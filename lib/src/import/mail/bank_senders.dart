/// Danh mục ngân hàng nguồn của email biên lai (AC-81, AC-83, D-030).
///
/// Địa chỉ gửi của từng ngân hàng điền ở `senders` (viết thường), cùng với mẫu
/// và test của bộ đọc. Chưa có địa chỉ nào thì ngân hàng đó coi
/// như chưa hỗ trợ: không hiện ở đâu và app không tải thư nào (không mở kết
/// nối để tìm thư).
class BankSource {
  const BankSource({
    required this.id,
    required this.name,
    required this.senders,
  });

  /// Mã nội bộ, vd `mb`.
  final String id;

  /// Tên hiển thị (tên riêng, không dịch), vd "MB Bank".
  final String name;

  /// Địa chỉ gửi được phép, viết thường, so khớp NGUYÊN địa chỉ.
  final Set<String> senders;

  /// Có email mẫu thật và test đạt (AC-83) — ở đây: đã có địa chỉ gửi.
  bool get isSupported => senders.isNotEmpty;
}

/// Địa chỉ gửi email biên lai của MB Bank — MỘT chỗ duy nhất trong app.
///
/// **GIẢ ĐỊNH, chưa xác minh:** ảnh chụp mẫu chỉ thấy `mbebanking@mbb…` (bị
/// cắt) và chân thư dùng tên miền `mbbank.com.vn`. Người dùng bảo chưa cần xác
/// minh; kiểm lại khi kết nối Gmail thật (nếu sai, bộ lọc không tải thư nào và
/// bộ đếm "không đọc được" vẫn 0 — sửa đúng dòng này).
const mbSenderAddress = 'mbebanking@mbbank.com.vn';

/// MB Bank (M1: đã có bộ đọc `lib/src/import/mb/` và mẫu test đã che).
const mbBank = BankSource(
  id: 'mb',
  name: 'MB Bank',
  senders: {mbSenderAddress},
);

/// Mọi nguồn đã khai báo (gồm cả nguồn chưa hỗ trợ).
const declaredBankSources = <BankSource>[mbBank];

/// Danh sách địa chỉ gửi được phép đọc. Test thay bằng danh sách riêng.
class SenderAllowlist {
  const SenderAllowlist(this.sources);

  final List<BankSource> sources;

  /// Chỉ các nguồn đã hỗ trợ (AC-83).
  List<BankSource> get supported => [
    for (final s in sources)
      if (s.isSupported) s,
  ];

  /// Mọi địa chỉ được phép, viết thường.
  Set<String> get addresses => {
    for (final s in supported)
      for (final a in s.senders) a.trim().toLowerCase(),
  };

  bool get isEmpty => addresses.isEmpty;

  /// [address] có đúng là một địa chỉ được phép (không phải chuỗi con).
  bool allows(String? address) {
    if (address == null) return false;
    return addresses.contains(address.trim().toLowerCase());
  }

  /// Nguồn của [address], hoặc null.
  BankSource? sourceOf(String? address) {
    if (address == null) return null;
    final a = address.trim().toLowerCase();
    for (final s in supported) {
      if (s.senders.any((x) => x.trim().toLowerCase() == a)) return s;
    }
    return null;
  }
}

/// Danh sách của bản build.
const defaultSenderAllowlist = SenderAllowlist(declaredBankSources);
