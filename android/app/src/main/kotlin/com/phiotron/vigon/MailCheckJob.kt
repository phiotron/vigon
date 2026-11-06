package com.phiotron.vigon

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Kiểm thư nền khoảng mỗi giờ khi app ĐÓNG (F-28, AC-82, D-031), chỉ Android.
 *
 * Dart (`AndroidMailCheckScheduler`) bật/tắt qua kênh `vigon/mail_schedule` khi có/không còn hộp
 * thư → [MailCheck.enable] đặt một job ĐỊNH KỲ ~1 giờ của JobScheduler (lịch không chính xác, hệ
 * thống gom theo Doze/pin; không quyền báo thức chính xác). `setPersisted(true)` giữ lịch qua khởi
 * động lại máy — dùng quyền `RECEIVE_BOOT_COMPLETED` đã có. KHÔNG đặt điều kiện mạng: điều kiện
 * đó cần `ACCESS_NETWORK_STATE` (cấm, SPEC 5); không có mạng thì lần kiểm báo "Không có mạng" và
 * lần mở app kế tiếp kiểm bù.
 *
 * Job dựng FlutterEngine không giao diện như sao lưu tự động ([BackupJobService]) và chạy
 * `mailCheckBackgroundMain` (lib/main.dart). Không thêm quyền, không thêm thư viện.
 */
object MailCheck {
    const val SCHEDULE_CHANNEL = "vigon/mail_schedule"
    const val JOB_ID = 4311
    private const val PERIOD_MS = 60L * 60 * 1000
    private const val FLEX_MS = 15L * 60 * 1000

    fun enable(ctx: Context) {
        val js = ctx.getSystemService(JobScheduler::class.java) ?: return
        // Đã có job giống hệt: giữ nguyên để không dời mốc chạy mỗi lần mở app.
        val existing = js.getPendingJob(JOB_ID)
        if (existing != null && existing.isPeriodic && existing.intervalMillis == PERIOD_MS) return
        try {
            js.schedule(
                JobInfo.Builder(JOB_ID, ComponentName(ctx, MailCheckJobService::class.java))
                    .setPeriodic(PERIOD_MS, FLEX_MS)
                    .setPersisted(true)
                    .build(),
            )
        } catch (_: Exception) {
            // Hệ thống từ chối: vẫn kiểm khi mở/quay lại app.
        }
    }

    fun disable(ctx: Context) {
        try {
            ctx.getSystemService(JobScheduler::class.java)?.cancel(JOB_ID)
        } catch (_: Exception) {}
    }

    /** Kênh trong app: Dart bật/tắt lịch. */
    fun registerChannel(messenger: BinaryMessenger, ctx: Context) {
        val app = ctx.applicationContext
        MethodChannel(messenger, SCHEDULE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "enable" -> {
                    enable(app)
                    result.success(null)
                }
                "disable" -> {
                    disable(app)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

/**
 * Job kiểm thư: dựng FlutterEngine không giao diện (plugin tự đăng ký: Keystore qua
 * flutter_secure_storage, đường dẫn app), chạy `mailCheckBackgroundMain`. Dart báo `done` qua kênh
 * `vigon/mail_job` thì kết thúc job; quá [TIMEOUT_MS] cũng kết thúc. Bị hệ thống dừng: không xếp
 * lại (job định kỳ tự chạy lần sau; mở app cũng kiểm).
 */
class MailCheckJobService : JobService() {
    companion object {
        const val JOB_CHANNEL = "vigon/mail_job"
        const val ENTRYPOINT = "mailCheckBackgroundMain"
        private const val TIMEOUT_MS = 5L * 60 * 1000
    }

    private val main = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var params: JobParameters? = null
    private val timeout = Runnable { finish() }

    override fun onStartJob(params: JobParameters): Boolean {
        if (this.params != null) return false
        this.params = params
        return try {
            val loader = FlutterInjector.instance().flutterLoader()
            loader.startInitialization(applicationContext)
            loader.ensureInitializationCompleteAsync(applicationContext, null, main) {
                startDart(loader.findAppBundlePath())
            }
            main.postDelayed(timeout, TIMEOUT_MS)
            true
        } catch (_: Exception) {
            this.params = null
            false
        }
    }

    private fun startDart(bundlePath: String) {
        if (params == null) return
        try {
            val e = FlutterEngine(applicationContext)
            engine = e
            MethodChannel(e.dartExecutor.binaryMessenger, JOB_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    // Chỉ số đếm (hộp thư kiểm được/lỗi), không địa chỉ, nội dung hay mật khẩu.
                    // Xem: adb logcat -s VigonMail
                    Log.i("VigonMail", "scheduled mail check ${call.arguments}")
                    result.success(null)
                    main.post { finish() }
                } else {
                    result.notImplemented()
                }
            }
            e.dartExecutor.executeDartEntrypoint(
                DartExecutor.DartEntrypoint(bundlePath, ENTRYPOINT),
            )
        } catch (_: Exception) {
            finish()
        }
    }

    private fun finish() {
        main.removeCallbacks(timeout)
        val p = params
        params = null
        engine?.destroy()
        engine = null
        if (p != null) jobFinished(p, false)
    }

    override fun onStopJob(params: JobParameters): Boolean {
        main.removeCallbacks(timeout)
        this.params = null
        engine?.destroy()
        engine = null
        return false
    }

    override fun onDestroy() {
        main.removeCallbacks(timeout)
        engine?.destroy()
        engine = null
        super.onDestroy()
    }
}
