/// Gấp chữ để so khớp không phân biệt hoa thường và dấu tiếng Việt (AC-48).
/// Ví dụ `Cà phê`, `ca phe` và `CÀ PHÊ` đều thành `ca phe`; `Đ`/`đ` thành `d`.
/// Thuần Dart, không cần thư viện ngoài.
String foldText(String input) {
  final lower = input.toLowerCase();
  final out = StringBuffer();
  for (final rune in lower.runes) {
    // Dấu rời (chữ gõ dạng tổ hợp NFD): bỏ.
    if (rune >= 0x0300 && rune <= 0x036F) continue;
    final ch = String.fromCharCode(rune);
    out.write(_foldMap[ch] ?? ch);
  }
  return out.toString();
}

const _groups = <String, String>{
  'a': 'àáạảãâầấậẩẫăằắặẳẵ',
  'e': 'èéẹẻẽêềếệểễ',
  'i': 'ìíịỉĩ',
  'o': 'òóọỏõôồốộổỗơờớợởỡ',
  'u': 'ùúụủũưừứựửữ',
  'y': 'ỳýỵỷỹ',
  'd': 'đ',
};

final _foldMap = <String, String>{
  for (final e in _groups.entries)
    for (final ch in e.value.split('')) ch: e.key,
};
