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
import '../../ui/category_avatar.dart';
import '../../ui/category_grid.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/theme.dart';
import '../import_queue/import_queue_actions.dart';
import '../import_queue/import_queue_providers.dart';
import '../import_queue/queue_match.dart';
import '../../ui/tokens.g.dart';
import 'entry_time.dart';
import 'keypad.dart';

/// Ghi khoản mới hoặc sửa khoản có sẵn (F-01, F-04).
class EntryEditorScreen extends ConsumerStatefulWidget {
  const EntryEditorScreen({
    super.key,
    this.entryId,
    this.type = EntryType.expense,
    this.categoryId,
    this.queueItemId,
  });

  final int? entryId;
  final EntryType type;
  final int? categoryId;

  /// Mục hàng đợi đang "Sửa trước khi lưu" (AC-96): màn điền sẵn dữ liệu của
  /// mục; lưu thì tạo khoản có nguồn + số tham chiếu và mục rời hàng đợi.
  final int? queueItemId;

  @override
  ConsumerState<EntryEditorScreen> createState() => _EntryEditorScreenState();
}

class _EntryEditorScreenState extends ConsumerState<EntryEditorScreen> {
  Entry? _original;
  ImportQueueItem? _queueItem;
  late EntryType _type = widget.type;
  late int? _categoryId = widget.categoryId;
  String _expression = '';
  late DateTime _date = dateOnly(ref.read(clockProvider)());
  int? _accountId;
  // Giờ `HH:mm`; khoản mới mặc định giờ lúc mở màn (AC-74), khoản cũ có thể
  // chưa có giờ (AC-75).
  late String? _time = nowTimeKey(ref.read(clockProvider)());
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
    } else if (widget.queueItemId != null) {
      _loading = true;
      _loadQueueItem(widget.queueItemId!);
    }
  }

  /// Điền sẵn từ mục hàng đợi (AC-96). Khác tiền tệ app thì ô số tiền để trống
  /// cho người dùng tự nhập, không tự quy đổi (AC-87).
  Future<void> _loadQueueItem(int id) async {
    final item = await ref.read(importQueueRepositoryProvider).find(id);
    if (!mounted) return;
    if (item == null) {
      context.pop();
      return;
    }
    final currency = ref.read(currencyProvider).value ?? 'VND';
    final accountId = await ref
        .read(importQueueActionsProvider)
        .resolveAccount(item);
    if (!mounted) return;
    setState(() {
      _queueItem = item;
      _type = EntryType.expense;
      _accountId = accountId;
      _date = parseDateKey(item.date);
      _time = item.time;
      _note.text = queueItemNote(item) ?? '';
      if (item.currency == currency) {
        _expression = minorUnitsToInput(
          item.amount,
          currencyDecimalDigits(currency),
        );
      }
      _loading = false;
    });
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
      _time = entry.time;
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
    // Khoản đang 0 (quy đổi tiền tệ làm tròn một số rất nhỏ, D-029) mở ra mà
    // giữ nguyên số tiền thì vẫn lưu được; AC-05 chặn số 0 do người dùng gõ.
    final unchangedZero = v == 0 && _original?.amount == 0;
    if (v == null || (v <= 0 && !unchangedZero)) {
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
    int? savedId;
    try {
      final repo = ref.read(entryRepositoryProvider);
      final accountId = _accountId ?? await _defaultAccountId();
      final note = _note.text.trim().isEmpty ? null : _note.text.trim();
      final original = _original;
      final queueItem = _queueItem;
      if (queueItem != null) {
        // Từ hàng đợi: tạo khoản chi có nguồn + số tham chiếu của email, mục
        // rời hàng đợi, nhớ gợi ý (AC-96). Giữ số chính xác nếu không đổi số.
        final currency = ref.read(currencyProvider).value ?? 'VND';
        final same =
            queueItem.currency == currency && amount == queueItem.amount;
        await ref
            .read(importQueueActionsProvider)
            .saveEdited(
              queueItem,
              EntriesCompanion.insert(
                type: EntryType.expense,
                amount: amount,
                amountMicro: Value(same ? queueItem.amountMicro : null),
                categoryId: Value(_categoryId),
                accountId: accountId,
                date: dateKey(_date),
                time: Value(_time),
                note: Value(note),
              ),
            );
      } else if (original == null) {
        final entry = EntriesCompanion.insert(
          type: _type,
          amount: amount,
          categoryId: Value(_categoryId),
          accountId: accountId,
          date: dateKey(_date),
          time: Value(_time),
          note: Value(note),
        );
        final repeat = _repeat;
        if (repeat == null) {
          savedId = await repo.add(entry);
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
            time: Value(_time),
            note: Value(note),
          ),
        );
        savedId = original.id;
      }
    } catch (_) {
      _saving = false;
      rethrow;
    }
    // Khoản ghi tay vừa lưu khớp một mục đang chờ (AC-94): mục rời hàng đợi,
    // gắn vào khoản, có thanh "Hoàn tác".
    final matched = savedId == null || !mounted
        ? null
        : await matchQueueFor(ref, context, savedId);
    if (mounted) context.pop();
    matched?.showUndo();
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
    return showCategorySheet(context, type: type, selectedId: _categoryId);
  }

  /// Bảng "Lặp lại" (3.5), chỉ có khi ghi khoản mới.
  Future<void> _pickRepeat() async {
    final l = AppLocalizations.of(context);
    final picked = await showChoiceSheet<RecurrenceFrequency?>(
      context,
      title: l.repeat,
      selected: _repeat,
      options: [
        for (final f in <RecurrenceFrequency?>[
          null,
          ...RecurrenceFrequency.values,
        ])
          ChoiceOption(f, repeatLabel(l, f)),
      ],
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
      firstDate: _date.isBefore(DateTime(2000)) ? _date : DateTime(2000),
      lastDate: DateTime(now.year + 10),
    );
    if (picked != null) setState(() => _date = dateOnly(picked));
  }

  /// Bảng "Tài khoản" (3.6); chip chỉ hiện khi có từ 2 tài khoản.
  Future<void> _pickAccount(List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final picked = await showChoiceSheet<int>(
      context,
      title: l.account,
      selected: _accountId ?? accounts.first.id,
      options: [
        for (final a in accounts)
          // Dữ liệu tài khoản không có icon riêng.
          ChoiceOption(
            a.id,
            accountLabel(l, a),
            icon: Symbols.account_balance_wallet_rounded,
          ),
      ],
    );
    if (picked != null) setState(() => _accountId = picked.$1);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final currency = ref.watch(currencyProvider).value ?? 'VND';
    final digits = currencyDecimalDigits(currency);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final scheme = Theme.of(context).colorScheme;
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
    // Khoản cũ của tài khoản đã ẩn vẫn hiện đúng tên tài khoản đó (AC-44).
    final account =
        (ref.watch(allAccountsProvider).value ?? accounts)
            .where((a) => a.id == _accountId)
            .firstOrNull ??
        accounts.firstOrNull;
    final pickable = [
      ...accounts,
      if (account != null && !accounts.any((a) => a.id == account.id)) account,
    ];
    // Màn sửa giữ tiêu đề "Sửa khoản" cả lúc đang nạp (4.7).
    final title = widget.entryId != null
        ? l.editEntry
        : (isIncome ? l.newIncome : l.newExpense);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (_original != null)
            IconButton(
              icon: const Icon(Symbols.delete_rounded),
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
                        // Số tiền căn phải, hàng chip căn trái, ô ghi chú rộng
                        // hết (bản vẽ 3.1); mặc định của Column là căn giữa.
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AmountDisplay(
                            expression: _expression,
                            amount: money(context, currency, value ?? 0),
                            color: color,
                            error: _error,
                          ),
                          // Hàng chip `.vg-chips`: lề 16, cách 8. Chip cao 40
                          // trong vùng chạm 48 nên hàng tự cách nhau 8.
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VgSpace.s4,
                              0,
                              VgSpace.s4,
                              VgSpace.s2,
                            ),
                            child: Wrap(
                              spacing: VgSpace.s2,
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
                                  avatar: const Icon(
                                    Symbols.calendar_today_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    _date == dateOnly(ref.read(clockProvider)())
                                        ? l.today
                                        : shortDate(context, _date),
                                  ),
                                  onPressed: _pickDate,
                                ),
                                TimeChip(
                                  time: _time,
                                  fallback: nowTimeKey(
                                    ref.read(clockProvider)(),
                                  ),
                                  onChanged: (t) => setState(() => _time = t),
                                ),
                                if (_original == null && _queueItem == null)
                                  ActionChip(
                                    avatar: const Icon(
                                      Symbols.repeat_rounded,
                                      size: 18,
                                    ),
                                    label: Text(repeatLabel(l, _repeat)),
                                    onPressed: _pickRepeat,
                                  )
                                else if (_rule != null && _rule!.active)
                                  InputChip(
                                    avatar: const Icon(
                                      Symbols.repeat_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      repeatLabel(l, _rule!.frequency),
                                    ),
                                    deleteIcon: Icon(
                                      Symbols.stop_circle_rounded,
                                      fill: 1,
                                      size: 20,
                                      color: context.vg.error,
                                    ),
                                    deleteButtonTooltipMessage: l.stopRepeat,
                                    onDeleted: _stopRepeat,
                                  ),
                                if (account != null && pickable.length > 1)
                                  ActionChip(
                                    avatar: const Icon(
                                      Symbols.account_balance_wallet_rounded,
                                      size: 18,
                                    ),
                                    label: Text(accountLabel(l, account)),
                                    onPressed: () => _pickAccount(pickable),
                                  ),
                              ],
                            ),
                          ),
                          // Ô ghi chú `.vg-field` v2 viền outline, cao 56
                          // (lề trong 16 của theme), bộ đếm label-sm "0/200"
                          // bên phải (AC-04).
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                              VgSpace.s4,
                              0,
                              VgSpace.s4,
                              VgSpace.s3,
                            ),
                            child: TextField(
                              controller: _note,
                              maxLength: 200,
                              style: VgType.bodyMd.copyWith(
                                color: scheme.onSurface,
                              ),
                              decoration: InputDecoration(
                                hintText: l.noteHint,
                                hintStyle: VgType.bodyMd.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                                counterStyle: VgType.labelSm.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Thanh thông báo luôn nằm trên bàn phím số + Lưu (v2).
                  SnackBarClearance(
                    child: Keypad(
                      decimalDigits: digits,
                      onKey: _onKey,
                      saveLabel: _categoryId == null
                          ? l.chooseCategory
                          : l.save,
                      saveColor: color,
                      saveForeground: isIncome
                          ? context.vg.onIncome
                          : context.vg.onExpense,
                      onSave: _save,
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
