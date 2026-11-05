package com.phiotron.vigon

import android.app.AlarmManager
import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Widget màn hình chính "Ví Gọn" (AC-63, AC-64): hai nút Chi và Thu, và nếu Dart
 * cho phép thì một dòng trạng thái đã định dạng sẵn. Dữ liệu nằm trong file
 * SharedPreferences riêng của app (MODE_PRIVATE), chỉ có dòng chữ đó.
 *
 * Dòng số tiền đi kèm hạn dùng (`validUntil`, hết kỳ tháng). Quá hạn mà app chưa đẩy số
 * mới (app không chạy qua ngày đầu tháng) thì dòng bị XÓA khỏi bộ nhớ và widget hiện
 * "Mở app để cập nhật": không bao giờ hiện số của kỳ cũ như của kỳ này. Hạn được kiểm ở
 * mọi lần vẽ (hệ thống cập nhật định kỳ 30 phút, khởi động máy, launcher vẽ lại) và bằng
 * một báo thức KHÔNG chính xác (AlarmManager.set, không cần quyền nào) đặt đúng lúc hết hạn.
 */
class VigonWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) manager.updateAppWidget(id, build(context))
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
        private const val ACTION_EXPIRE = "com.phiotron.vigon.WIDGET_EXPIRE"
        const val CHANNEL = "vigon/widget"

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.vigon_widget)
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            var line = prefs.getString(KEY_LINE, null)
            val validUntil = prefs.getLong(KEY_VALID_UNTIL, 0L)
            if (!line.isNullOrEmpty() && validUntil > 0L && System.currentTimeMillis() >= validUntil) {
                // Hết kỳ: xóa số cũ khỏi bộ nhớ, nhớ rằng đang chờ app cập nhật.
                prefs.edit()
                    .remove(KEY_LINE)
                    .remove(KEY_VALID_UNTIL)
                    .putBoolean(KEY_STALE, true)
                    .commit()
                line = null
            }
            if (!line.isNullOrEmpty() && validUntil > 0L) {
                scheduleExpiry(context, validUntil)
            } else {
                cancelExpiry(context)
            }

            if (!line.isNullOrEmpty()) {
                views.setTextViewText(R.id.widget_status, line)
                views.setViewVisibility(R.id.widget_status, View.VISIBLE)
            } else if (prefs.getBoolean(KEY_STALE, false)) {
                views.setTextViewText(R.id.widget_status, context.getString(R.string.widget_stale))
                views.setViewVisibility(R.id.widget_status, View.VISIBLE)
            } else {
                views.setViewVisibility(R.id.widget_status, View.GONE)
            }
            views.setOnClickPendingIntent(
                R.id.widget_expense,
                openEntry(context, 0, "/entry/new?type=expense"),
            )
            views.setOnClickPendingIntent(
                R.id.widget_income,
                openEntry(context, 1, "/entry/new?type=income"),
            )
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
            for (id in ids) manager.updateAppWidget(id, build(context))
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
                                prefs.edit()
                                    .putString(KEY_LINE, line)
                                    .putLong(KEY_VALID_UNTIL, validUntil)
                                    .putBoolean(KEY_STALE, false)
                                    .commit()
                                refreshAll(app)
                                result.success(null)
                            }
                        }
                        "clear" -> {
                            prefs.edit()
                                .remove(KEY_LINE)
                                .remove(KEY_VALID_UNTIL)
                                .remove(KEY_STALE)
                                .commit()
                            refreshAll(app)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }
}
