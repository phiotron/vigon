package com.phiotron.vigon

import android.content.Intent
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var backupFolder: BackupFolderChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // F-24: sao lưu tự động vào thư mục người dùng chọn (Storage Access Framework).
        backupFolder = BackupFolderChannel(this, flutterEngine.dartExecutor.binaryMessenger)
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
