import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Nhắc ghi sổ (F-25): flutter_local_notifications nhận chạm thông báo và
    // hiện thông báo khi app đang mở qua delegate này.
    UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "VigonBackupExclusion") {
      BackupExclusionChannel.register(messenger: registrar.messenger())
    }
    // D-022: che nội dung (F-22), sao lưu tự động (F-24), widget + liên kết sâu (F-26).
    VigonNative.register(registry: engineBridge.pluginRegistry)
  }
}

/// Kênh `vigon/backup_exclusion`: loại cơ sở dữ liệu khỏi bản sao lưu iCloud/máy tính
/// (giống Android `allowBackup="false"`). Dart gọi sau mỗi lần mở cơ sở dữ liệu
/// (`lib/src/data/device_backup_exclusion.dart`). Đường dẫn chưa tồn tại thì bỏ qua.
enum BackupExclusionChannel {
  static let name = "vigon/backup_exclusion"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: name, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let args = call.arguments as? [String: Any],
        let paths = args["paths"] as? [String]
      else {
        result(FlutterError(code: "bad_args", message: "paths required", details: nil))
        return
      }
      result(exclude(paths: paths))
    }
  }

  /// Đặt cờ cho từng đường dẫn đang tồn tại; trả số mục đã đặt và đọc lại thấy cờ bật.
  /// Lỗi từng mục chỉ ghi log (CI đọc dòng log này trên simulator).
  static func exclude(paths: [String]) -> Int {
    var excluded = 0
    var failed: [String] = []
    for path in paths where FileManager.default.fileExists(atPath: path) {
      var url = URL(fileURLWithPath: path)
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      do {
        try url.setResourceValues(values)
        var check = URL(fileURLWithPath: path)
        check.removeAllCachedResourceValues()
        if try check.resourceValues(forKeys: [.isExcludedFromBackupKey]).isExcludedFromBackup == true {
          excluded += 1
        } else {
          failed.append(url.lastPathComponent)
        }
      } catch {
        failed.append("\(url.lastPathComponent): \(error.localizedDescription)")
      }
    }
    NSLog("VigonBackupExclusion: excluded=%ld failed=%ld %@", excluded, failed.count,
          failed.joined(separator: "; "))
    return excluded
  }
}
