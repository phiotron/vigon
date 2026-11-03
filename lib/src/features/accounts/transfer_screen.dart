import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../entry/keypad.dart';

/// Chuyển tiền giữa hai tài khoản (AC-19); sửa hoặc xóa lần chuyển có sẵn.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.entryId});

  final int? entryId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  Entry? _original;
  int? _from;
  int? _to;
  String _expression = '';
  late DateTime _date = dateOnly(ref.read(clockProvider)());
  final _note = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) _load(widget.entryId!);
  }

  Future<void> _load(int id) async {
    final e = await ref.read(entryRepositoryProvider).find(id);
    if (!mounted || e == null) return;
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'VND',
    );
    setState(() {
      _original = e;
      _from = e.accountId;
      _to = e.toAccountId;
      _expression = minorUnitsToInput(e.amount, digits);
      _date = parseDateKey(e.date);
      _note.text = e.note ?? '';
    });
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _digits =>
      currencyDecimalDigits(ref.read(currencyProvider).value ?? 'VND');

  void _onKey(String key) => setState(() {
    _error = null;
    _expression = applyKeypadKey(_expression, key, decimalDigits: _digits);
  });

  Future<void> _save(List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final from = _from ?? accounts.first.id;
    final to = _to ?? accounts[1].id;
    final amount = evaluateToMinorUnits(_expression, decimalDigits: _digits);
    if (from == to) {
      setState(() => _error = l.sameAccountError);
      return;
    }
    if (amount == null || amount <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    final repo = ref.read(entryRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final original = _original;
    if (original == null) {
      await repo.addTransfer(
        fromAccountId: from,
        toAccountId: to,
        amount: amount,
        date: dateKey(_date),
        note: note,
      );
    } else {
      await repo.update(
        original.copyWith(
          accountId: from,
          toAccountId: Value(to),
          amount: amount,
          date: dateKey(_date),
          note: Value(note),
        ),
      );
    }
    if (mounted) context.pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final repo = ref.read(entryRepositoryProvider);
    final deleted = await repo.delete(_original!.id);
    if (!mounted) return;
    context.pop();
    if (deleted != null) {
      showUndoSnackBar(
        message: l.deleted,
        undoLabel: l.undo,
        onUndo: () => repo.restore(deleted),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final value = evaluateToMinorUnits(_expression, decimalDigits: digits);

    Widget accountPicker(
      String label,
      int? selected,
      ValueChanged<int?> onChanged,
    ) => DropdownButtonFormField<int>(
      isExpanded: true,
      initialValue: selected,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final a in accounts)
          DropdownMenuItem(value: a.id, child: Text(accountLabel(l, a))),
      ],
      onChanged: onChanged,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l.transfer),
        actions: [
          if (_original != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: accounts.length < 2
          ? const SizedBox.shrink()
          : SafeArea(
              child: Column(
                children: [
                  // Phần trên cuộn được, bàn phím luôn ở dưới cùng; cỡ chữ
                  // 200% không làm tràn màn hình (AC-37, AC-38).
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: accountPicker(
                                    l.transferFrom,
                                    _from ?? accounts.first.id,
                                    (v) => setState(() => _from = v),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: Icon(Icons.arrow_forward),
                                ),
                                Expanded(
                                  child: accountPicker(
                                    l.transferTo,
                                    _to ?? accounts[1].id,
                                    (v) => setState(() => _to = v),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            money(context, currency, value ?? 0),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          if (_error != null)
                            Text(
                              _error!,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ActionChip(
                            avatar: const Icon(Icons.event, size: 18),
                            label: Text(
                              _date == dateOnly(ref.read(clockProvider)())
                                  ? l.today
                                  : shortDate(context, _date),
                            ),
                            onPressed: () async {
                              final now = ref.read(clockProvider)();
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _date,
                                firstDate: _date.isBefore(DateTime(2000))
                                    ? _date
                                    : DateTime(2000),
                                lastDate: DateTime(now.year + 10),
                              );
                              if (picked != null) {
                                setState(() => _date = dateOnly(picked));
                              }
                            },
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _note,
                              maxLength: 200,
                              decoration: InputDecoration(hintText: l.noteHint),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Keypad(
                    decimalDigits: digits,
                    onKey: _onKey,
                    saveLabel: l.save,
                    saveColor: Theme.of(context).colorScheme.primary,
                    onSave: () => _save(accounts),
                  ),
                ],
              ),
            ),
    );
  }
}
