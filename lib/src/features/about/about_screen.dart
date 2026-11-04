import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_info.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';

/// Màn Giới thiệu (AC-41, 9.1–9.2): tên, phiên bản, lời cam kết dữ liệu, chính
/// sách quyền riêng tư, kênh báo lỗi bảo mật, giấy phép nguồn mở. Mở trang web
/// và email bằng app khác của máy, nên Ví Gọn vẫn không cần quyền INTERNET
/// (AC-43).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value ?? '';
    final textTheme = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final hasPolicy = AppInfo.privacyPolicyUrl.isNotEmpty;

    // Không mở được (máy không có trình duyệt hay app email, 9.2): báo kèm
    // email để người dùng tự gửi.
    Future<void> open(Uri uri) async {
      bool ok;
      try {
        ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        ok = false;
      }
      if (!ok) showMessage(l.linkOpenFailed(AppInfo.contactEmail));
    }

    // Dòng `.vg-row` có icon đầu chữ phụ; dòng tắt thì chữ chính cũng phụ.
    Widget row({
      required IconData icon,
      required String title,
      String? subtitle,
      IconData? trailing,
      VoidCallback? onTap,
    }) {
      final enabled = onTap != null;
      return ListTile(
        enabled: enabled,
        leading: Icon(icon, size: 22, color: muted),
        title: Text(title, style: enabled ? null : TextStyle(color: muted)),
        subtitle: subtitle == null
            ? null
            : Text(subtitle, style: TextStyle(color: muted)),
        trailing: trailing == null ? null : Icon(trailing, color: muted),
        onTap: onTap,
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.about)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: VgSpace.s8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s6,
              VgSpace.s4,
              VgSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l.appTitle,
                    style: textTheme.titleLarge!.copyWith(
                      fontSize: 32,
                      height: 40 / 32,
                    ),
                  ),
                ),
                const SizedBox(height: VgSpace.s1),
                Text(
                  l.version(version),
                  style: textTheme.bodyMedium!.copyWith(color: muted),
                ),
                const SizedBox(height: VgSpace.s4),
                Text(l.aboutBody, style: textTheme.bodyLarge),
              ],
            ),
          ),
          const Divider(height: VgSpace.s2 + 1),
          row(
            icon: Symbols.policy_rounded,
            title: l.privacyPolicy,
            // Chưa có đường dẫn thì dòng tắt, ghi "Đang chuẩn bị trang web".
            subtitle: hasPolicy ? null : l.privacyPolicyPending,
            trailing: hasPolicy ? Symbols.open_in_new_rounded : null,
            onTap: hasPolicy
                ? () => open(Uri.parse(AppInfo.privacyPolicyUrl))
                : null,
          ),
          row(
            icon: Symbols.mail_rounded,
            title: l.reportSecurity,
            subtitle: l.contactEmail(AppInfo.contactEmail),
            trailing: Symbols.open_in_new_rounded,
            onTap: () => open(
              Uri(
                scheme: 'mailto',
                path: AppInfo.contactEmail,
                query: 'subject=${Uri.encodeComponent(l.securityEmailSubject)}',
              ),
            ),
          ),
          row(
            icon: Symbols.description_rounded,
            title: l.licenses,
            trailing: Symbols.chevron_right_rounded,
            // Trang giấy phép chuẩn của Flutter, gồm cả giấy phép OFL của font.
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
