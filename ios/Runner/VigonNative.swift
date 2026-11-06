import Flutter
import UIKit
import UniformTypeIdentifiers
import WidgetKit

/// Phần gốc iOS của các tính năng 1.2 (D-022). Cùng tên kênh và giao thức với phía Android
/// (`MainActivity.kt`, `BackupFolderChannel.kt`, `WidgetProvider.kt`, `DeepLinkChannel.kt`), nên mã
/// Dart không phân biệt nền tảng:
/// - `vigon/secure` (F-22): che nội dung bằng lớp phủ khi app rời trạng thái hoạt động
///   (màn chuyển app chụp ảnh lúc đó). iOS không cho chặn chụp màn hình.
/// - `vigon/deeplink` (F-26): route từ nút Chi/Thu của widget (`vigon://open/entry/new?type=…`).
/// - `vigon/widget` (F-26): ghi dòng trạng thái vào App Group cho WidgetKit đọc.
/// - `vigon/backup_folder` (F-24): thư mục chọn bằng bộ chọn của app Tệp, giữ bằng bookmark.
enum VigonNative {
  /// Giữ tham chiếu mạnh: registrar không chắc giữ đối tượng scene delegate.
  private static var scene: VigonSceneHandler?
  private static var folder: BackupFolderChannel?

  static func register(registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "VigonNative") else { return }
    let messenger = registrar.messenger()
    let handler = VigonSceneHandler(messenger: messenger)
    registrar.addSceneDelegate(handler)
    scene = handler
    folder = BackupFolderChannel(messenger: messenger)
    WidgetChannel.register(messenger: messenger)
  }
}

// MARK: - F-22 che nội dung, F-26 liên kết sâu

/// Nhận sự kiện vòng đời scene qua `FlutterSceneDelegate` (đăng ký bằng `addSceneDelegate`),
/// theo tên Swift của giao thức `FlutterSceneLifeCycleDelegate` (đã kiểm bằng trình biên dịch trên CI).
final class VigonSceneHandler: NSObject, FlutterSceneLifeCycleDelegate {
  static let urlScheme = "vigon"
  static let urlHost = "open"

  private let deepLink: FlutterMethodChannel
  private let secure: FlutterMethodChannel
  private var pendingRoute: String?
  private var secureEnabled = false
  private var cover: UIView?

  init(messenger: FlutterBinaryMessenger) {
    deepLink = FlutterMethodChannel(name: "vigon/deeplink", binaryMessenger: messenger)
    secure = FlutterMethodChannel(name: "vigon/secure", binaryMessenger: messenger)
    super.init()
    deepLink.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takePending" else {
        result(FlutterMethodNotImplemented)
        return
      }
      result(self?.pendingRoute)
      self?.pendingRoute = nil
    }
    secure.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setSecure" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let on = call.arguments as? Bool else {
        result(FlutterError(code: "bad_args", message: "setSecure needs true/false", details: nil))
        return
      }
      self?.secureEnabled = on
      if !on { self?.hideCover() }
      NSLog("VigonSecure: enabled=%@", on ? "1" : "0")
      result(nil)
    }
  }

  func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions?
  ) -> Bool {
    guard let contexts = connectionOptions?.urlContexts, !contexts.isEmpty else { return false }
    return accept(contexts, notify: false)
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) -> Bool {
    accept(URLContexts, notify: true)
  }

  func sceneWillResignActive(_ scene: UIScene) {
    showCover(in: scene)
  }

  func sceneDidEnterBackground(_ scene: UIScene) {
    showCover(in: scene)
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    hideCover()
    takeWidgetRoute()
  }

  /// Nút Chi/Thu của widget nhỏ (iOS 17+) chạy intent mở app và để route trong App Group
  /// (`OpenEntryIntent` ở VigonWidget). Chỉ nhận route vừa để trong 60 giây.
  private func takeWidgetRoute() {
    guard let store = UserDefaults(suiteName: WidgetChannel.appGroup),
      let route = store.string(forKey: WidgetChannel.pendingRouteKey)
    else { return }
    let at = store.double(forKey: WidgetChannel.pendingAtKey)
    store.removeObject(forKey: WidgetChannel.pendingRouteKey)
    store.removeObject(forKey: WidgetChannel.pendingAtKey)
    guard abs(Date().timeIntervalSince1970 - at) < 60 else { return }
    pendingRoute = route
    NSLog("VigonDeepLink: pending route %@ (widget intent)", route)
    deepLink.invokeMethod("routeAvailable", arguments: nil)
  }

  /// Chuyển URL `vigon://open/<route>` thành route cho Dart; Dart vẫn lọc bằng
  /// `allowedDeepLinkRoute` (chỉ `/entry/new?type=expense|income`).
  static func route(from url: URL) -> String? {
    guard url.scheme?.lowercased() == urlScheme, url.host?.lowercased() == urlHost else {
      return nil
    }
    guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
    var route = parts.path.isEmpty ? "/" : parts.path
    if let query = parts.percentEncodedQuery, !query.isEmpty { route += "?" + query }
    return route
  }

  private func accept(_ contexts: Set<UIOpenURLContext>, notify: Bool) -> Bool {
    guard let route = contexts.lazy.compactMap({ Self.route(from: $0.url) }).first else {
      return false
    }
    pendingRoute = route
    NSLog("VigonDeepLink: pending route %@", route)
    if notify { deepLink.invokeMethod("routeAvailable", arguments: nil) }
    return true
  }

  private func showCover(in scene: UIScene) {
    guard secureEnabled, cover == nil,
      let window = (scene as? UIWindowScene)?.windows.first(where: { $0.isKeyWindow })
        ?? (scene as? UIWindowScene)?.windows.first
    else { return }
    let view = PrivacyCoverView(frame: window.bounds)
    window.addSubview(view)
    cover = view
    NSLog("VigonSecure: cover shown")
  }

  private func hideCover() {
    cover?.removeFromSuperview()
    cover = nil
  }
}

/// Lớp phủ che nội dung: màu nền app (token `surface` sáng/tối) và logo ở giữa.
final class PrivacyCoverView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)
    autoresizingMask = [.flexibleWidth, .flexibleHeight]
    backgroundColor = UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(red: 0x0F / 255, green: 0x15 / 255, blue: 0x13 / 255, alpha: 1)
        : UIColor(red: 0xF7 / 255, green: 0xFA / 255, blue: 0xF8 / 255, alpha: 1)
    }
    isAccessibilityElement = false
    let logo = UIImageView(image: UIImage(named: "PrivacyLogo"))
    logo.translatesAutoresizingMaskIntoConstraints = false
    logo.layer.cornerRadius = 22
    logo.layer.cornerCurve = .continuous
    logo.clipsToBounds = true
    addSubview(logo)
    NSLayoutConstraint.activate([
      logo.widthAnchor.constraint(equalToConstant: 96),
      logo.heightAnchor.constraint(equalToConstant: 96),
      logo.centerXAnchor.constraint(equalTo: centerXAnchor),
      logo.centerYAnchor.constraint(equalTo: centerYAnchor),
    ])
  }

  required init?(coder: NSCoder) { nil }
}

// MARK: - F-26 dữ liệu widget

/// Kênh `vigon/widget`: "show" ghi `{line, validUntil?}`, "clear" XÓA hẳn (D-016). Dữ liệu nằm trong
/// UserDefaults của App Group để extension WidgetKit đọc; chỉ có chuỗi đã định dạng sẵn.
enum WidgetChannel {
  static let appGroup = "group.com.phiotron.vigon"
  static let lineKey = "widget.line"
  static let validUntilKey = "widget.validUntil"
  static let staleKey = "widget.stale"
  static let pendingRouteKey = "widget.pendingRoute"
  static let pendingAtKey = "widget.pendingAt"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "vigon/widget", binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      guard let store = UserDefaults(suiteName: appGroup) else {
        result(FlutterError(code: "no_group", message: "App Group unavailable", details: nil))
        return
      }
      switch call.method {
      case "show":
        let args = call.arguments as? [String: Any]
        guard let line = args?["line"] as? String, !line.isEmpty else {
          result(FlutterError(code: "bad_args", message: "show needs {line}", details: nil))
          return
        }
        store.set(line, forKey: lineKey)
        store.removeObject(forKey: staleKey)
        if let until = args?["validUntil"] as? NSNumber {
          store.set(until.doubleValue, forKey: validUntilKey)
        } else {
          store.removeObject(forKey: validUntilKey)
        }
      case "clear":
        store.removeObject(forKey: lineKey)
        store.removeObject(forKey: validUntilKey)
        store.removeObject(forKey: staleKey)
      default:
        result(FlutterMethodNotImplemented)
        return
      }
      WidgetCenter.shared.reloadAllTimelines()
      NSLog("VigonWidget: %@", call.method)
      result(nil)
    }
  }
}

// MARK: - F-24 thư mục sao lưu tự động

/// Kênh `vigon/backup_folder` (cùng giao thức với `BackupFolderChannel.kt`). Thư mục chọn bằng
/// `UIDocumentPickerViewController` (app Tệp: iCloud Drive, Trên iPhone, nhà cung cấp khác). Quyền
/// được giữ bằng bookmark lưu trong UserDefaults của app; Dart chỉ giữ mã `ios-bookmark:<uuid>`
/// (bookmark cũ thì tạo lại tại chỗ, Dart không cần biết). Lỗi trả về cùng mã với Android:
/// `permission_denied`, `folder_missing`, `busy`, `bad_args`, `io_error`.
final class BackupFolderChannel: NSObject, UIDocumentPickerDelegate {
  static let prefix = "ios-bookmark:"
  private let channel: FlutterMethodChannel
  private let queue = DispatchQueue(label: "com.phiotron.vigon.backupFolder")
  private var pickResult: FlutterResult?

  private struct Failure: Error {
    let code: String
    let message: String
  }

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "vigon/backup_folder", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    if call.method == "pickFolder" {
      pick(result: result)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    guard let uri = args["treeUri"] as? String else {
      result(FlutterError(code: "bad_args", message: "treeUri required", details: nil))
      return
    }
    let name = args["name"] as? String
    let bytes = (args["bytes"] as? FlutterStandardTypedData)?.data
    queue.async {
      let reply: Any?
      do {
        switch call.method {
        case "writeFile":
          guard let name = name, Self.safeName(name), let bytes = bytes else {
            throw Failure(code: "bad_args", message: "name and bytes required")
          }
          try self.write(uri: uri, name: name, data: bytes)
          reply = nil
        case "listFiles":
          reply = try self.list(uri: uri)
        case "deleteFile":
          guard let name = name, Self.safeName(name) else {
            throw Failure(code: "bad_args", message: "name required")
          }
          try self.delete(uri: uri, name: name)
          reply = nil
        case "releaseFolder":
          UserDefaults.standard.removeObject(forKey: Self.key(uri))
          reply = nil
        default:
          DispatchQueue.main.async { result(FlutterMethodNotImplemented) }
          return
        }
      } catch let f as Failure {
        NSLog("VigonBackupFolder: %@ failed %@", call.method, f.code)
        DispatchQueue.main.async {
          result(FlutterError(code: f.code, message: f.message, details: nil))
        }
        return
      } catch {
        let f = Self.failure(from: error)
        NSLog("VigonBackupFolder: %@ failed %@", call.method, f.code)
        DispatchQueue.main.async {
          result(FlutterError(code: f.code, message: f.message, details: nil))
        }
        return
      }
      DispatchQueue.main.async { result(reply) }
    }
  }

  // MARK: Bộ chọn thư mục

  private func pick(result: @escaping FlutterResult) {
    guard pickResult == nil else {
      result(FlutterError(code: "busy", message: "picker already open", details: nil))
      return
    }
    guard let top = Self.topViewController() else {
      result(FlutterError(code: "io_error", message: "no view controller", details: nil))
      return
    }
    let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.folder])
    picker.allowsMultipleSelection = false
    picker.delegate = self
    pickResult = result
    top.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let result = pickResult else { return }
    pickResult = nil
    guard let url = urls.first else {
      result(nil)
      return
    }
    let accessing = url.startAccessingSecurityScopedResource()
    defer { if accessing { url.stopAccessingSecurityScopedResource() } }
    do {
      let bookmark = try url.bookmarkData(
        options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
      let uri = Self.prefix + UUID().uuidString
      UserDefaults.standard.set(bookmark, forKey: Self.key(uri))
      let inICloud =
        (try? url.resourceValues(forKeys: [.isUbiquitousItemKey]))?.isUbiquitousItem ?? false
      NSLog("VigonBackupFolder: picked iCloud=%@", inICloud ? "1" : "0")
      result(["uri": uri, "name": url.lastPathComponent, "inICloud": inICloud])
    } catch {
      result(FlutterError(code: "permission_denied", message: error.localizedDescription, details: nil))
    }
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    pickResult?(nil)
    pickResult = nil
  }

  private static func topViewController() -> UIViewController? {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    let window = scenes.flatMap { $0.windows }.first { $0.isKeyWindow }
      ?? scenes.flatMap { $0.windows }.first
    var top = window?.rootViewController
    while let presented = top?.presentedViewController { top = presented }
    return top
  }

  // MARK: Ghi, liệt kê, xóa

  static func key(_ uri: String) -> String { "vigon.backupFolder." + uri }

  /// Chỉ nhận tên file đơn (không có `/`, không `..`), để không ghi ra ngoài thư mục đã chọn.
  static func safeName(_ name: String) -> Bool {
    !name.isEmpty && !name.contains("/") && name != "." && name != ".."
  }

  /// Mở thư mục từ bookmark, xin quyền, kiểm còn tồn tại rồi chạy [body].
  private func withFolder<T>(_ uri: String, _ body: (URL) throws -> T) throws -> T {
    guard uri.hasPrefix(Self.prefix), let data = UserDefaults.standard.data(forKey: Self.key(uri))
    else { throw Failure(code: "folder_missing", message: "unknown folder") }
    var stale = false
    let url: URL
    do {
      url = try URL(
        resolvingBookmarkData: data, options: [], relativeTo: nil, bookmarkDataIsStale: &stale)
    } catch {
      throw Failure(code: "folder_missing", message: error.localizedDescription)
    }
    guard url.startAccessingSecurityScopedResource() else {
      throw Failure(code: "permission_denied", message: "security scope refused")
    }
    defer { url.stopAccessingSecurityScopedResource() }
    if stale,
      let fresh = try? url.bookmarkData(options: [], includingResourceValuesForKeys: nil, relativeTo: nil)
    {
      UserDefaults.standard.set(fresh, forKey: Self.key(uri))
    }
    var isDir: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue
    else { throw Failure(code: "folder_missing", message: "folder not found") }
    return try body(url)
  }

  private func coordinate(
    _ url: URL, writing: Bool, options: NSFileCoordinator.WritingOptions = [],
    _ body: @escaping (URL) throws -> Void
  ) throws {
    var coordError: NSError?
    var bodyError: Error?
    let coordinator = NSFileCoordinator(filePresenter: nil)
    if writing {
      coordinator.coordinate(writingItemAt: url, options: options, error: &coordError) { u in
        do { try body(u) } catch { bodyError = error }
      }
    } else {
      coordinator.coordinate(readingItemAt: url, options: [], error: &coordError) { u in
        do { try body(u) } catch { bodyError = error }
      }
    }
    if let e = coordError { throw e }
    if let e = bodyError { throw e }
  }

  private func write(uri: String, name: String, data: Data) throws {
    try withFolder(uri) { folder in
      try coordinate(folder.appendingPathComponent(name), writing: true, options: .forReplacing) {
        try data.write(to: $0, options: .atomic)
      }
    }
  }

  /// Tên các mục trong thư mục. File iCloud chưa tải về có dạng `.<tên>.icloud`: trả tên thật
  /// để việc giữ 2 file vẫn đếm và dọn được chúng.
  private func list(uri: String) throws -> [String] {
    try withFolder(uri) { folder in
      var names: [String] = []
      try coordinate(folder, writing: false) { u in
        names = try FileManager.default.contentsOfDirectory(atPath: u.path).map(Self.logicalName)
      }
      return names
    }
  }

  static func logicalName(_ name: String) -> String {
    if name.hasPrefix("."), name.hasSuffix(".icloud"), name.count > ".icloud".count + 1 {
      return String(name.dropFirst().dropLast(".icloud".count))
    }
    return name
  }

  private func delete(uri: String, name: String) throws {
    try withFolder(uri) { folder in
      var target = folder.appendingPathComponent(name)
      let placeholder = folder.appendingPathComponent("." + name + ".icloud")
      if !FileManager.default.fileExists(atPath: target.path),
        FileManager.default.fileExists(atPath: placeholder.path)
      {
        target = placeholder
      }
      guard FileManager.default.fileExists(atPath: target.path) else { return }
      try coordinate(target, writing: true, options: .forDeleting) {
        try FileManager.default.removeItem(at: $0)
      }
    }
  }

  private static func failure(from error: Error) -> Failure {
    let ns = error as NSError
    if ns.domain == NSCocoaErrorDomain {
      switch ns.code {
      case NSFileWriteNoPermissionError, NSFileReadNoPermissionError:
        return Failure(code: "permission_denied", message: ns.localizedDescription)
      case NSFileNoSuchFileError, NSFileReadNoSuchFileError:
        return Failure(code: "folder_missing", message: ns.localizedDescription)
      default:
        break
      }
    }
    if ns.domain == NSPOSIXErrorDomain, ns.code == Int(EACCES) || ns.code == Int(EPERM) {
      return Failure(code: "permission_denied", message: ns.localizedDescription)
    }
    return Failure(code: "io_error", message: ns.localizedDescription)
  }
}
