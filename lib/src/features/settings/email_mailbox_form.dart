import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../import/mail/imap_gateway.dart';
import '../../import/mail/mail_provider.dart';
import '../../import/mail/mail_providers.dart';
import '../../import/mail/mailbox_service.dart';
import '../../import/mail/mailbox_store.dart';
import '../../ui/choice_segments.dart';
import '../../ui/fields.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/tokens.g.dart';
import 'email_import_screen.dart';

/// Màn "Thêm hộp thư" (AC-78): chọn Gmail / Yahoo / iCloud, hướng dẫn từng
/// bước tạo mật khẩu ứng dụng + nút mở trang của nhà cung cấp bằng trình duyệt
/// ngoài app, địa chỉ, mật khẩu ứng dụng; "Kết nối" đăng nhập thử ngay và báo
/// "Đã kết nối" hoặc lỗi rõ. Người dùng TỰ tạo và tự nhập mật khẩu.
///
/// Có [mailboxId]: nhập lại mật khẩu cho hộp thư đã dừng kiểm vì sai mật khẩu
/// (AC-82) — nhà cung cấp và địa chỉ cố định.
class EmailMailboxForm extends ConsumerStatefulWidget {
  const EmailMailboxForm({super.key, this.mailboxId});

  final String? mailboxId;

  @override
  ConsumerState<EmailMailboxForm> createState() => _EmailMailboxFormState();
}

class _EmailMailboxFormState extends ConsumerState<EmailMailboxForm> {
  final _address = TextEditingController();
  final _password = TextEditingController();
  var _provider = MailProvider.gmail;
  var _busy = false;
  String? _addressError;
  String? _passwordError;
  String? _error;

  Mailbox? get _existing {
    final id = widget.mailboxId;
    if (id == null) return null;
    return ref
        .read(mailboxesProvider)
        .value
        ?.where((b) => b.id == id)
        .firstOrNull;
  }

  @override
  void dispose() {
    _address.dispose();
    // Không giữ mật khẩu trong bộ nhớ lâu hơn cần.
    _password
      ..clear()
      ..dispose();
    super.dispose();
  }

  Future<void> _openPasswordPage(MailProvider provider) async {
    try {
      await launchUrl(
        Uri.parse(provider.appPasswordUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {}
  }

  Future<void> _submit() async {
    final l = AppLocalizations.of(context);
    final existing = _existing;
    final address = _address.text.trim();
    final password = _password.text.trim();
    setState(() {
      _error = null;
      _addressError = existing == null && !isPlausibleEmail(address)
          ? l.emailAddressInvalid
          : null;
      _passwordError = password.isEmpty ? l.emailAppPasswordEmpty : null;
    });
    if (_addressError != null || _passwordError != null) return;
    setState(() => _busy = true);
    final service = ref.read(mailboxServiceProvider);
    try {
      if (existing == null) {
        await service.add(
          provider: _provider,
          address: address,
          password: password,
        );
      } else {
        await service.updatePassword(existing.id, password);
      }
      ref.invalidate(mailboxesProvider);
      showMessage(l.emailConnected);
      if (mounted) Navigator.of(context).pop();
    } on MailException catch (e) {
      if (mounted) setState(() => _error = mailErrorText(l, e.kind));
    } on MailboxAddException catch (e) {
      if (mounted) {
        setState(
          () => _error = switch (e.error) {
            MailboxAddError.duplicate => l.emailDuplicate,
            MailboxAddError.limit => l.emailMailboxLimit,
            MailboxAddError.invalidAddress => l.emailAddressInvalid,
          },
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = l.emailErrorServer);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<String> _steps(AppLocalizations l, MailProvider p) => switch (p) {
    MailProvider.gmail => [
      l.emailStepsGmail1,
      l.emailStepsGmail2,
      l.emailStepsGmail3,
    ],
    MailProvider.yahoo => [
      l.emailStepsYahoo1,
      l.emailStepsYahoo2,
      l.emailStepsYahoo3,
    ],
    MailProvider.icloud => [
      l.emailStepsIcloud1,
      l.emailStepsIcloud2,
      l.emailStepsIcloud3,
    ],
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    // Theo dõi để màn nhập lại mật khẩu có dữ liệu khi mở thẳng đường dẫn.
    ref.watch(mailboxesProvider);
    final existing = _existing;
    final provider = existing?.provider ?? _provider;
    final steps = _steps(l, provider);
    const gutter = EdgeInsets.symmetric(horizontal: VgSpace.s4);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          existing == null ? l.emailAddMailbox : l.emailReenterPassword,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: VgSpace.s8),
        children: [
          if (existing == null) ...[
            SettingsGroupTitle(l.emailProvider, first: true),
            SettingsCard(
              children: [
                SettingsSegmentRow(
                  segments: ChoiceSegments<MailProvider>(
                    options: [
                      for (final p in MailProvider.values) (p, p.label),
                    ],
                    selected: _provider,
                    onChanged: _busy
                        ? (_) {}
                        : (p) => setState(() {
                            _provider = p;
                            _error = null;
                          }),
                  ),
                ),
              ],
            ),
          ] else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s4,
                VgSpace.s4,
                0,
              ),
              child: Text(
                '${existing.address} · ${existing.provider.label}',
                style: VgType.titleSm,
              ),
            ),
          SettingsGroupTitle(l.emailStepsTitle),
          Padding(
            padding: gutter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, step) in steps.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: VgSpace.s2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: VgSpace.s6,
                          child: Text(
                            '${i + 1}.',
                            style: VgType.bodyMd.copyWith(
                              color: scheme.primary,
                            ),
                          ),
                        ),
                        Expanded(child: Text(step, style: VgType.bodyMd)),
                      ],
                    ),
                  ),
                const SizedBox(height: VgSpace.s2),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(VgSize.tapMin),
                  ),
                  icon: const Icon(Symbols.open_in_new_rounded),
                  label: Text(l.emailOpenPasswordPage),
                  onPressed: () => _openPasswordPage(provider),
                ),
                const SizedBox(height: VgSpace.s6),
                if (existing == null) ...[
                  TextField(
                    controller: _address,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: InputDecoration(
                      labelText: l.emailAddress,
                      errorText: _addressError,
                    ),
                  ),
                  const SizedBox(height: VgSpace.s4),
                ],
                PasswordField(
                  controller: _password,
                  enabled: !_busy,
                  label: l.emailAppPassword,
                  helperText: l.emailAppPasswordHelper,
                  errorText: _passwordError,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _busy ? null : _submit(),
                ),
                if (_error != null) ...[
                  const SizedBox(height: VgSpace.s4),
                  SettingsStatusLine(
                    status: SettingsStatus.error,
                    text: _error!,
                  ),
                ],
                const SizedBox(height: VgSpace.s6),
                FilledButton(
                  style: BusyButtonLabel.filledStyle(context, busy: _busy)
                      .merge(
                        FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(VgSize.tapMin),
                        ),
                      ),
                  onPressed: _busy ? null : _submit,
                  child: BusyButtonLabel(
                    busy: _busy,
                    icon: Symbols.link_rounded,
                    label: existing == null
                        ? l.emailConnect
                        : l.emailSaveReenter,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
