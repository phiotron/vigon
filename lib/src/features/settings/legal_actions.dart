import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../app_info.dart';
import '../../ui/messenger.dart';
import 'legal_screen.dart';

/// Hành động sau các hàng của nhóm Giới thiệu (AC-41, D-039).
abstract final class LegalActions {
  static Future<bool> _open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Mở trang công khai [url]; không mở được (offline, không có trình duyệt)
  /// thì đọc bản nhúng trong app.
  static Future<void> openLegal(
    BuildContext context,
    LegalDoc doc, {
    required String url,
  }) async {
    if (url.isNotEmpty && await _open(Uri.parse(url))) return;
    if (context.mounted)
      await Navigator.of(context).push(LegalScreen.route(doc));
  }

  static Future<void> openPrivacyPolicy(
    BuildContext context,
    String localeName,
  ) => openLegal(
    context,
    LegalDoc.privacy,
    url: AppInfo.privacyPolicyUrl(localeName),
  );

  static Future<void> openTerms(BuildContext context, String localeName) =>
      openLegal(context, LegalDoc.terms, url: AppInfo.termsUrl(localeName));

  /// Trang giấy phép chuẩn của Flutter (gồm giấy phép phông chữ và icon).
  static void openLicenses(BuildContext context, String version) {
    final l = AppLocalizations.of(context);
    showLicensePage(
      context: context,
      applicationName: l.appTitle,
      applicationVersion: version,
    );
  }

  /// Hàng "Đánh giá" chỉ hiện khi có chỗ để đi: Android luôn có, iOS chờ có
  /// App Store id (không để nút chết).
  static bool get canRate =>
      defaultTargetPlatform == TargetPlatform.android ||
      (defaultTargetPlatform == TargetPlatform.iOS &&
          AppInfo.appStoreId != null);

  /// Mở trang cửa hàng: Play (`market://` rồi HTTPS); iOS mở hộp đánh giá
  /// khi đã có App Store id.
  static Future<void> rateApp(BuildContext context) async {
    final AppLocalizations l = AppLocalizations.of(context);
    final candidates = defaultTargetPlatform == TargetPlatform.iOS
        ? [
            Uri.parse(
              'https://apps.apple.com/app/id${AppInfo.appStoreId}?action=write-review',
            ),
          ]
        : [
            Uri.parse('market://details?id=${AppInfo.androidPackage}'),
            Uri.parse(
              'https://play.google.com/store/apps/details?id=${AppInfo.androidPackage}',
            ),
          ];
    for (final uri in candidates) {
      if (await _open(uri)) return;
    }
    if (context.mounted) showMessage(l.linkOpenFailed(AppInfo.contactEmail));
  }

  /// `mailto:` gửi góp ý, tiêu đề có phiên bản app.
  static Future<void> sendFeedback(BuildContext context, String version) async {
    final l = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.contactEmail,
      query: 'subject=${Uri.encodeComponent(l.feedbackSubject(version))}',
    );
    if (!await _open(uri) && context.mounted) {
      showMessage(l.linkOpenFailed(AppInfo.contactEmail));
    }
  }

  /// `mailto:` báo lỗi bảo mật (COMPLIANCE S-05: kênh nêu đích danh trong app).
  static Future<void> reportSecurity(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: AppInfo.contactEmail,
      query: 'subject=${Uri.encodeComponent(l.securityEmailSubject)}',
    );
    if (!await _open(uri) && context.mounted) {
      showMessage(l.linkOpenFailed(AppInfo.contactEmail));
    }
  }
}
