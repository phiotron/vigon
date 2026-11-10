import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../../ui/choice_segments.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/tokens.g.dart';

/// Mở bảng kéo "Giao diện & ngôn ngữ" (SCR-12/33, D-038). Hai hàng của nhóm
/// Cài đặt cùng gọi hàm này nên người dùng đổi được cả hai ở một chỗ.
Future<void> showAppearanceSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => const AppearanceSheet(),
    );

/// Nội dung bảng kéo: theme (3 lựa chọn) rồi ngôn ngữ (English / Tiếng Việt),
/// chọn là áp dụng ngay, nút Done chỉ để đóng. Tự theo dõi cài đặt nên khi
/// đổi ngôn ngữ, chữ trong bảng đổi luôn mà bảng vẫn mở (D-038).
class AppearanceSheet extends ConsumerWidget {
  const AppearanceSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final repo = ref.watch(settingsRepositoryProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeCode = ref.watch(localeCodeProvider).value;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.only(bottom: VgSpace.s4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SheetHeader(l.appearanceLanguage),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SheetLabel(l.theme),
                    const SizedBox(height: VgSpace.s2),
                    ChoiceSegments<ThemeMode>(
                      options: [
                        (ThemeMode.system, l.themeSystem),
                        (ThemeMode.light, l.themeLight),
                        (ThemeMode.dark, l.themeDark),
                      ],
                      selected: themeMode,
                      onChanged: repo.setThemeMode,
                    ),
                    const SizedBox(height: VgSpace.s6),
                    _SheetLabel(l.language),
                    const SizedBox(height: VgSpace.s2),
                    ChoiceSegments<String>(
                      options: const [('en', 'English'), ('vi', 'Tiếng Việt')],
                      selected: localeCode == 'vi' ? 'vi' : 'en',
                      onChanged: repo.setLocaleCode,
                    ),
                    const SizedBox(height: VgSpace.s6),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.done),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Nhãn nhỏ phía trên mỗi nút chọn trong bảng kéo.
class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: VgType.labelMd.copyWith(
        color: scheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
