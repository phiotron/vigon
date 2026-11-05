import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/amount_display.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
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
    final scheme = Theme.of(context).colorScheme;
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? accounts;
    final value = evaluateToMinorUnits(_expression, decimalDigits: digits);
    final from = _from ?? (accounts.isEmpty ? null : accounts.first.id);
    final to = _to ?? (accounts.length < 2 ? null : accounts[1].id);
    // Hai tài khoản giống nhau: báo ngay, ô Đến viền `error` (6.7).
    final same = from != null && from == to;
    final error = same ? l.sameAccountError : _error;

    // Ô chọn tài khoản (`.vg-field`, cao tối thiểu 48), tên dài vẫn một dòng
    // vì mỗi ô chiếm cả bề ngang. Tài khoản đã ẩn chỉ hiện khi là tài khoản
    // sẵn có của lần chuyển đang sửa (AC-44).
    Widget accountPicker(
      String label,
      int? selected,
      ValueChanged<int?> onChanged, {
      bool invalid = false,
    }) {
      final errorBorder = OutlineInputBorder(
        borderRadius: BorderRadius.circular(VgRadius.sm),
        borderSide: BorderSide(color: scheme.error, width: 2),
      );
      return DropdownButtonFormField<int>(
        // Đổi khóa theo giá trị để ô hiện đúng tài khoản sau khi nạp lần chuyển cũ.
        key: ValueKey('$label-$selected'),
        isExpanded: true,
        initialValue: selected,
        style: Theme.of(context).textTheme.bodyLarge,
        icon: const Icon(Symbols.arrow_drop_down_rounded),
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: VgSpace.s4,
            vertical: VgSpace.s3,
          ),
          enabledBorder: invalid ? errorBorder : null,
          focusedBorder: invalid ? errorBorder : null,
        ),
        items: [
          for (final a in [
            ...accounts,
            for (final a in all)
              if (a.id == selected && !accounts.any((v) => v.id == a.id)) a,
          ])
            DropdownMenuItem(
              value: a.id,
              child: Text(
                accountLabel(l, a),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
        onChanged: onChanged,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l.transfer),
        actions: [
          if (_original != null)
            IconButton(
              icon: const Icon(Symbols.delete_rounded),
              tooltip: l.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: accounts.length < 2 && _original == null
          ? const SizedBox.shrink()
          : SafeArea(
              child: Column(
                children: [
                  // Phần trên cuộn được, bàn phím luôn ở dưới cùng; cỡ chữ
                  // 200% không làm tràn màn hình (AC-37, AC-38).
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Từ và Đến xếp dọc (6.6).
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VgSpace.s4,
                              VgSpace.s3,
                              VgSpace.s4,
                              0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                KeyedSubtree(
                                  key: const ValueKey('transfer-from'),
                                  child: accountPicker(
                                    l.transferFrom,
                                    from,
                                    (v) => setState(() {
                                      _from = v;
                                      _error = null;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: VgSpace.s4),
                                KeyedSubtree(
                                  key: const ValueKey('transfer-to'),
                                  child: accountPicker(
                                    l.transferTo,
                                    to,
                                    (v) => setState(() {
                                      _to = v;
                                      _error = null;
                                    }),
                                    invalid: same,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          AmountDisplay(
                            expression: _expression,
                            amount: money(context, currency, value ?? 0),
                            color: scheme.onSurface,
                            error: error,
                          ),
                          // Chip ngày (`.vg-chips`): căn trái, lề 16.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VgSpace.s4,
                              0,
                              VgSpace.s4,
                              VgSpace.s3,
                            ),
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ActionChip(
                                avatar: const Icon(
                                  Symbols.calendar_today_rounded,
                                  size: 18,
                                ),
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
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: VgSpace.s4,
                            ),
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
                    saveColor: scheme.primary,
                    saveForeground: scheme.onPrimary,
                    onSave: () => _save(accounts),
                  ),
                ],
              ),
            ),
    );
  }
}
