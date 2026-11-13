import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../l10n/app_localizations.dart';
import 'theme.dart';

/// Năm tab gốc của app. Mỗi tab là một màn độc lập; các màn phụ (nhập khoản,
/// lịch, danh mục…) vẫn mở chồng lên và không có thanh tab.
enum MainTab {
  home('/', Symbols.home_rounded),
  entries('/entries', Symbols.receipt_long_rounded),
  overview('/overview', Symbols.dashboard_rounded),
  stats('/stats', Symbols.bar_chart_rounded),
  settings('/settings', Symbols.settings_rounded);

  const MainTab(this.location, this.icon);

  /// Đường dẫn gốc của tab, dùng với `context.go`.
  final String location;

  final IconData icon;

  String label(AppLocalizations l) => switch (this) {
    MainTab.home => l.homeTab,
    MainTab.entries => l.entries,
    MainTab.overview => l.overviewTitle,
    MainTab.stats => l.statsTitle,
    MainTab.settings => l.settings,
  };
}

/// Thanh điều hướng dưới, 5 tab (màn chính · các khoản · tổng quan · thống kê ·
/// cài đặt). Chạm tab dùng `go` để mỗi tab là một gốc, không chồng màn.
///
/// Nhãn 5 tab tiếng Việt vừa đủ chỗ ở cỡ chữ chuẩn; chữ lớn hơn một chút thì
/// chỉ hiện nhãn tab đang mở, từ 130% trở lên ẩn hẳn nhãn (icon vẫn đủ nghĩa
/// nhờ tooltip và nhãn đọc màn hình) — tránh nhãn tràn nhau ở màn 360 dp
/// (AC-38).
class MainTabBar extends StatelessWidget {
  const MainTabBar({required this.current, super.key});

  final MainTab current;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = context.vg;
    final scaled = MediaQuery.textScalerOf(context).scale(10);
    final labelBehavior = scaled >= 13
        ? NavigationDestinationLabelBehavior.alwaysHide
        : scaled > 10
        ? NavigationDestinationLabelBehavior.onlyShowSelected
        : NavigationDestinationLabelBehavior.alwaysShow;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: p.outlineVariant)),
      ),
      child: NavigationBar(
        selectedIndex: current.index,
        backgroundColor: p.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelBehavior: labelBehavior,
        onDestinationSelected: (index) {
          final tab = MainTab.values[index];
          // Tab đang mở: không dựng lại màn (giữ vị trí cuộn, ô tìm…).
          if (tab == current) return;
          context.go(tab.location);
        },
        destinations: [
          for (final tab in MainTab.values)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.icon),
              label: tab.label(l),
              // Tooltip trùng nhãn: trên máy chỉ hiện khi nhấn giữ, và là thứ
              // các test cũ dùng để mở Cài đặt/Các khoản.
              tooltip: tab.label(l),
            ),
        ],
      ),
    );
  }
}
