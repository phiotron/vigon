import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/money_lines.dart';
import 'account_manage.dart';
import '../categories/sheet_footer.dart';
import '../../ui/tokens.g.dart';
import '../settings/budget_dialog.dart' show currencySymbol;
import '../settings/currency_picker.dart';

/// Icon đầu dòng tài khoản: tiền mặt mặc định là tờ tiền, còn lại là ví.
IconData accountIcon(Account a) => a.nameKey == 'cash'
    ? Symbols.payments_rounded
    : Symbols.account_balance_wallet_rounded;

/// Danh sách tài khoản và số dư hiện tại (F-06), theo 6.4: số dư bên phải,
/// ⇄ khi có từ 2 tài khoản, nút nổi +.
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final balances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    final own =
        ref.watch(accountOwnBalancesProvider).value ?? const <int, int>{};
    final large = isLargeText(context);
    // Số dư: Tiền tệ chính to ở trên, số theo tiền tệ tài khoản nhỏ ở dưới
    // (D-042). Cả hai tính thẳng từ số gốc, không quy ngược (AC-148).
    Widget balance(Account a) => MoneyLines(
      amount: own[a.id] ?? a.initialBalanceOriginal ?? a.initialBalance,
      currency: a.currency,
      primaryAmount: balances[a.id],
      style: VgType.bodyMd.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      secondaryStyle: VgType.bodySm,
      crossAxisAlignment: CrossAxisAlignment.end,
      textAlign: TextAlign.end,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.accounts),
        actions: [
          if (accounts.length > 1)
            IconButton(
              icon: const Icon(Symbols.swap_horiz_rounded),
              tooltip: l.transfer,
              onPressed: () => context.push('/transfer'),
            ),
        ],
      ),
      body: ListView(
        // Đệm đáy để nút + không che dòng cuối.
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          for (final a in accounts)
            ListTile(
              leading: SizedBox(
                width: 40,
                child: Center(child: Icon(accountIcon(a))),
              ),
              // Tên dài thì cắt một dòng; số dư không bao giờ cắt (SCR-17).
              title: Text(
                accountLabel(l, a),
                maxLines: large ? null : 1,
                overflow: large ? null : TextOverflow.ellipsis,
              ),
              subtitle: large ? balance(a) : null,
              trailing: large ? null : balance(a),
              onTap: () => showAccountEditor(context, account: a),
            ),
          const ArchivedAccountsSection(),
        ],
      ),
      // SCR-17: nút nổi có chữ "Thêm tài khoản".
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showAccountEditor(context),
        icon: const Icon(Symbols.add_rounded),
        label: Text(l.addAccount, style: VgType.labelLg),
      ),
    );
  }
}

/// Thêm hoặc sửa tài khoản: tên và số dư ban đầu (AC-18), bảng kéo 6.5.
Future<void> showAccountEditor(BuildContext context, {Account? account}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _AccountEditor(account: account),
      ),
    );

class _AccountEditor extends ConsumerStatefulWidget {
  const _AccountEditor({this.account});

  final Account? account;

  @override
  ConsumerState<_AccountEditor> createState() => _AccountEditorState();
}

class _AccountEditorState extends ConsumerState<_AccountEditor> {
  final _name = TextEditingController();
  final _balance = TextEditingController();
  String? _nameError;
  String? _balanceError;
  String? _currency;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = widget.account;
    if (a != null && _name.text.isEmpty) {
      _name.text = accountLabel(AppLocalizations.of(context), a);
      _currency ??= a.currency;
      final digits = currencyDecimalDigits(a.currency);
      final original = a.initialBalanceOriginal ?? a.initialBalance;
      final abs = amountInput(context, original.abs(), digits);
      _balance.text = original < 0 ? '-$abs' : abs;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _balance.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    final text = _balance.text.trim();
    final negative = text.startsWith('-');
    final currency = _currency ?? ref.read(currencyProvider).value ?? 'USD';
    final digits = currencyDecimalDigits(currency);
    final abs = text.isEmpty
        ? 0
        : parseAmountField(
            context,
            negative ? text.substring(1) : text,
            digits,
          );
    setState(() {
      _nameError = name.isEmpty ? l.nameRequired : null;
      _balanceError = abs == null ? l.invalidExpression : null;
    });
    if (_nameError != null || abs == null) return;
    final original = negative ? -abs : abs;
    final service = await ref.read(currencyServiceProvider.future);
    final balance = service.toPrimary(original, currency);
    if (balance == null) {
      if (mounted) {
        setState(
          () => _balanceError = l.rateMissing(currency, service.primary),
        );
      }
      return;
    }
    final repo = ref.read(accountRepositoryProvider);
    final a = widget.account;
    if (a == null) {
      await repo.add(
        name: name,
        initialBalance: balance,
        initialBalanceOriginal: original,
        currency: currency,
      );
    } else {
      await repo.edit(
        a.id,
        name: name,
        initialBalance: balance,
        initialBalanceOriginal: original,
        currency: currency,
      );
    }
    if (mounted) Navigator.pop(context);
  }

  /// Đổi tiền tệ tài khoản: giữ nguyên số gốc người dùng đã nhập, chỉ đổi tiền
  /// tệ hiển thị/quy đổi (D-037).
  Future<void> _pickCurrency() async {
    final current = _currency ?? ref.read(currencyProvider).value ?? 'USD';
    final picked = await showCurrencyPicker(context, current);
    if (picked == null || picked == current || !mounted) return;
    final oldDigits = currencyDecimalDigits(current);
    final newDigits = currencyDecimalDigits(picked);
    final text = _balance.text.trim();
    final negative = text.startsWith('-');
    final parsed = text.isEmpty
        ? 0
        : parseAmountField(
            context,
            negative ? text.substring(1) : text,
            oldDigits,
          );
    setState(() {
      _currency = picked;
      if (parsed != null && text.isNotEmpty) {
        final abs = amountInput(context, parsed, newDigits);
        _balance.text = negative ? '-$abs' : abs;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = _currency ?? ref.watch(currencyProvider).value ?? 'USD';
    final account = widget.account;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SheetHeader(account == null ? l.addAccount : l.editAccount),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s2,
                      VgSpace.s4,
                      0,
                    ),
                    child: TextField(
                      controller: _name,
                      maxLength: 50,
                      autofocus: account == null,
                      decoration: InputDecoration(
                        labelText: l.name,
                        errorText: _nameError,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s2,
                      VgSpace.s4,
                      0,
                    ),
                    child: InkWell(
                      onTap: _pickCurrency,
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(labelText: l.currency),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                currencyCodeLabel(currency),
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                            ),
                            const Icon(Symbols.arrow_drop_down_rounded),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      VgSpace.s4,
                      VgSpace.s2,
                      VgSpace.s4,
                      0,
                    ),
                    child: TextField(
                      controller: _balance,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
                      ],
                      style: const TextStyle(
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: InputDecoration(
                        labelText: l.initialBalance,
                        suffixText: currencySymbol(currency),
                        helperText: l.initialBalanceHelper,
                        helperMaxLines: 3,
                        errorText: _balanceError,
                        errorMaxLines: 3,
                      ),
                    ),
                  ),
                  // Vùng quản lý chỉ có khi sửa (SCR-18).
                  if (account != null) AccountRemoveSection(account: account),
                  const SizedBox(height: VgSpace.s2),
                ],
              ),
            ),
          ),
          // Lưu: nút lớn cả hàng, ghim đáy, trên bàn phím (SCR-18).
          SheetFooter(
            border: false,
            children: [
              FilledButton(
                style: sheetFilledButtonStyle(),
                onPressed: _save,
                child: Text(l.save),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
