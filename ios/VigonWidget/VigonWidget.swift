import AppIntents
import SwiftUI
import WidgetKit

// Widget màn hình chính Ví Gọn trên iOS (F-26, D-016, D-022), bố cục theo EXT-01 của Android:
// - nhỏ (2×2): hàng trên + hai nút Chi/Thu xếp dọc, chữ trạng thái tối đa 2 dòng (A15);
// - vừa (4×2): hai nút cạnh nhau, chữ 1 dòng.
// Dữ liệu chỉ là một chuỗi đã định dạng sẵn do app ghi vào App Group (`WidgetChannel` trong
// Runner/VigonNative.swift). Không mạng, không đọc cơ sở dữ liệu.

enum VigonWidgetStore {
  static let appGroup = "group.com.phiotron.vigon"
  static let lineKey = "widget.line"
  static let validUntilKey = "widget.validUntil"
  static let staleKey = "widget.stale"
  static let pendingRouteKey = "widget.pendingRoute"
  static let pendingAtKey = "widget.pendingAt"
}

/// Màu `widget-*` (token v3, kiểu "Ngọc lục bảo & vàng"), giống Android: chủ đề sáng =
/// `res/values/widget_colors.xml`, tối (`…Dark`) = `res/values-night/widget_colors.xml`.
enum VigonWidgetColor {
  static let surface = Color(red: 0xFB / 255, green: 0xF8 / 255, blue: 0xF1 / 255)
  static let surfaceEnd = Color(red: 0xF3 / 255, green: 0xEC / 255, blue: 0xDD / 255)
  static let ink = Color(red: 0x0E / 255, green: 0x3B / 255, blue: 0x32 / 255)
  static let gold = Color(red: 0x6E / 255, green: 0x5C / 255, blue: 0x34 / 255)
  static let outline = Color(red: 0xD9 / 255, green: 0xC4 / 255, blue: 0x8F / 255)
  static let action = Color(red: 0xEF / 255, green: 0xE5 / 255, blue: 0xCF / 255)
  static let expense = Color(red: 0xC0 / 255, green: 0x46 / 255, blue: 0x3A / 255)
  static let income = Color(red: 0x1F / 255, green: 0x7A / 255, blue: 0x5C / 255)
  static let surfaceDark = Color(red: 0x0A / 255, green: 0x2F / 255, blue: 0x27 / 255)
  static let surfaceEndDark = Color(red: 0x06 / 255, green: 0x20 / 255, blue: 0x19 / 255)
  static let inkDark = Color(red: 0xF4 / 255, green: 0xEB / 255, blue: 0xD3 / 255)
  static let goldDark = Color(red: 0xD6 / 255, green: 0xB6 / 255, blue: 0x6E / 255)
  static let outlineDark = Color(red: 0x7D / 255, green: 0x6B / 255, blue: 0x3F / 255)
  static let actionDark = Color(red: 0x1B / 255, green: 0x3E / 255, blue: 0x36 / 255)
  static let onAction = Color.white
}

/// Bộ màu theo sáng/tối của máy (huy hiệu Chi/Thu giống nhau ở hai chủ đề).
struct VigonWidgetPalette {
  let surface, surfaceEnd, ink, gold, outline, action: Color

  init(_ scheme: ColorScheme) {
    let dark = scheme == .dark
    surface = dark ? VigonWidgetColor.surfaceDark : VigonWidgetColor.surface
    surfaceEnd = dark ? VigonWidgetColor.surfaceEndDark : VigonWidgetColor.surfaceEnd
    ink = dark ? VigonWidgetColor.inkDark : VigonWidgetColor.ink
    gold = dark ? VigonWidgetColor.goldDark : VigonWidgetColor.gold
    outline = dark ? VigonWidgetColor.outlineDark : VigonWidgetColor.outline
    action = dark ? VigonWidgetColor.actionDark : VigonWidgetColor.action
  }
}

enum VigonWidgetState: Equatable {
  /// Mặc định (công tắc tắt): logo + "Ví Gọn", không số.
  case brand
  /// "Tháng này đã chi X" (công tắc bật, PIN tắt).
  case amount(String)
  /// "Đã khóa bằng PIN": dòng không có hạn dùng (app không bao giờ gửi số mà thiếu hạn).
  case locked(String)
  /// Hết kỳ tháng mà app chưa đẩy số mới: số cũ đã bị xóa.
  case stale
}

struct VigonEntry: TimelineEntry {
  let date: Date
  let state: VigonWidgetState
}

struct VigonProvider: TimelineProvider {
  func placeholder(in context: Context) -> VigonEntry {
    VigonEntry(date: Date(), state: .brand)
  }

  func getSnapshot(in context: Context, completion: @escaping (VigonEntry) -> Void) {
    // Bộ chọn widget luôn thấy trạng thái mặc định, không bao giờ thấy số.
    completion(
      context.isPreview
        ? placeholder(in: context) : VigonEntry(date: Date(), state: Self.read(now: Date()).0))
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<VigonEntry>) -> Void) {
    let now = Date()
    let (state, until) = Self.read(now: now)
    var entries = [VigonEntry(date: now, state: state)]
    // Hết kỳ: đổi sang "Mở app để cập nhật" đúng lúc, không chờ app.
    if case .amount = state, let until = until { entries.append(VigonEntry(date: until, state: .stale)) }
    // App đẩy lại timeline mỗi khi dữ liệu đổi (WidgetCenter.reloadAllTimelines).
    completion(Timeline(entries: entries, policy: .never))
  }

  /// Đọc App Group; số đã quá hạn thì XÓA khỏi bộ nhớ (D-016) và nhớ là đang chờ app.
  static func read(now: Date) -> (VigonWidgetState, Date?) {
    guard let store = UserDefaults(suiteName: VigonWidgetStore.appGroup) else { return (.brand, nil) }
    guard let line = store.string(forKey: VigonWidgetStore.lineKey), !line.isEmpty else {
      return (store.bool(forKey: VigonWidgetStore.staleKey) ? .stale : .brand, nil)
    }
    let ms = store.double(forKey: VigonWidgetStore.validUntilKey)
    if ms <= 0 { return (.locked(line), nil) }
    let until = Date(timeIntervalSince1970: ms / 1000)
    if now >= until {
      store.removeObject(forKey: VigonWidgetStore.lineKey)
      store.removeObject(forKey: VigonWidgetStore.validUntilKey)
      store.set(true, forKey: VigonWidgetStore.staleKey)
      return (.stale, nil)
    }
    return (.amount(line), until)
  }
}

/// Loại khoản của nút. Route đúng hai giá trị Dart chấp nhận (`allowedDeepLinkRoute`).
enum VigonEntryKind: String {
  case expense
  case income

  var url: URL { URL(string: "vigon://open/entry/new?type=\(rawValue)")! }
  var route: String { "/entry/new?type=\(rawValue)" }
}

/// Nút trong widget nhỏ (iOS 17+): widget nhỏ không nhận `Link`, nên nút chạy intent mở app và
/// để lại route trong App Group; app lấy route khi trở lại hoạt động (`VigonSceneHandler`).
@available(iOSApplicationExtension 17.0, *)
struct OpenEntryIntent: AppIntent {
  static var title: LocalizedStringResource = "Ví Gọn"
  static var openAppWhenRun: Bool = true
  static var isDiscoverable: Bool = false

  @Parameter(title: "Type")
  var type: String

  init() { type = VigonEntryKind.expense.rawValue }

  init(kind: VigonEntryKind) { type = kind.rawValue }

  func perform() async throws -> some IntentResult {
    let kind = VigonEntryKind(rawValue: type) ?? .expense
    let store = UserDefaults(suiteName: VigonWidgetStore.appGroup)
    store?.set(kind.route, forKey: VigonWidgetStore.pendingRouteKey)
    store?.set(Date().timeIntervalSince1970, forKey: VigonWidgetStore.pendingAtKey)
    return .result()
  }
}

struct VigonWidgetView: View {
  @Environment(\.widgetFamily) private var family
  @Environment(\.colorScheme) private var scheme
  let entry: VigonEntry

  private var palette: VigonWidgetPalette { VigonWidgetPalette(scheme) }

  private var wide: Bool { family != .systemSmall }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      header
      if wide {
        HStack(spacing: 8) { buttons }
      } else {
        VStack(spacing: 8) { buttons }
      }
    }
    .vigonWidgetBackground(palette)
    // Widget nhỏ trên iOS 15–16 là một vùng chạm duy nhất: mở màn nhập khoản chi.
    .widgetURL(VigonEntryKind.expense.url)
  }

  @ViewBuilder private var header: some View {
    HStack(alignment: .top, spacing: 6) {
      switch entry.state {
      case .brand:
        Image("WidgetLogo")
          .resizable()
          .frame(width: 18, height: 18)
          .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
          .accessibilityHidden(true)
        Text("appTitle")
          .font(.system(size: 14, weight: .semibold))
          .kerning(0.5)
          .foregroundColor(palette.ink)
      case .amount(let line):
        statusText(Text(line))
      case .locked(let line):
        Image(systemName: "lock.fill")
          .font(.system(size: 13))
          .accessibilityHidden(true)
        statusText(Text(line))
      case .stale:
        Image(systemName: "arrow.clockwise")
          .font(.system(size: 13, weight: .semibold))
          .accessibilityHidden(true)
        statusText(Text("widgetStale"))
      }
      Spacer(minLength: 0)
    }
    // Dòng trạng thái và icon đi kèm: vàng (widget-gold); tên app ghi đè sang widget-ink.
    .foregroundColor(palette.gold)
    .padding(.horizontal, 4)
    .padding(.top, 2)
    .frame(minHeight: 20, alignment: .topLeading)
  }

  private func statusText(_ text: Text) -> some View {
    text
      .font(.system(size: 12, weight: .medium))
      .lineLimit(wide ? 1 : 2)
      .truncationMode(.tail)
  }

  @ViewBuilder private var buttons: some View {
    entryButton(.expense)
    entryButton(.income)
  }

  @ViewBuilder private func entryButton(_ kind: VigonEntryKind) -> some View {
    let face = ButtonFace(kind: kind, palette: palette)
    if wide {
      Link(destination: kind.url) { face }
    } else if #available(iOSApplicationExtension 17.0, *) {
      Button(intent: OpenEntryIntent(kind: kind)) { face }
        .buttonStyle(.plain)
    } else {
      face
    }
  }
}

/// Mặt nút: huy hiệu tròn −/+ và chữ (không chỉ dựa vào màu) trên khối widget-action, bo 16.
struct ButtonFace: View {
  let kind: VigonEntryKind
  let palette: VigonWidgetPalette

  var body: some View {
    HStack(spacing: 10) {
      Image(systemName: kind == .expense ? "minus" : "plus")
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(VigonWidgetColor.onAction)
        .frame(width: 28, height: 28)
        .background(Circle().fill(kind == .expense ? VigonWidgetColor.expense : VigonWidgetColor.income))
      Text(LocalizedStringKey(kind == .expense ? "widgetExpenseButton" : "widgetIncomeButton"))
        .font(.system(size: 15, weight: .semibold))
        .foregroundColor(palette.ink)
        .lineLimit(1)
        .minimumScaleFactor(0.8)
      Spacer(minLength: 0)
    }
    .padding(.leading, 8)
    .padding(.trailing, 10)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .frame(minHeight: 40)
    .background(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(palette.action)
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(Text(LocalizedStringKey(kind == .expense ? "addExpense" : "addIncome")))
    .accessibilityAddTraits(.isButton)
  }
}

/// Nền widget: dải chuyển màu rất nhẹ (trên trái → dưới phải) và viền vàng mảnh.
struct VigonWidgetSurface: View {
  let palette: VigonWidgetPalette

  var body: some View {
    ZStack {
      LinearGradient(
        colors: [palette.surface, palette.surfaceEnd],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
      // Nét 2pt trên mép hình: nửa ngoài bị cắt, còn 1pt bên trong.
      ContainerRelativeShape().stroke(palette.outline, lineWidth: 2)
    }
  }
}

extension View {
  /// iOS 17 bắt buộc `containerBackground` (thiếu thì hệ thống hiện màn báo lỗi thay widget).
  @ViewBuilder func vigonWidgetBackground(_ palette: VigonWidgetPalette) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      containerBackground(for: .widget) { VigonWidgetSurface(palette: palette) }
    } else {
      padding(10).background(VigonWidgetSurface(palette: palette))
    }
  }
}

@main
struct VigonWidget: Widget {
  let kind = "VigonWidget"

  var body: some WidgetConfiguration {
    StaticConfiguration(kind: kind, provider: VigonProvider()) { entry in
      VigonWidgetView(entry: entry)
    }
    .configurationDisplayName("widgetPickerName")
    .description("widgetPickerDescription")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
