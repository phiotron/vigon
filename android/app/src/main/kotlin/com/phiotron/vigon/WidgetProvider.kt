package com.phiotron.vigon

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
 */
class VigonWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, appWidgetIds: IntArray) {
        for (id in appWidgetIds) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val PREFS = "vigon_widget"
        private const val KEY_LINE = "line"
        const val CHANNEL = "vigon/widget"

        private fun build(context: Context): RemoteViews {
            val views = RemoteViews(context.packageName, R.layout.vigon_widget)
            val line = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_LINE, null)
            if (line.isNullOrEmpty()) {
                views.setViewVisibility(R.id.widget_status, View.GONE)
            } else {
                views.setTextViewText(R.id.widget_status, line)
                views.setViewVisibility(R.id.widget_status, View.VISIBLE)
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

        fun refreshAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, VigonWidgetProvider::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
        }

        /** Kênh `vigon/widget`: "show" ghi dòng trạng thái, "clear" XÓA khỏi bộ nhớ; cả hai vẽ lại widget. */
        fun registerChannel(engine: FlutterEngine, context: Context) {
            val app = context.applicationContext
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    val prefs = app.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                    when (call.method) {
                        "show" -> {
                            val line = call.arguments as? String
                            if (line.isNullOrEmpty()) {
                                result.error("bad_args", "show cần một chuỗi", null)
                            } else {
                                prefs.edit().putString(KEY_LINE, line).commit()
                                refreshAll(app)
                                result.success(null)
                            }
                        }
                        "clear" -> {
                            prefs.edit().remove(KEY_LINE).commit()
                            refreshAll(app)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }
}
