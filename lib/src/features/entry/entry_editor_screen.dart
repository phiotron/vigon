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
import '../../ui/category_avatar.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import 'keypad.dart';

/// Ghi khoản mới hoặc sửa khoản có sẵn (F-01, F-04).
class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({
    super.key,
    this.entryId,
    this.type = EntryType.expense,
    this.categoryId,
  });

  final int? entryId;
  final EntryType type;
  final int? categoryId;

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  Entry? _original;
  late EntryType _type = widget.type;
  late int? _categoryId = widget.categoryId;
  String _expression = '';
  late DateTime _date = dateOnly(ref.read(clockProvider)());
  int? _accountId;
  final _note = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _saving = false;
  RecurrenceFrequency? _repeat;
  RecurringRule? _rule;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) {
      _loading = true;
      _load(widget.entryId!);
    }
  }

  Future<void> _load(int id) async {
    final entry = await ref.read(entryRepositoryProvider).find(id);
    if (!mounted) return;
    if (entry == null) {
      context.pop();
      return;
    }
    final digits = currencyDecimalDigits(
      ref.read(currencyProvider).value ?? 'VND',
    );
    final ruleId = entry.recurringRuleId;
    final rule = ruleId == null
        ? null
        : await ref.read(recurringRepositoryProvider).find(ruleId);
    if (!mounted) return;
    setState(() {
      _rule = rule;
      _original = entry;
      _type = entry.type;
      _categoryId = entry.categoryId;
      _expression = minorUnitsToInput(entry.amount, digits);
      _date = parseDateKey(entry.date);
      _accountId = entry.accountId;
      _note.text = entry.note ?? '';
      _loading = false;
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

  /// Kiểm số tiền; trả về null và hiện lỗi nếu không hợp lệ (AC-05).
  int? _validAmount() {
    final l = AppLocalizations.of(context);
    final v = evaluateToMinorUnits(_expression, decimalDigits: _digits);
    if (v == null && _expression.isNotEmpty && _expression != '0') {
      setState(() => _error = l.invalidExpression);
      return null;
    }
    if (v == null || v <= 0) {
      setState(() => _error = l.amountMustBePositive);
      return null;
    }
    return v;
  }

  Future<void> _save() async {
    if (_saving) return;
    final amount = _validAmount();
    if (amount == null) return;
    if (_categoryId == null) {
      final picked = await _pickCategory();
      if (picked == null) return;
      _categoryId = picked;
    }
    _saving = true;
    final repo = ref.read(entryRepositoryProvider);
    final accountId = _accountId ?? await _defaultAccountId();
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final original = _original;
    if (original == null) {
      final entry = EntriesCompanion.insert(
        type: _type,
        amount: amount,
        categoryId: Value(_categoryId),
        accountId: accountId,
        date: dateKey(_date),
        note: Value(note),
      );
      final repeat = _repeat;
      if (repeat == null) {
        await repo.add(entry);
      } else {
        // Ngày bắt đầu ở quá khứ thì tạo luôn các lần đã tới hạn (AC-24).
        final recurring = ref.read(recurringRepositoryProvider);
        await recurring.addWithRepeat(entry, repeat);
        await recurring.generateDue(ref.read(clockProvider)());
      }
    } else {
      await repo.update(
        original.copyWith(
          amount: amount,
          categoryId: Value(_categoryId),
          accountId: accountId,
          date: dateKey(_date),
          note: Value(note),
        ),
      );
    }
    if (mounted) context.pop();
  }

  Future<int> _defaultAccountId() async {
    final accounts = await ref.read(accountRepositoryProvider).watch().first;
    return accounts.first.id;
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

  /// Lưới danh mục; chạm một danh mục là chọn nó (AC-02).
  Future<int?> _pickCategory() {
    final type = _type == EntryType.income
        ? CategoryType.income
        : CategoryType.expense;
    return showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => _CategoryGrid(type: type, selectedId: _categoryId),
    );
  }

  Future<void> _pickRepeat() async {
    final l = AppLocalizations.of(context);
    final options = <RecurrenceFrequency?>[null, ...RecurrenceFrequency.values];
    final picked = await showModalBottomSheet<(RecurrenceFrequency?,)>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final f in options)
              ListTile(
                title: Text(repeatLabel(l, f)),
                selected: f == _repeat,
                trailing: f == _repeat ? const Icon(Icons.check) : null,
                onTap: () => Navigator.pop(context, (f,)),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _repeat = picked.$1);
  }

  /// Dừng chuỗi định kỳ của khoản này; khoản đã tạo giữ nguyên (AC-25).
  Future<void> _stopRepeat() async {
    final rule = _rule;
    if (rule == null) return;
    final stopped = AppLocalizations.of(context).repeatStopped;
    await ref.read(recurringRepositoryProvider).stop(rule.id);
    if (!mounted) return;
    setState(() => _rule = rule.copyWith(active: false));
    showMessage(stopped);
  }

  Future<void> _pickDate() async {
    final now = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  Future<void> _pickAccount(List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final a in accounts)
              ListTile(
                title: Text(accountLabel(l, a)),
                selected: a.id == (_accountId ?? accounts.first.id),
                onTap: () => Navigator.pop(context, a.id),
              ),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _accountId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final isIncome = _type == EntryType.income;
    final color = isIncome ? incomeColor(context) : expenseColor(context);
    final value = evaluateToMinorUnits(_expression, decimalDigits: digits);
    final category = _categoryId == null
        ? null
        : (ref
                      .watch(
                        categoriesProvider(
                          isIncome ? CategoryType.income : CategoryType.expense,
                        ),
                      )
                      .value ??
                  const <Category>[])
              .where((c) => c.id == _categoryId)
              .firstOrNull;
    final account =
        accounts.where((a) => a.id == _accountId).firstOrNull ??
        accounts.firstOrNull;
    final title = _original != null
        ? l.editEntry
        : (isIncome ? l.newIncome : l.newExpense);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_original != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l.delete,
              onPressed: _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
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
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                            child: Semantics(
                              liveRegion: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    _expression.isEmpty ? ' ' : _expression,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      money(context, currency, value ?? 0),
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(color: color),
                                    ),
                                  ),
                                  if (_error != null)
                                    Text(
                                      _error!,
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .error,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                if (category != null)
                                  ActionChip(
                                    avatar: CategoryAvatar(
                                      category: category,
                                      size: 24,
                                    ),
                                    label: Text(categoryLabel(l, category)),
                                    onPressed: () async {
                                      final picked = await _pickCategory();
                                      if (picked != null) {
                                        setState(() => _categoryId = picked);
                                      }
                                    },
                                  ),
                                ActionChip(
                                  avatar: const Icon(Icons.event, size: 18),
                                  label: Text(
                                    _date == dateOnly(ref.read(clockProvider)())
                                        ? l.today
                                        : shortDate(context, _date),
                                  ),
                                  onPressed: _pickDate,
                                ),
                                if (_original == null)
                                  ActionChip(
                                    avatar: const Icon(Icons.repeat, size: 18),
                                    label: Text(repeatLabel(l, _repeat)),
                                    onPressed: _pickRepeat,
                                  )
                                else if (_rule != null && _rule!.active)
                                  InputChip(
                                    avatar: const Icon(Icons.repeat, size: 18),
                                    label: Text(
                                      repeatLabel(l, _rule!.frequency),
                                    ),
                                    deleteIcon: const Icon(
                                      Icons.stop_circle_outlined,
                                    ),
                                    deleteButtonTooltipMessage: l.stopRepeat,
                                    onDeleted: _stopRepeat,
                                  ),
                                if (account != null && accounts.length > 1)
                                  ActionChip(
                                    avatar: const Icon(
                                      Icons.account_balance_wallet_outlined,
                                      size: 18,
                                    ),
                                    label: Text(accountLabel(l, account)),
                                    onPressed: () => _pickAccount(accounts),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: TextField(
                              controller: _note,
                              maxLength: 200,
                              decoration: InputDecoration(hintText: l.noteHint),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Keypad(
                    decimalDigits: digits,
                    onKey: _onKey,
                    saveLabel: _categoryId == null ? l.chooseCategory : l.save,
                    saveColor: color,
                    onSave: _save,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  const _CategoryGrid({required this.type, required this.selectedId});

  final CategoryType type;
  final int? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final categories =
        ref.watch(categoriesProvider(type)).value ?? const <Category>[];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l.chooseCategory,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Flexible(
              child: GridView.extent(
                shrinkWrap: true,
                maxCrossAxisExtent: 96,
                childAspectRatio: 0.8,
                children: [
                  for (final c in categories)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, c.id),
                      child: Semantics(
                        button: true,
                        selected: c.id == selectedId,
                        label: categoryLabel(l, c),
                        excludeSemantics: true,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CategoryAvatar(category: c),
                            const SizedBox(height: 4),
                            Text(
                              categoryLabel(l, c),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String repeatLabel(AppLocalizations l, RecurrenceFrequency? f) => switch (f) {
  null => l.repeatNone,
  RecurrenceFrequency.daily => l.repeatDaily,
  RecurrenceFrequency.weekly => l.repeatWeekly,
  RecurrenceFrequency.monthly => l.repeatMonthly,
  RecurrenceFrequency.yearly => l.repeatYearly,
};
