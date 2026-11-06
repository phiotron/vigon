package com.phiotron.vigon

import android.app.AlarmManager
import android.app.PendingIntent
import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar
import java.util.TimeZone

/**
 * Sao lưu tự động theo giờ người dùng chọn (F-24, D-026), phần Android chạy khi app ĐÓNG.
 *
 * Chuỗi: Dart (`AndroidAutoBackupScheduler`) gửi giờ qua kênh `vigon/backup_schedule` →
 * [BackupAlarm.save] lưu giờ (không bí mật) vào SharedPreferences riêng rồi đặt một báo thức
 * KHÔNG chính xác `setAndAllowWhileIdle` (chạy được cả lúc Doze, hệ thống có thể lùi vài phút;
 * không xin quyền báo thức chính xác, giữ tinh thần D-015) → báo thức nổ,
 * [BackupAlarmReceiver] đặt ngay báo thức ngày mai (chuỗi lịch không phụ thuộc Dart) và xếp
 * [BackupJobService] (expedited từ Android 12) → job dựng một FlutterEngine không giao diện, chạy
 * `autoBackupBackgroundMain` (lib/main.dart): mở DB, đọc mật khẩu từ Keystore, mã hoá, ghi qua SAF
 * bằng chung `AutoBackupService` (mỗi mốc giờ tối đa một lần, chỉ khi dữ liệu đổi, giữ 7 file).
 *
 * Khởi động lại máy, cập nhật app, đổi giờ hay múi giờ: [BackupAlarmReceiver] tính lại mốc theo
 * giờ địa phương mới. Không thêm quyền: RECEIVE_BOOT_COMPLETED đã có (F-25); JobScheduler và
 * AlarmManager không cần quyền khai báo. Không thêm thư viện.
 */
object BackupAlarm {
    const val SCHEDULE_CHANNEL = "vigon/backup_schedule"
    const val ACTION_FIRE = "com.phiotron.vigon.action.AUTO_BACKUP_ALARM"
    const val JOB_ID = 4302
    private const val REQUEST_CODE = 4301
    private const val PREFS = "vigon_auto_backup_schedule"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_HOUR = "hour"
    private const val KEY_MINUTE = "minute"

    private fun prefs(ctx: Context) = ctx.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    fun isEnabled(ctx: Context) = prefs(ctx).getBoolean(KEY_ENABLED, false)

    /** Lưu giờ và đặt báo thức kế tiếp (thay báo thức cũ cùng PendingIntent). */
    fun save(ctx: Context, hour: Int, minute: Int) {
        prefs(ctx).edit()
            .putBoolean(KEY_ENABLED, true)
            .putInt(KEY_HOUR, hour)
            .putInt(KEY_MINUTE, minute)
            .apply()
        scheduleNext(ctx)
    }

    /** Tắt: xóa giờ, hủy báo thức và job đang chờ. */
    fun disable(ctx: Context) {
        prefs(ctx).edit().clear().apply()
        try {
            ctx.getSystemService(AlarmManager::class.java)?.cancel(pendingIntent(ctx))
        } catch (_: Exception) {}
        try {
            ctx.getSystemService(JobScheduler::class.java)?.cancel(JOB_ID)
        } catch (_: Exception) {}
    }

    /**
     * Mốc kế tiếp lúc [hour]:[minute] theo múi giờ [zone], sau hẳn [nowMillis]. Calendar tự đẩy
     * giờ không tồn tại (chuyển giờ mùa hè) tới sau khoảng nhảy.
     */
    fun nextTrigger(nowMillis: Long, hour: Int, minute: Int, zone: TimeZone): Long {
        val cal = Calendar.getInstance(zone).apply {
            timeInMillis = nowMillis
            set(Calendar.HOUR_OF_DAY, hour)
            set(Calendar.MINUTE, minute)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        if (cal.timeInMillis <= nowMillis) {
            cal.add(Calendar.DAY_OF_MONTH, 1)
            cal.set(Calendar.HOUR_OF_DAY, hour)
            cal.set(Calendar.MINUTE, minute)
        }
        return cal.timeInMillis
    }

    /** Đặt báo thức cho mốc kế tiếp nếu đang bật. [zone]: múi giờ mới khi vừa đổi. */
    fun scheduleNext(ctx: Context, zone: TimeZone = TimeZone.getDefault()) {
        val p = prefs(ctx)
        if (!p.getBoolean(KEY_ENABLED, false)) return
        val at = nextTrigger(
            System.currentTimeMillis(),
            p.getInt(KEY_HOUR, 21),
            p.getInt(KEY_MINUTE, 0),
            zone,
        )
        try {
            // KHÔNG chính xác (D-015, D-026): không cần quyền báo thức chính xác.
            ctx.getSystemService(AlarmManager::class.java)
                ?.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pendingIntent(ctx))
        } catch (_: Exception) {
            // Hệ thống từ chối: vẫn còn đường bù khi mở/rời app.
        }
    }

    private fun pendingIntent(ctx: Context): PendingIntent = PendingIntent.getBroadcast(
        ctx,
        REQUEST_CODE,
        Intent(ctx, BackupAlarmReceiver::class.java).setAction(ACTION_FIRE),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    /** Xếp job sao lưu chạy ngay: expedited (Android 12+, hết hạn mức thì job thường). */
    fun startJob(ctx: Context) {
        val js = ctx.getSystemService(JobScheduler::class.java) ?: return
        val component = ComponentName(ctx, BackupJobService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            try {
                val job = JobInfo.Builder(JOB_ID, component).setExpedited(true).build()
                if (js.schedule(job) == JobScheduler.RESULT_SUCCESS) return
            } catch (_: Exception) {}
        }
        try {
            js.schedule(JobInfo.Builder(JOB_ID, component).setOverrideDeadline(60_000).build())
        } catch (_: Exception) {}
    }

    /** Kênh trong app: Dart đặt/hủy lịch. */
    fun registerChannel(messenger: BinaryMessenger, ctx: Context) {
        val app = ctx.applicationContext
        MethodChannel(messenger, SCHEDULE_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "schedule" -> {
                    val hour = call.argument<Int>("hour")
                    val minute = call.argument<Int>("minute")
                    if (hour == null || minute == null || hour !in 0..23 || minute !in 0..59) {
                        result.error("bad_args", "schedule cần hour 0..23 và minute 0..59", null)
                    } else {
                        save(app, hour, minute)
                        result.success(null)
                    }
                }
                "cancel" -> {
                    disable(app)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}

/**
 * Nhận báo thức giờ sao lưu (intent tường minh, không cần bộ lọc) và các sự kiện hệ thống làm mất
 * hoặc lệch báo thức: khởi động lại, cập nhật app, đổi giờ, đổi múi giờ. `exported="false"`: chỉ
 * hệ thống gửi được tới đây.
 */
class BackupAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            BackupAlarm.ACTION_FIRE -> {
                // Đặt lịch ngày mai TRƯỚC khi chạy: Dart lỗi hay bị dừng cũng không đứt chuỗi.
                BackupAlarm.scheduleNext(context)
                if (BackupAlarm.isEnabled(context)) BackupAlarm.startJob(context)
            }
            Intent.ACTION_TIMEZONE_CHANGED -> {
                val zone = intent.getStringExtra("time-zone")?.let { TimeZone.getTimeZone(it) }
                BackupAlarm.scheduleNext(context, zone ?: TimeZone.getDefault())
            }
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_TIME_CHANGED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            -> BackupAlarm.scheduleNext(context)
        }
    }
}

/**
 * Job chạy sao lưu khi app đóng: dựng FlutterEngine không giao diện (plugin tự đăng ký: Keystore
 * qua flutter_secure_storage, đường dẫn DB...), gắn [BackupFolderChannel] không Activity, chạy
 * `autoBackupBackgroundMain`. Dart báo `done` qua kênh `vigon/backup_job` thì kết thúc job và hủy
 * engine; quá [TIMEOUT_MS] cũng kết thúc. Hệ thống dừng job giữa chừng: không lên lịch lại (lần
 * mở/rời app kế tiếp sẽ bù, D-026).
 */
class BackupJobService : JobService() {
    companion object {
        const val JOB_CHANNEL = "vigon/backup_job"
        const val ENTRYPOINT = "autoBackupBackgroundMain"
        private const val TIMEOUT_MS = 9L * 60 * 1000
    }

    private val main = Handler(Looper.getMainLooper())
    private var engine: FlutterEngine? = null
    private var folder: BackupFolderChannel? = null
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
        if (params == null) return // đã bị dừng trong lúc nạp Flutter
        try {
            val e = FlutterEngine(applicationContext)
            engine = e
            val messenger = e.dartExecutor.binaryMessenger
            folder = BackupFolderChannel(applicationContext, null, messenger)
            MethodChannel(messenger, JOB_CHANNEL).setMethodCallHandler { call, result ->
                if (call.method == "done") {
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
        cleanUp()
        if (p != null) jobFinished(p, false)
    }

    private fun cleanUp() {
        folder?.dispose()
        folder = null
        engine?.destroy()
        engine = null
    }

    override fun onStopJob(params: JobParameters): Boolean {
        main.removeCallbacks(timeout)
        this.params = null
        cleanUp()
        return false
    }

    override fun onDestroy() {
        main.removeCallbacks(timeout)
        cleanUp()
        super.onDestroy()
    }
}
