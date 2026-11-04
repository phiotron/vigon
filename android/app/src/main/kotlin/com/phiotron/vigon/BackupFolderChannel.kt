package com.phiotron.vigon

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileNotFoundException
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
 */
class BackupFolderChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {
    companion object {
        const val CHANNEL = "vigon/backup_folder"
        private const val REQUEST_PICK_FOLDER = 4201
        private const val FILE_MIME = "application/octet-stream"
    }

    private val resolver get() = activity.contentResolver
    private val main = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor()
    private var pendingPick: MethodChannel.Result? = null

    init {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "pickFolder" -> pickFolder(result)
            "writeFile" -> {
                val tree = call.argument<String>("treeUri")
                val name = call.argument<String>("name")
                val bytes = call.argument<ByteArray>("bytes")
                if (tree == null || name == null || bytes == null || !validName(name)) {
                    result.error("bad_args", "writeFile cần treeUri, name hợp lệ và bytes", null)
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
                if (tree == null || name == null || !validName(name)) {
                    result.error("bad_args", "deleteFile cần treeUri và name hợp lệ", null)
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
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).addFlags(
            Intent.FLAG_GRANT_READ_URI_PERMISSION or
                Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION or
                Intent.FLAG_GRANT_PREFIX_URI_PERMISSION,
        )
        pendingPick = result
        try {
            @Suppress("DEPRECATION")
            activity.startActivityForResult(intent, REQUEST_PICK_FOLDER)
        } catch (e: Exception) {
            // Máy không có bộ chọn thư mục.
            pendingPick = null
            result.error("io_error", e.message, null)
        }
    }

    private fun runAsync(result: MethodChannel.Result, block: () -> Any?) {
        worker.execute {
            try {
                val value = block()
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

    /** Tên file chỉ là một thành phần: không dấu gạch chéo, không rỗng. */
    private fun validName(name: String) =
        name.isNotEmpty() && !name.contains('/') && !name.contains('\\') && name != "." && name != ".."

    /** Quyền ghi vào [tree] còn không (người dùng có thể thu hồi trong cài đặt hệ thống). */
    private fun requireWritePermission(tree: Uri) {
        val ok = resolver.persistedUriPermissions.any { it.uri == tree && it.isWritePermission }
        if (!ok) throw SecurityException("Quyền ghi vào thư mục đã bị thu hồi")
    }

    private fun rootDocument(tree: Uri): Uri =
        DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree))

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

    private fun writeFile(tree: Uri, name: String, bytes: ByteArray) {
        // Trùng tên (hai lần sao lưu trong cùng một phút): xóa bản cũ để nhà cung cấp không
        // tự đổi tên thành "(1)".
        deleteFile(tree, name)
        val parent = rootDocument(tree)
        val doc = DocumentsContract.createDocument(resolver, parent, FILE_MIME, name)
            ?: throw FileNotFoundException("Không tạo được file trong thư mục")
        try {
            val stream = resolver.openOutputStream(doc, "wt")
                ?: throw FileNotFoundException("Không mở được file để ghi")
            stream.use {
                it.write(bytes)
                it.flush()
            }
        } catch (e: Exception) {
            // Không để lại file dở dang.
            try {
                DocumentsContract.deleteDocument(resolver, doc)
            } catch (_: Exception) {
            }
            throw e
        }
    }

    private fun deleteFile(tree: Uri, name: String) {
        for ((id, display) in listFiles(tree)) {
            if (display == name) {
                DocumentsContract.deleteDocument(
                    resolver,
                    DocumentsContract.buildDocumentUriUsingTree(tree, id),
                )
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
