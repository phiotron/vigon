import 'package:flutter/widgets.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../ui/tokens.g.dart';

/// 31 icon chọn được cho danh mục, đúng thứ tự trong `design-system-guide.md`
/// mục Biểu tượng. Khóa là chữ lưu trong cơ sở dữ liệu (D-010).
const categoryIcons = <String, IconData>{
  'restaurant': Symbols.restaurant_rounded,
  'local_cafe': Symbols.local_cafe_rounded,
  'directions_bus': Symbols.directions_bus_rounded,
  'two_wheeler': Symbols.two_wheeler_rounded,
  'local_gas_station': Symbols.local_gas_station_rounded,
  'home': Symbols.home_rounded,
  'receipt_long': Symbols.receipt_long_rounded,
  'bolt': Symbols.bolt_rounded,
  'water_drop': Symbols.water_drop_rounded,
  'wifi': Symbols.wifi_rounded,
  'shopping_bag': Symbols.shopping_bag_rounded,
  'checkroom': Symbols.checkroom_rounded,
  'health_and_safety': Symbols.health_and_safety_rounded,
  'medication': Symbols.medication_rounded,
  'movie': Symbols.movie_rounded,
  'sports_esports': Symbols.sports_esports_rounded,
  'school': Symbols.school_rounded,
  'menu_book': Symbols.menu_book_rounded,
  'family_restroom': Symbols.family_restroom_rounded,
  'child_care': Symbols.child_care_rounded,
  'pets': Symbols.pets_rounded,
  'redeem': Symbols.redeem_rounded,
  'payments': Symbols.payments_rounded,
  'savings': Symbols.savings_rounded,
  'work': Symbols.work_rounded,
  'flight': Symbols.flight_rounded,
  'fitness_center': Symbols.fitness_center_rounded,
  'spa': Symbols.spa_rounded,
  'volunteer_activism': Symbols.volunteer_activism_rounded,
  'build': Symbols.build_rounded,
  'more_horiz': Symbols.more_horiz_rounded,
};

/// Khóa của bộ icon trước PLAN-001, không còn trong bảng chọn nhưng vẫn có thể
/// nằm trong cơ sở dữ liệu hoặc file sao lưu cũ; vẫn phải hiện được icon.
const legacyCategoryIcons = <String, IconData>{
  'local_grocery_store': Symbols.local_grocery_store_rounded,
  'phone_android': Symbols.phone_android_rounded,
  'medical_services': Symbols.medical_services_rounded,
  'card_giftcard': Symbols.card_giftcard_rounded,
  'trending_up': Symbols.trending_up_rounded,
};

IconData iconFor(String key) =>
    categoryIcons[key] ?? legacyCategoryIcons[key] ?? Symbols.category_rounded;

/// Bảng 16 màu danh mục cat-01 … cat-16 (ARGB lưu trong cơ sở dữ liệu). Màu
/// đậm để icon trắng đạt tương phản tối thiểu 3:1 (AC-40).
final categoryColors = <int>[for (final c in vgCategoryColors) c.toARGB32()];
