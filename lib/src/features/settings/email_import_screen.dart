import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../import/mail/imap_gateway.dart';
import '../../import/mail/mail_provider.dart';
import '../../import/mail/mail_providers.dart';
import '../../import/mail/mailbox_service.dart';
import '../../import/mail/mailbox_store.dart';
import '../../ui/confirm_dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import 'settings_lead.dart';
import '../../ui/status.dart';
import '../../ui/theme.dart';

/// Đường dẫn của màn hộp thư và màn thêm hộp thư.
const emailImportRoute = '/email-import';
const emailAddMailboxRoute = '/email-import/add';

/// Câu báo của một loại lỗi hộp thư (AC-78).
String mailErrorText(AppLocalizations l, MailErrorKind kind) => switch (kind) {
  MailErrorKind.badCredentials => l.emailErrorCredentials,
  MailErrorKind.imapDisabled => l.emailErrorImapDisabled,
  MailErrorKind.noNetwork => l.emailErrorNetwork,
  MailErrorKind.secureConnection => l.emailErrorSecure,
  MailErrorKind.server => l.emailErrorServer,
};

/// Dòng "Nhập từ email ngân hàng" trong nhóm "Nhập từ email" của Cài đặt
/// (AC-78): mở màn hộp thư, giá trị là số hộp thư. Nhóm và thẻ do màn Cài đặt
/// dựng, để dòng "Khoản chờ chọn danh mục" nằm chung một thẻ.
class EmailImportRow extends ConsumerWidget {
  const EmailImportRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final count = ref.watch(mailboxesProvider).value?.length ?? 0;
    return SettingsNavRow(
      icon: Symbols.mail_rounded,
      title: l.emailImport,
      value: count == 0
          ? l.emailImportNoMailbox
          : l.emailImportMailboxCount(count),
      onTap: () => context.push(emailImportRoute),
    );
  }
}

/// Màn "Nhập từ email ngân hàng" (F-28): lần đầu là màn giải thích (AC-78);
/// sau đó là danh sách hộp thư với trạng thái, lỗi, bộ đếm email không đọc
/// được (AC-82, AC-85), nút nhập lại mật khẩu, xoá hộp thư; kéo để kiểm ngay.
class EmailImportScreen extends ConsumerWidget {
  const EmailImportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final intro = ref.watch(mailIntroSeenProvider);
    final boxes = ref.watch(mailboxesProvider);
    final Widget body;
    if (!intro.hasValue || !boxes.hasValue) {
      body = const SizedBox.shrink();
    } else if (!intro.value! && boxes.value!.isEmpty) {
      body = const _Intro();
    } else {
      body = _MailboxList(boxes: boxes.value!);
    }
    return Scaffold(
      appBar: AppBar(title: Text(l.emailImport)),
      body: body,
    );
  }
}

/// Màn giải thích trước khi thêm hộp thư (AC-78).
class _Intro extends ConsumerWidget {
  const _Intro();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final points = <(IconData, String)>[
      (Symbols.mark_email_read_rounded, l.emailIntroRead),
      (Symbols.smartphone_rounded, l.emailIntroLocal),
      (Symbols.edit_off_rounded, l.emailIntroReadOnly),
      (Symbols.key_rounded, l.emailIntroAppPassword),
      (Symbols.account_balance_rounded, l.emailIntroBanks),
      if (useIosCopy) (Symbols.schedule_rounded, l.emailIntroIos),
    ];
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        VgSpace.s4,
        VgSpace.s6,
        VgSpace.s4,
        VgSpace.s8,
      ),
      children: [
        Semantics(
          header: true,
          child: Text(
            l.emailIntroTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: VgSpace.s4),
        for (final (icon, text) in points)
          Padding(
            padding: const EdgeInsets.only(bottom: VgSpace.s3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, size: 22, color: scheme.primary),
                ),
                const SizedBox(width: VgSpace.s3),
                Expanded(child: Text(text, style: VgType.bodyMd)),
              ],
            ),
          ),
        const SizedBox(height: VgSpace.s4),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(VgSize.tapMin),
          ),
          icon: const Icon(Symbols.add_rounded),
          label: Text(l.emailAddMailbox),
          onPressed: () async {
            await ref.read(mailboxServiceProvider).setIntroSeen();
            ref.invalidate(mailIntroSeenProvider);
            if (context.mounted) await context.push(emailAddMailboxRoute);
          },
        ),
      ],
    );
  }
}

class _MailboxList extends ConsumerWidget {
  const _MailboxList({required this.boxes});

  final List<Mailbox> boxes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final full = boxes.length >= maxMailboxes;
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(mailboxServiceProvider)
            .checkAll(MailCheckTrigger.manual);
        ref.invalidate(mailboxesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: VgSpace.s8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s8,
              VgSpace.s4,
              VgSpace.s8,
              VgSpace.s2,
            ),
            child: Text(
              useIosCopy ? l.emailScheduleIos : l.emailScheduleAndroid,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          for (final box in boxes) ...[
            _MailboxCard(box: box),
            const SizedBox(height: SettingsCard.gap),
          ],
          if (full)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: VgSpace.s8,
                vertical: VgSpace.s2,
              ),
              child: Text(
                l.emailMailboxLimit,
                style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
              ),
            )
          else
            SettingsCard(
              children: [
                SettingsNavRow(
                  icon: Symbols.add_rounded,
                  title: l.emailAddMailbox,
                  onTap: () => context.push(emailAddMailboxRoute),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _MailboxCard extends ConsumerWidget {
  const _MailboxCard({required this.box});

  final Mailbox box;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String when(DateTime d) =>
        '${DateFormat.MMMd(locale).format(d)}, ${DateFormat.Hm(locale).format(d)}';
    final last = box.lastCheckAt;
    final error = box.lastError;
    final (status, text) = error == null
        ? (
            SettingsStatus.ok,
            last == null ? l.emailConnected : l.emailLastCheck(when(last)),
          )
        : (
            SettingsStatus.error,
            last == null
                ? mailErrorText(l, error)
                : l.emailErrorAt(when(last), mailErrorText(l, error)),
          );

    Future<void> remove() async {
      final ok = await showConfirmDialog(
        context,
        icon: Symbols.delete_rounded,
        title: l.emailRemoveTitle,
        body: l.emailRemoveBody(box.address),
        action: l.emailRemoveMailbox,
        style: ConfirmStyle.danger,
      );
      if (!ok) return;
      await ref.read(mailboxServiceProvider).remove(box.id);
      ref.invalidate(mailboxesProvider);
      showMessage(l.emailRemoved);
    }

    return SettingsCard(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            VgSpace.s4,
            VgSpace.s3,
            VgSpace.s4,
            VgSpace.s3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      Symbols.mail_rounded,
                      size: 22,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: VgSpace.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(box.address, style: VgType.titleSm),
                        Text(
                          box.provider.label,
                          style: VgType.bodySm.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: VgSpace.s3),
              // Chip trạng thái (mockup v4 SCR-44 connected).
              StatusChip(
                label: text,
                icon: status == SettingsStatus.ok
                    ? Symbols.check_circle_rounded
                    : Symbols.error_rounded,
                tone: status == SettingsStatus.ok
                    ? StatusTone.ok
                    : StatusTone.err,
              ),
              if (box.needsPassword) ...[
                const SizedBox(height: VgSpace.s2),
                Text(
                  l.emailPaused,
                  style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (box.unreadable > 0) ...[
                const SizedBox(height: VgSpace.s2),
                // Cảnh báo màu `warning` có icon (mockup v4).
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Symbols.warning_rounded,
                        size: 18,
                        color: context.vg.warning,
                      ),
                    ),
                    const SizedBox(width: VgSpace.s2),
                    Expanded(
                      child: Text(
                        l.emailUnreadable(box.unreadable),
                        style: VgType.bodySm.copyWith(
                          color: context.vg.warning,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              ButtonPair(
                children: [
                  if (box.needsPassword)
                    FilledButton.tonal(
                      onPressed: () =>
                          context.push('$emailAddMailboxRoute?id=${box.id}'),
                      child: Text(l.emailReenterPassword),
                    ),
                  OutlinedButton(
                    onPressed: remove,
                    child: Text(l.emailRemoveMailbox),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
