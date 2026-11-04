import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_info.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';

/// Màn Giới thiệu: phiên bản, chính sách quyền riêng tư, kênh báo lỗi bảo mật,
/// giấy phép nguồn mở (AC-41). Mở trang web và email bằng app khác của máy,
/// nên Ví Gọn vẫn không cần quyền INTERNET (AC-43).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';
    final textTheme = Theme.of(context).textTheme;

    Future<void> open(Uri uri, String fallback) async {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) showMessage(l.linkOpenFailed(fallback));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.appTitle, style: textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(l.version(version), style: textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text(l.aboutBody, style: textTheme.bodyLarge),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Symbols.privacy_tip_rounded),
            title: Text(l.privacyPolicy),
            subtitle: AppInfo.privacyPolicyUrl.isEmpty
                ? Text(l.privacyPolicyPending)
                : null,
            enabled: AppInfo.privacyPolicyUrl.isNotEmpty,
            onTap: () => open(
              Uri.parse(AppInfo.privacyPolicyUrl),
              AppInfo.privacyPolicyUrl,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.security_rounded),
            title: Text(l.reportSecurity),
            subtitle: Text(l.contactEmail(AppInfo.contactEmail)),
            onTap: () => open(
              Uri(
                scheme: 'mailto',
                path: AppInfo.contactEmail,
                query: 'subject=${Uri.encodeComponent(l.securityEmailSubject)}',
              ),
              AppInfo.contactEmail,
            ),
          ),
          ListTile(
            leading: const Icon(Symbols.description_rounded),
            title: Text(l.licenses),
            onTap: () => showLicensePage(
              context: context,
              applicationName: l.appTitle,
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
