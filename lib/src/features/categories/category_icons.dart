import 'package:flutter/material.dart';

/// Bộ icon chọn được cho danh mục. Khóa là chữ lưu trong cơ sở dữ liệu.
const categoryIcons = <String, IconData>{
  'restaurant': Icons.restaurant,
  'local_cafe': Icons.local_cafe,
  'local_grocery_store': Icons.local_grocery_store,
  'directions_bus': Icons.directions_bus,
  'local_gas_station': Icons.local_gas_station,
  'two_wheeler': Icons.two_wheeler,
  'home': Icons.home,
  'receipt_long': Icons.receipt_long,
  'bolt': Icons.bolt,
  'wifi': Icons.wifi,
  'phone_android': Icons.phone_android,
  'shopping_bag': Icons.shopping_bag,
  'checkroom': Icons.checkroom,
  'medical_services': Icons.medical_services,
  'fitness_center': Icons.fitness_center,
  'movie': Icons.movie,
  'sports_esports': Icons.sports_esports,
  'flight': Icons.flight,
  'school': Icons.school,
  'menu_book': Icons.menu_book,
  'family_restroom': Icons.family_restroom,
  'child_care': Icons.child_care,
  'pets': Icons.pets,
  'card_giftcard': Icons.card_giftcard,
  'volunteer_activism': Icons.volunteer_activism,
  'payments': Icons.payments,
  'redeem': Icons.redeem,
  'savings': Icons.savings,
  'trending_up': Icons.trending_up,
  'work': Icons.work,
  'more_horiz': Icons.more_horiz,
};

IconData iconFor(String key) => categoryIcons[key] ?? Icons.category;

/// Bảng màu danh mục. Màu đậm để icon trắng đạt tương phản tối thiểu 3:1 (AC-40).
const categoryColors = <int>[
  0xFFC62828, 0xFFAD1457, 0xFF6A1B9A, 0xFF4527A0, //
  0xFF283593, 0xFF1565C0, 0xFF0277BD, 0xFF00838F, //
  0xFF00695C, 0xFF2E7D32, 0xFF558B2F, 0xFFE65100, //
  0xFFBF360C, 0xFF5D4037, 0xFF455A64, 0xFF616161, //
];
