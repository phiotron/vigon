package com.phiotron.vigon

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Chuyển route trong intent (nút Chi/Thu của widget) sang Dart qua kênh
 * `vigon/deeplink`. Route được giữ lại tới khi Dart lấy bằng "takePending"
 * (khởi động nguội); khi app đang chạy thì báo bằng "routeAvailable".
 * Dart tự lọc route, chỉ nhận màn nhập khoản mới.
 */
class DeepLinkChannel(engine: FlutterEngine) {
    companion object {
        const val CHANNEL = "vigon/deeplink"
        const val EXTRA_ROUTE = "com.phiotron.vigon.route"
    }

    private var pending: String? = null
    private val channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "takePending" -> {
                    result.success(pending)
                    pending = null
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * [notify] true khi intent đến lúc app đang chạy. Intent mở lại từ danh sách
     * gần đây mang theo intent gốc của task nên bị bỏ qua, tránh mở lại màn cũ.
     */
    fun accept(intent: Intent?, notify: Boolean) {
        if (intent == null) return
        if (intent.flags and Intent.FLAG_ACTIVITY_LAUNCHED_FROM_HISTORY != 0) return
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return
        intent.removeExtra(EXTRA_ROUTE)
        pending = route
        if (notify) channel.invokeMethod("routeAvailable", null)
    }
}
