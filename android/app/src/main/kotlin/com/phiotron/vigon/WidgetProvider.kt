package com.phiotron.vigon

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.SizeF
import android.view.View
import android.widget.RemoteViews
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Widget màn hình chính "Ví Gọn" (AC-63, AC-64; vẽ lại theo mockup v4 EXT-01): hai nút Chi và
 * Thu, và nếu Dart cho phép thì số đã chi tháng này (số lớn + thanh hạn mức + dòng phụ) đã định
 * dạng sẵn. Dữ liệu nằm trong file SharedPreferences riêng của app (MODE_PRIVATE), chỉ có các
 * chuỗi đó.
 *
 * Dòng số tiền đi kèm hạn dùng (`validUntil`, hết kỳ tháng). Quá hạn mà app chưa đẩy số
 * mới (app không chạy qua ngày đầu tháng) thì dòng bị XÓA khỏi bộ nhớ và widget hiện
 * "Mở app để cập nhật": không bao giờ hiện số của kỳ cũ như của kỳ này. Hạn được kiểm ở
 * mọi lần vẽ (hệ thống cập nhật định kỳ 30 phút, khởi động máy, launcher vẽ lại) và bằng
 * một báo thức KHÔNG chính xác (AlarmManager.set, không cần quyền nào) đặt đúng lúc hết hạn.
 */
class VigonWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) manager.updateAppWidget(id, build(context, manager, id))
    }

    // Android dưới 12: đổi cỡ thì chọn lại bố cục 2×2 (nút dọc) hay 4×2 (nút ngang).
    override fun onAppWidgetOptionsChanged(
        context: Context,
        manager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle,
    ) {
        manager.updateAppWidget(appWidgetId, build(context, manager, appWidgetId))
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // Báo thức hết hạn do chính app đặt (receiver không xuất ra ngoài): vẽ lại để bỏ số cũ.
        if (intent.action == ACTION_EXPIRE) refreshAll(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        cancelExpiry(context)
    }

    companion object {
        private const val PREFS = "vigon_widget"
        private const val KEY_LINE = "line"
        private const val KEY_VALID_UNTIL = "valid_until"
        private const val KEY_STALE = "stale"
        private const val KEY_LABEL = "label"
        private const val KEY_AMOUNT = "amount"
        private const val KEY_CAPTION = "caption"
        private const val KEY_PERCENT = "percent"
        private const val KEY_WARN = "warn"
        private val HERO_KEYS = listOf(KEY_LABEL, KEY_AMOUNT, KEY_CAPTION, KEY_PERCENT, KEY_WARN)
        private const val ACTION_EXPIRE = "com.phiotron.vigon.WIDGET_EXPIRE"
        const val CHANNEL = "vigon/widget"

        /** Số bị che khi khóa PIN (EXT-01 locked). */
        private const val MASK = "\u2022\u2022\u2022\u2022\u2022\u2022"

        /** Bề rộng (dp) từ đó dùng bố cục 4×2: hai nút cạnh nhau, chữ một dòng (EXT-01). */
        private const val WIDE_MIN_DP = 250

        /**
         * Android 12+: giao cả hai bố cục, launcher tự chọn theo cỡ. Bản cũ hơn: chọn theo bề rộng
         * tối thiểu hiện tại của widget.
         */
        private fun build(context: Context, manager: AppWidgetManager, id: Int): RemoteViews {
            val state = readState(context)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                return RemoteViews(
                    mapOf(
                        SizeF(110f, 110f) to views(context, R.layout.vigon_widget, state),
                        SizeF(WIDE_MIN_DP.toFloat(), 110f) to
                            views(context, R.layout.vigon_widget_wide, state),
                    ),
                )
            }
            val minWidth = manager.getAppWidgetOptions(id)
                .getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
            val layout = if (minWidth >= WIDE_MIN_DP) R.layout.vigon_widget_wide else R.layout.vigon_widget
            return views(context, layout, state)
        }

        /**
         * Trạng thái vẽ: [line] null = mặc định (logo + "Ví Gọn" + lời giới thiệu). Có số: [label] +
         * [amount] (+ [percent]/[caption]/[warn] khi có hạn mức). [locked]: "Đã khóa bằng PIN" + số
         * che. [stale]: hết kỳ, "Mở app để cập nhật".
         */
        private data class State(
            val line: String?,
            val locked: Boolean,
            val stale: Boolean,
            val label: String? = null,
            val amount: String? = null,
            val caption: String? = null,
            val percent: Int = -1,
            val warn: Boolean = false,
        )

        /**
         * Đọc bộ nhớ widget, bỏ số đã hết kỳ. Dòng số tiền luôn có hạn dùng; dòng không có hạn
         * dùng là "Đã khóa bằng PIN" (Dart không bao giờ gửi số mà thiếu hạn, D-016).
         */
        private fun readState(context: Context): State {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            var line = prefs.getString(KEY_LINE, null)
            val validUntil = prefs.getLong(KEY_VALID_UNTIL, 0L)
            if (!line.isNullOrEmpty() && validUntil > 0L && System.currentTimeMillis() >= validUntil) {
                // Hết kỳ: xóa số cũ khỏi bộ nhớ, nhớ rằng đang chờ app cập nhật.
                val edit = prefs.edit()
                    .remove(KEY_LINE)
                    .remove(KEY_VALID_UNTIL)
                    .putBoolean(KEY_STALE, true)
                HERO_KEYS.forEach { edit.remove(it) }
                edit.commit()
                line = null
            }
            if (!line.isNullOrEmpty() && validUntil > 0L) {
                scheduleExpiry(context, validUntil)
            } else {
                cancelExpiry(context)
            }

            return when {
                !line.isNullOrEmpty() -> State(
                    line,
                    locked = validUntil <= 0L,
                    stale = false,
                    label = prefs.getString(KEY_LABEL, null),
                    amount = prefs.getString(KEY_AMOUNT, null),
                    caption = prefs.getString(KEY_CAPTION, null),
                    percent = prefs.getInt(KEY_PERCENT, -1),
                    warn = prefs.getBoolean(KEY_WARN, false),
                )
                prefs.getBoolean(KEY_STALE, false) ->
                    State(context.getString(R.string.widget_stale), locked = false, stale = true)
                else -> State(null, locked = false, stale = false)
            }
        }

        private fun views(context: Context, layout: Int, state: State): RemoteViews {
            val views = RemoteViews(context.packageName, layout)
            // Mặc định mọi phần số đều ẩn; từng trạng thái bật phần của mình.
            views.setViewVisibility(R.id.widget_amount, View.GONE)
            views.setViewVisibility(R.id.widget_bar, View.GONE)
            views.setViewVisibility(R.id.widget_bar_warn, View.GONE)
            views.setViewVisibility(R.id.widget_caption_row, View.GONE)
            views.setViewVisibility(R.id.widget_msg_row, View.GONE)
            views.setViewVisibility(R.id.widget_msg_icon, View.GONE)
            views.setViewVisibility(R.id.widget_icon, View.VISIBLE)
            views.setImageViewResource(R.id.widget_icon, R.drawable.ic_widget_logo)
            views.setTextViewText(R.id.widget_brand, context.getString(R.string.widget_label))
            when {
                state.locked -> {
                    // PIN bật: khóa + "Đã khóa bằng PIN", số che và thanh rỗng để bố cục không nhảy
                    // khi tắt PIN (EXT-01 locked).
                    views.setImageViewResource(R.id.widget_icon, R.drawable.ic_widget_lock)
                    views.setTextViewText(R.id.widget_brand, state.line)
                    views.setTextViewText(R.id.widget_amount, MASK)
                    views.setTextColor(R.id.widget_amount, context.getColor(R.color.widget_ink_45))
                    views.setViewVisibility(R.id.widget_amount, View.VISIBLE)
                    views.setProgressBar(R.id.widget_bar, 100, 0, false)
                    views.setViewVisibility(R.id.widget_bar, View.VISIBLE)
                }
                state.stale -> {
                    views.setTextViewText(R.id.widget_msg, state.line)
                    views.setViewVisibility(R.id.widget_msg_icon, View.VISIBLE)
                    views.setViewVisibility(R.id.widget_msg_row, View.VISIBLE)
                }
                state.line != null && state.amount != null -> {
                    // Có số: "Tháng này đã chi" + số lớn (+ thanh và dòng phụ khi có hạn mức).
                    views.setViewVisibility(R.id.widget_icon, View.GONE)
                    views.setTextViewText(R.id.widget_brand, state.label ?: "")
                    views.setTextViewText(R.id.widget_amount, state.amount)
                    views.setTextColor(R.id.widget_amount, context.getColor(R.color.widget_ink))
                    views.setViewVisibility(R.id.widget_amount, View.VISIBLE)
                    // TalkBack đọc cả câu (AC-64).
                    views.setContentDescription(R.id.widget_amount, state.line)
                    if (state.percent >= 0) {
                        val bar = if (state.warn) R.id.widget_bar_warn else R.id.widget_bar
                        views.setProgressBar(bar, 100, state.percent.coerceIn(0, 100), false)
                        views.setViewVisibility(bar, View.VISIBLE)
                    }
                    if (!state.caption.isNullOrEmpty()) {
                        views.setViewVisibility(R.id.widget_caption_row, View.VISIBLE)
                        views.setViewVisibility(
                            R.id.widget_caption_icon,
                            if (state.warn) View.VISIBLE else View.GONE,
                        )
                        views.setViewVisibility(
                            R.id.widget_caption,
                            if (state.warn) View.GONE else View.VISIBLE,
                        )
                        views.setViewVisibility(
                            R.id.widget_caption_warn,
                            if (state.warn) View.VISIBLE else View.GONE,
                        )
                        views.setTextViewText(
                            if (state.warn) R.id.widget_caption_warn else R.id.widget_caption,
                            state.caption,
                        )
                    }
                }
                state.line != null -> {
                    // Dữ liệu cũ (chỉ có câu, từ bản trước khi vẽ lại): hiện câu dưới tiêu đề.
                    views.setTextViewText(R.id.widget_msg, state.line)
                    views.setViewVisibility(R.id.widget_msg_row, View.VISIBLE)
                }
                else -> {
                    // Mặc định: logo + "Ví Gọn" + lời giới thiệu; không có gì về tiền.
                    views.setTextViewText(R.id.widget_msg, context.getString(R.string.widget_description))
                    views.setViewVisibility(R.id.widget_msg_row, View.VISIBLE)
                }
            }
            views.setOnClickPendingIntent(
                R.id.widget_expense,
                openEntry(context, 0, "/entry/new?type=expense"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_income,
                openEntry(context, 1, "/entry/new?type=income"),
            )
            // Chạm phần tên/dòng trạng thái: mở màn chính (D9; trước đây chạm vào không có gì).
            views.setOnClickPendingIntent(R.id.widget_header, openEntry(context, 2, "/"))
            return views
        }

        /** Mở MainActivity kèm route; mã yêu cầu khác nhau để hai nút không đè extra của nhau. */
        private fun openEntry(context: Context, requestCode: Int, route: String): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                putExtra(DeepLinkChannel.EXTRA_ROUTE, route)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
            }
            return PendingIntent.getActivity(
                context,
                requestCode,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        private fun expiryIntent(context: Context): PendingIntent {
            val intent = Intent(context, VigonWidgetProvider::class.java).setAction(ACTION_EXPIRE)
            return PendingIntent.getBroadcast(
                context,
                2,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
        }

        /** Báo thức không chính xác, không đánh thức máy, không cần quyền; máy khởi động lại thì onUpdate đặt lại. */
        private fun scheduleExpiry(context: Context, validUntil: Long) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.set(AlarmManager.RTC, validUntil, expiryIntent(context))
        }

        private fun cancelExpiry(context: Context) {
            val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            alarms.cancel(expiryIntent(context))
        }

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, VigonWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context, manager, id))
        }

        /**
         * Kênh `vigon/widget`: "show" ghi dòng trạng thái kèm hạn dùng (`{line, validUntil?}`),
         * "clear" XÓA khỏi bộ nhớ; cả hai vẽ lại widget.
         */
        fun registerChannel(engine: FlutterEngine, context: Context) {
            val app = context.applicationContext
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    when (call.method) {
                        "show" -> {
                            val line = call.argument<String>("line")
                            val validUntil = call.argument<Number>("validUntil")?.toLong() ?: 0L
                            if (line.isNullOrEmpty()) {
                                result.error("bad_args", "show cần {line, validUntil?}", null)
                            } else {
                                val edit = prefs.edit()
                                    .putString(KEY_LINE, line)
                                    .putLong(KEY_VALID_UNTIL, validUntil)
                                    .putBoolean(KEY_STALE, false)
                                HERO_KEYS.forEach { edit.remove(it) }
                                // Phần số lớn (mockup v4): chỉ có khi Dart được phép hiện số.
                                call.argument<String>("amount")?.let { amount ->
                                    edit.putString(KEY_AMOUNT, amount)
                                    edit.putString(KEY_LABEL, call.argument<String>("label"))
                                    call.argument<String>("caption")?.let {
                                        edit.putString(KEY_CAPTION, it)
                                    }
                                    edit.putInt(
                                        KEY_PERCENT,
                                        call.argument<Number>("percent")?.toInt() ?: -1,
                                    )
                                    edit.putBoolean(KEY_WARN, call.argument<Boolean>("warn") ?: false)
                                }
                                edit.commit()
                                refreshAll(app)
                                result.success(null)
                            }
                        }
                        "clear" -> {
                            val edit = prefs.edit()
                                .remove(KEY_LINE)
                                .remove(KEY_VALID_UNTIL)
                                .remove(KEY_STALE)
                            HERO_KEYS.forEach { edit.remove(it) }
                            edit.commit()
                            refreshAll(app)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }
}
