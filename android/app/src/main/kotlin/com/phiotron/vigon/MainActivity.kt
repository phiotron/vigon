package com.phiotron.vigon

import android.content.Intent
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var backupFolder: BackupFolderChannel? = null
    private var deepLink: DeepLinkChannel? = null
    private var restoredState = false

    override fun onCreate(savedInstanceState: Bundle?) {
        // Hệ thống dựng lại activity sau khi tiến trình bị giết: intent gốc không được xử lý lại.
        restoredState = savedInstanceState != null
        super.onCreate(savedInstanceState)
    }

    // F-26: route từ nút widget khi app đang chạy.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        deepLink?.accept(intent, notify = true)
    }

    private fun configureWidget(flutterEngine: FlutterEngine) {
        VigonWidgetProvider.registerChannel(flutterEngine, this)
        deepLink = DeepLinkChannel(flutterEngine).also {
            if (!restoredState) it.accept(intent, notify = false)
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // F-24: sao lưu tự động vào thư mục người dùng chọn (Storage Access Framework).
        backupFolder = BackupFolderChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        // D-026: lịch sao lưu theo giờ chọn (báo thức không chính xác → job chạy Dart nền).
        BackupAlarm.registerChannel(flutterEngine.dartExecutor.binaryMessenger, this)
        // F-28/AC-82: lịch kiểm thư nền ~mỗi giờ (job định kỳ → job chạy Dart nền).
        MailCheck.registerChannel(flutterEngine.dartExecutor.binaryMessenger, this)
        // F-26: widget màn hình chính và liên kết sâu từ nút Chi/Thu.
        configureWidget(flutterEngine)
        // AC-56: bật/tắt FLAG_SECURE để chặn chụp màn hình và che màn đa nhiệm.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "vigon/secure")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val on = call.arguments as? Boolean
                        if (on == null) {
                            result.error("bad_args", "setSecure cần một giá trị true/false", null)
                        } else {
                            if (on) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Chuyển kết quả bộ chọn thư mục cho BackupFolderChannel")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (backupFolder?.onActivityResult(requestCode, resultCode, data) == true) return
        @Suppress("DEPRECATION")
        super.onActivityResult(requestCode, resultCode, data)
    }
}
