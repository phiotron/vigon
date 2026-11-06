package com.phiotron.vigon

import android.app.Activity
import android.app.Application
import android.content.ContentResolver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Kênh `vigon/backup_folder` (F-24, AC-58..60): ghi file sao lưu vào một thư mục người dùng chọn
 * bằng Storage Access Framework. Không cần quyền nào trong manifest, không mạng; Google Drive,
 * Dropbox... tự tải file lên đám mây vì chúng là nhà cung cấp tài liệu của thư mục đó.
 *
 * Lệnh: pickFolder, writeFile, listFiles, deleteFile, releaseFolder.
 * Lỗi trả về mã: permission_denied (quyền bị thu hồi), folder_missing (thư mục mất hoặc không
 * truy cập được), busy (đang có bộ chọn khác), bad_args, io_error.
 * Mọi việc đọc ghi chạy ở luồng nền; kết quả trả về luồng chính.
 *
 * Ghi file an toàn khi tiến trình bị giết giữa chừng: dữ liệu ghi vào file tạm
 * `vigon-auto-tmp-<ms>.part` (KHÔNG khớp mẫu `vigon-auto-AAAAMMDD-GGPP.vigon` mà bộ dọn file cũ
 * của Dart đếm), ghi xong và đóng stream mới đổi tên. File cũ trùng tên chỉ bị bỏ sau khi đổi
 * tên thành công (lỗi thì trả lại). File tạm mồ côi cũ hơn một ngày bị dọn. App chỉ ghi và xóa
 * tên khớp đúng mẫu của mình, không bao giờ chạm file khác của người dùng.
 */
class BackupFolderChannel(
    context: Context,
    hostActivity: Activity?,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    /** Trong app (có màn hình): mở được bộ chọn thư mục. */
    constructor(hostActivity: Activity, messenger: BinaryMessenger) :
        this(hostActivity.applicationContext, hostActivity, messenger)

    companion object {
        const val CHANNEL = "vigon/backup_folder"
        private const val REQUEST_PICK_FOLDER = 4201
        private const val FILE_MIME = "application/octet-stream"
        private const val TMP_PREFIX = "vigon-auto-tmp-"
        private const val ORPHAN_MAX_AGE_MS = 24L * 60 * 60 * 1000

        /** Tên file sao lưu tự động do Dart đặt. */
        private val AUTO_NAME = Regex("^vigon-auto-\\d{8}-\\d{4}\\.vigon$")

        /** File tạm/dự phòng do bên Kotlin tạo; nhóm 1 là mốc thời gian (ms). */
        private val TMP_NAME = Regex("^vigon-auto-tmp-(\\d{1,19})\\.(part|old)$")

        private fun ownedName(name: String) = AUTO_NAME.matches(name) || TMP_NAME.matches(name)
    }

    // Chỉ giữ Activity cho việc cần nó (mở bộ chọn); đọc ghi dùng applicationContext để luồng
    // nền không giữ Activity. Cả hai được bỏ khi Activity bị hủy (xem dispose).
    // Chạy nền (D-026, BackupJobService) thì không có Activity: chỉ ghi/liệt kê/xóa, không mở
    // bộ chọn; nơi tạo tự gọi dispose() khi hủy engine.
    private val appContext: Context = context.applicationContext
    private var activity: Activity? = hostActivity
    private val resolver: ContentResolver get() = appContext.contentResolver
    private val main = Handler(Looper.getMainLooper())
    private val worker: ExecutorService = Executors.newSingleThreadExecutor()
    private val channel = MethodChannel(messenger, CHANNEL)
    private var pendingPick: MethodChannel.Result? = null

    private val lifecycle = object : Application.ActivityLifecycleCallbacks {
        override fun onActivityDestroyed(a: Activity) {
            if (a === activity) dispose()
        }

        override fun onActivityCreated(a: Activity, savedInstanceState: Bundle?) {}
        override fun onActivityStarted(a: Activity) {}
        override fun onActivityResumed(a: Activity) {}
        override fun onActivityPaused(a: Activity) {}
        override fun onActivityStopped(a: Activity) {}
        override fun onActivitySaveInstanceState(a: Activity, outState: Bundle) {}
    }

    init {
        channel.setMethodCallHandler(this)
        if (hostActivity != null) {
            (appContext as? Application)?.registerActivityLifecycleCallbacks(lifecycle)
        }
    }

    /**
     * Gọi khi Activity bị hủy: thôi nhận lệnh, bỏ tham chiếu Activity, dừng luồng nền (việc đang
     * chạy vẫn xong, việc mới không nhận). Bản mới được dựng ở `configureFlutterEngine`.
     */
    fun dispose() {
        (appContext as? Application)?.unregisterActivityLifecycleCallbacks(lifecycle)
        channel.setMethodCallHandler(null)
        pendingPick?.error("io_error", "Màn hình đã đóng", null)
        pendingPick = null
        activity = null
        worker.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "writeFile" -> {
                val tree = call.argument<String>("treeUri")
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                if (tree == null || name == null || bytes == null || !AUTO_NAME.matches(name)) {
                    result.error("bad_args", "writeFile cần treeUri, name đúng mẫu vigon-auto-AAAAMMDD-GGPP.vigon và bytes", null)
                } else {
                    runAsync(result) { writeFile(Uri.parse(tree), name, bytes) }
                }
            }
            "listFiles" -> {
                val tree = call.argument<String>("treeUri")
                if (tree == null) {
                    result.error("bad_args", "listFiles cần treeUri", null)
                } else {
                    runAsync(result) { listFiles(Uri.parse(tree)).map { it.second } }
                }
            }
            "deleteFile" -> {
                val tree = call.argument<String>("treeUri")
                val name = call.argument<String>("name")
                // Chỉ xóa file đúng mẫu tên của app: không bao giờ đụng file khác của người dùng.
                if (tree == null || name == null || !ownedName(name)) {
                    result.error("bad_args", "deleteFile cần treeUri và tên file của Ví Gọn", null)
                } else {
                    runAsync(result) { deleteFile(Uri.parse(tree), name) }
                }
            }
            "releaseFolder" -> {
                val tree = call.argument<String>("treeUri")
                if (tree == null) {
                    result.error("bad_args", "releaseFolder cần treeUri", null)
                } else {
                    runAsync(result) { releaseFolder(Uri.parse(tree)) }
                }
            }
            else -> result.notImplemented()
        }
    }

    /** Chuyển kết quả bộ chọn thư mục từ `Activity.onActivityResult`; true nếu đã xử lý. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST_PICK_FOLDER) return false
        val result = pendingPick ?: return true
        pendingPick = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            // Giữ quyền đọc+ghi qua các lần mở app và khởi động lại máy.
            resolver.takePersistableUriPermission(
                uri,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
            result.success(mapOf("uri" to uri.toString(), "name" to folderName(uri)))
        } catch (e: SecurityException) {
            result.error("permission_denied", "Không giữ được quyền ghi vào thư mục", null)
        } catch (e: Exception) {
            result.error("io_error", e.message, null)
        }
        return true
    }

    private fun pickFolder(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("busy", "Đang mở bộ chọn thư mục", null)
            return
        }
        val host = activity
        if (host == null) {
            result.error("io_error", "Màn hình đã đóng", null)
            return
        }
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
        pendingPick = result
        try {
            @Suppress("DEPRECATION")
            host.startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (e: Exception) {
            // Máy không có bộ chọn thư mục.
            pendingPick = null
            result.error("io_error", e.message, null)
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        if (worker.isShutdown) {
            result.error("io_error", "Màn hình đã đóng", null)
            return
        }
        worker.execute {
            try {
                // Hàm không trả gì (ghi/xóa file) cho ra kotlin.Unit; StandardMessageCodec
                // không mã hóa được Unit và ném lỗi trên luồng chính → app crash sau mỗi
                // lần sao lưu tự động thành công (D9, Galaxy A13 2026-11-05).
                val value = block().let { if (it == Unit) null else it }
                main.post { result.success(value) }
            } catch (e: SecurityException) {
                main.post { result.error("permission_denied", e.message, null) }
            } catch (e: FileNotFoundException) {
                main.post { result.error("folder_missing", e.message, null) }
            } catch (e: IllegalArgumentException) {
                // Nhà cung cấp tài liệu báo thư mục không còn.
                main.post { result.error("folder_missing", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("io_error", e.message, null) }
            }
        }
    }

    /** Quyền ghi vào [tree] còn không (người dùng có thể thu hồi trong cài đặt hệ thống). */
    private fun requireWritePermission(tree: Uri) {
        val ok = resolver.persistedUriPermissions.any { it.uri == tree && it.isWritePermission }
        if (!ok) throw SecurityException("Quyền ghi vào thư mục đã bị thu hồi")
    }

    private fun rootDocument(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

    private fun docUri(tree: Uri, id: String): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, id)

    private fun folderName(tree: Uri): String? {
        val cursor = resolver.query(
            rootDocument(tree),
            arrayOf(DocumentsContract.Document.COLUMN_DISPLAY_NAME),
            null,
            null,
            null,
        ) ?: return null
        cursor.use { return if (it.moveToFirst()) it.getString(0) else null }
    }

    /** Danh sách (mã tài liệu, tên hiển thị) các mục con trực tiếp của thư mục. */
    private fun listFiles(tree: Uri): List<Pair<String, String>> {
        requireWritePermission(tree)
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree,
            DocumentsContract.getTreeDocumentId(tree),
        )
        val cursor = resolver.query(
            children,
            arrayOf(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            ),
            null,
            null,
            null,
        ) ?: throw FileNotFoundException("Không mở được thư mục")
        val out = ArrayList<Pair<String, String>>()
        cursor.use {
            while (it.moveToNext()) out.add(Pair(it.getString(0), it.getString(1)))
        }
        return out
    }

    /** Đổi tên tài liệu; ném lỗi nếu nhà cung cấp không đổi được. Trả về Uri mới. */
    private fun rename(doc: Uri, newName: String): Uri =
        DocumentsContract.renameDocument(resolver, doc, newName)
            ?: throw FileNotFoundException("Không đổi được tên file trong thư mục")

    private fun deleteQuietly(doc: Uri) {
        try {
            DocumentsContract.deleteDocument(resolver, doc)
        } catch (_: Exception) {
        }
    }

    private fun writeFile(tree: Uri, name: String, bytes: ByteArray) {
        val stamp = System.currentTimeMillis()
        val parent = rootDocument(tree)
        // 1) Ghi hết dữ liệu vào file tạm rồi đóng stream. Bị giết giữa chừng thì chỉ còn file
        //    `.part` (không khớp mẫu tên nên không bị tính vào số file giữ lại; bị dọn sau một ngày).
        val tmp = DocumentsContract.createDocument(resolver, parent, FILE_MIME, "$TMP_PREFIX$stamp.part")
            ?: throw FileNotFoundException("Không tạo được file trong thư mục")
        try {
            val stream = resolver.openOutputStream(tmp, "wt")
                ?: throw FileNotFoundException("Không mở được file để ghi")
            stream.use {
                it.write(bytes)
                it.flush()
            }
            // 2) Trùng tên (hai lần sao lưu trong cùng một phút): dời bản cũ sang tên dự phòng
            //    (nhà cung cấp không tự đổi thành "(1)"), đổi tên file tạm thành tên đích; chỉ khi
            //    thành công mới bỏ bản cũ, lỗi thì trả bản cũ về.
            val existing = listFiles(tree).filter { it.second == name }
            var backedUp: Uri? = null
            for ((i, e) in existing.withIndex()) {
                val old = docUri(tree, e.first)
                if (i == 0) {
                    backedUp = rename(old, "$TMP_PREFIX$stamp.old")
                } else {
                    DocumentsContract.deleteDocument(resolver, old)
                }
            }
            try {
                rename(tmp, name)
            } catch (e: Exception) {
                if (backedUp != null) {
                    try {
                        rename(backedUp, name)
                    } catch (_: Exception) {
                    }
                }
                throw e
            }
            if (backedUp != null) deleteQuietly(backedUp)
        } catch (e: Exception) {
            // Lỗi ở bước nào cũng bỏ file tạm (nếu đã đổi tên thì URI cũ không còn: xóa vô hại).
            deleteQuietly(tmp)
            throw e
        }
        cleanOrphans(tree, stamp)
    }

    /** Dọn file `.part`/`.old` mồ côi cũ hơn một ngày; chỉ chạm đúng mẫu tên tạm của app. */
    private fun cleanOrphans(tree: Uri, now: Long) {
        try {
            for ((id, display) in listFiles(tree)) {
                val m = TMP_NAME.matchEntire(display) ?: continue
                val ts = m.groupValues[1].toLongOrNull() ?: continue
                if (now - ts > ORPHAN_MAX_AGE_MS) deleteQuietly(docUri(tree, id))
            }
        } catch (_: Exception) {
            // Dọn dẹp không làm hỏng lần ghi đã xong.
        }
    }

    private fun deleteFile(tree: Uri, name: String) {
        for ((id, display) in listFiles(tree)) {
            if (display == name) {
                DocumentsContract.deleteDocument(resolver, docUri(tree, id))
            }
        }
    }

    private fun releaseFolder(tree: Uri) {
        try {
            resolver.releasePersistableUriPermission(
                tree,
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
            )
        } catch (_: SecurityException) {
            // Quyền đã mất từ trước: coi như đã bỏ.
        }
    }
}
