import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_info.dart';
import '../../providers.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import 'legal_actions.dart';

/// Nhóm "Giới thiệu" cuối màn Cài đặt (AC-41, D-039): một thẻ như A001, gồm
/// phiên bản, chính sách quyền riêng tư, điều khoản sử dụng, giấy phép mã
/// nguồn mở, đánh giá (khi có cửa hàng), gửi góp ý và báo lỗi bảo mật.
class AboutSection extends ConsumerWidget {
  const AboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';
    final localeName = ref.watch(localeCodeProvider).value ?? '';
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsGroupTitle(l.about),
        SettingsCard(
          children: [
            SettingsNavRow(
              icon: Symbols.info_rounded,
              title: l.versionLabel,
              value: version,
              valueInline: true,
              chevron: false,
            ),
            SettingsNavRow(
              icon: Symbols.policy_rounded,
              title: l.privacyPolicy,
              trailing: Icon(
                Symbols.open_in_new_rounded,
                color: scheme.onSurfaceVariant,
              ),
              chevron: false,
              onTap: () => LegalActions.openPrivacyPolicy(context, localeName),
            ),
            SettingsNavRow(
              icon: Symbols.description_rounded,
              title: l.terms,
              trailing: Icon(
                Symbols.open_in_new_rounded,
                color: scheme.onSurfaceVariant,
              ),
              chevron: false,
              onTap: () => LegalActions.openTerms(context, localeName),
            ),
            SettingsNavRow(
              icon: Symbols.article_rounded,
              title: l.licenses,
              onTap: () => LegalActions.openLicenses(context, version),
            ),
            if (LegalActions.canRate)
              SettingsNavRow(
                icon: Symbols.star_rounded,
                title: l.rateApp,
                trailing: Icon(
                  Symbols.open_in_new_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                chevron: false,
                onTap: () => LegalActions.rateApp(context),
              ),
            SettingsNavRow(
              icon: Symbols.mail_rounded,
              title: l.feedback,
              trailing: Icon(
                Symbols.open_in_new_rounded,
                color: scheme.onSurfaceVariant,
              ),
              chevron: false,
              onTap: () => LegalActions.sendFeedback(context, version),
            ),
            SettingsNavRow(
              icon: Symbols.security_rounded,
              title: l.reportSecurity,
              value: l.contactEmail(AppInfo.contactEmail),
              trailing: Icon(
                Symbols.open_in_new_rounded,
                color: scheme.onSurfaceVariant,
              ),
              chevron: false,
              onTap: () => LegalActions.reportSecurity(context),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s8,
            VgSpace.s2,
            VgSpace.s8,
            0,
          ),
          child: Text(
            l.aboutBody,
            style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
