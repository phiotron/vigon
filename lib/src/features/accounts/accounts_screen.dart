import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../entry/keypad.dart' show minorUnitsToInput;
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';

/// Danh sách tài khoản và số dư hiện tại (F-06).
class AccountsScreen extends ConsumerWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final balances =
        ref.watch(accountBalancesProvider).value ?? const <int, int>{};
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    Widget balance(Account a) => Text(
      money(context, currency, balances[a.id] ?? a.initialBalance),
      style: Theme.of(context).textTheme.titleMedium,
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
        padding: const EdgeInsets.only(bottom: 88),
        children: [
          for (final a in accounts)
            ListTile(
              leading: const Icon(Symbols.account_balance_wallet_rounded),
              title: Text(accountLabel(l, a)),
              subtitle: isLargeText(context) ? balance(a) : null,
              trailing: isLargeText(context) ? null : balance(a),
              onTap: () => showAccountEditor(context, account: a),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: l.addAccount,
        onPressed: () => showAccountEditor(context),
        child: const Icon(Symbols.add_rounded),
      ),
    );
  }
}

/// Thêm hoặc sửa tài khoản: tên và số dư ban đầu (AC-18).
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final a = widget.account;
    if (a != null && _name.text.isEmpty) {
      _name.text = accountLabel(AppLocalizations.of(context), a);
      final digits = currencyDecimalDigits(
        ref.read(currencyProvider).value ?? 'VND',
      );
      final abs = minorUnitsToInput(a.initialBalance.abs(), digits);
      _balance.text = a.initialBalance < 0 ? '-$abs' : abs;
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
    final text = _balance.text.trim().replaceAll(',', '.');
    final negative = text.startsWith('-');
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'VND',
    );
    final abs = text.isEmpty
        ? 0
        : evaluateToMinorUnits(
            negative ? text.substring(1) : text,
            decimalDigits: digits,
          );
    setState(() {
      _nameError = name.isEmpty ? l.nameRequired : null;
      _balanceError = abs == null ? l.invalidExpression : null;
    });
    if (_nameError != null || abs == null) return;
    final balance = negative ? -abs : abs;
    final repo = ref.read(accountRepositoryProvider);
    final a = widget.account;
    if (a == null) {
      await repo.add(name: name, initialBalance: balance);
    } else {
      await repo.edit(a.id, name: name, initialBalance: balance);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.account == null ? l.addAccount : l.editAccount,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              maxLength: 50,
              autofocus: widget.account == null,
              decoration: InputDecoration(
                labelText: l.name,
                errorText: _nameError,
              ),
            ),
            TextField(
              controller: _balance,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
              ],
              decoration: InputDecoration(
                labelText: l.initialBalance,
                errorText: _balanceError,
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(onPressed: _save, child: Text(l.save)),
            ),
          ],
        ),
      ),
    );
  }
}
