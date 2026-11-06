import 'auto_backup_service.dart';
import 'backup_folder_service.dart';
import 'database.dart';
import 'pin_service.dart';

/// Một lần chạy sao lưu theo lịch khi app đóng (Android, D-026): Kotlin
/// `BackupJobService` dựng một FlutterEngine không giao diện và gọi
/// `autoBackupBackgroundMain` trong `lib/main.dart`, hàm đó gọi tới đây.
///
/// Mở cơ sở dữ liệu, đọc mật khẩu từ Keystore ([SecretStore]), mã hoá và ghi
/// qua Storage Access Framework bằng đúng [AutoBackupService] mà app dùng
/// (một lần mỗi mốc giờ, chỉ khi dữ liệu đổi, giữ 7 file, lỗi cũng ghi
/// `lastAt`). Lịch lần sau do phía Kotlin đặt ngay khi báo thức nổ, nên Dart
/// lỗi hay bị dừng giữa chừng cũng không làm đứt chuỗi lịch.
///
/// Trả kết quả lần thử (null: chưa tới mốc, đã xử lý, tắt hoặc dữ liệu không
/// đổi). Không ném lỗi; luôn đóng cơ sở dữ liệu.
Future<AutoBackupResult?> runScheduledAutoBackup({
  required AppDatabase Function() openDatabase,
  SecretStore secrets = const SecureSecretStore(),
  BackupFolderService folder = const BackupFolderService(),
  DateTime Function() clock = DateTime.now,
  BackupEncryptor? encrypt,
}) async {
  AppDatabase? db;
  try {
    db = openDatabase();
    final service = encrypt == null
        ? AutoBackupService(
            db: db,
            folder: folder,
            secrets: secrets,
            clock: clock,
          )
        : AutoBackupService(
            db: db,
            folder: folder,
            secrets: secrets,
            clock: clock,
            encrypt: encrypt,
          );
    // Tắt thì không mở cơ sở dữ liệu lâu hơn cần thiết.
    if (!(await service.state()).enabled) return null;
    return await service.maybeRunIfDue();
  } catch (_) {
    return null;
  } finally {
    try {
      await db?.close();
    } catch (_) {}
  }
}
