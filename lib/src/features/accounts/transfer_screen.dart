import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/calculator.dart';
import '../../data/database.dart';
import '../../data/money_sum.dart';
import '../../data/dates.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/amount_display.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../entry/entry_time.dart';
import '../entry/keypad.dart';
import '../import_queue/queue_match.dart';
import '../settings/currency_conversion.dart' show formatRate;
import '../settings/rates_format.dart' show ratePairFor;

/// Chuyển tiền giữa hai tài khoản (AC-19); sửa hoặc xóa lần chuyển có sẵn.
class TransferScreen extends ConsumerStatefulWidget {
  const TransferScreen({super.key, this.entryId, this.toAccountId});

  final int? entryId;

  /// Điền sẵn ô Đến (AC-102: "Góp tiền" vào tài khoản của mục tiêu tiết kiệm).
  final int? toAccountId;

  @override
  ConsumerState<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends ConsumerState<TransferScreen> {
  Entry? _original;
  int? _from;
  late int? _to = widget.toAccountId;
  String _expression = '';

  /// Số nhận khi chuyển khác tiền tệ (D-037); cùng tiền tệ thì bằng số gửi.
  String _toExpression = '';
  String? _receivedError;

  /// Người dùng chạm thẻ "Bên nhận được" để tự gõ số nhận (mockup v4 SCR-19);
  /// chưa chạm thì số nhận = số gửi quy đổi theo tỷ giá đã lưu.
  bool _editReceived = false;

  /// Tiền tệ của số gửi/số nhận; mặc định theo tài khoản, giữ nguyên khi sửa.
  String? _currency;
  String? _toCurrency;
  late DateTime _date = dateOnly(ref.read(clockProvider)());
  late String? _time = nowTimeKey(ref.read(clockProvider)());
  final _note = TextEditingController();
  final _toAmount = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.entryId != null) _load(widget.entryId!);
  }

  Future<void> _load(int id) async {
    final e = await ref.read(entryRepositoryProvider).find(id);
    if (!mounted || e == null) return;
    final currency = e.currency;
    final toCurrency = e.toCurrency ?? currency;
    setState(() {
      _original = e;
      _from = e.accountId;
      _to = e.toAccountId;
      _currency = currency;
      _toCurrency = toCurrency;
      _expression = minorUnitsToInput(
        e.originalAmount ?? e.amount,
        currencyDecimalDigits(currency),
      );
      _toExpression = minorUnitsToInput(
        e.toOriginalAmount ?? e.toAmount ?? e.originalAmount ?? e.amount,
        currencyDecimalDigits(toCurrency),
      );
      _toAmount.text = _toExpression;
      // Lần chuyển khác tiền tệ đã lưu: giữ số nhận đã lưu, hiện ô sửa.
      _editReceived = toCurrency != currency;
      _date = parseDateKey(e.date);
      _time = e.time;
      _note.text = e.note ?? '';
    });
  }

  @override
  void dispose() {
    _note.dispose();
    _toAmount.dispose();
    super.dispose();
  }

  int get _digits => currencyDecimalDigits(
    _currency ?? ref.read(currencyProvider).value ?? 'USD',
  );

  void _onKey(String key) => setState(() {
    _error = null;
    _expression = applyKeypadKey(_expression, key, decimalDigits: _digits);
  });

  /// Tài khoản Từ mặc định: tài khoản hiện đầu tiên, trừ tài khoản Đến đã điền
  /// sẵn (AC-102: Từ = tài khoản mặc định).
  int? _defaultFrom(List<Account> accounts) {
    if (accounts.isEmpty) return null;
    return accounts
        .firstWhere(
          (a) => a.id != widget.toAccountId,
          orElse: () => accounts.first,
        )
        .id;
  }

  Future<void> _save(List<Account> accounts) async {
    final l = AppLocalizations.of(context);
    final from = _from ?? _defaultFrom(accounts)!;
    final to = _to ?? accounts[1].id;
    final fromAccount = accounts.where((a) => a.id == from).firstOrNull;
    final toAccount = accounts.where((a) => a.id == to).firstOrNull;
    final fromCurrency =
        _currency ??
        fromAccount?.currency ??
        ref.read(currencyProvider).value ??
        'USD';
    final toCurrency =
        _toCurrency ??
        toAccount?.currency ??
        ref.read(currencyProvider).value ??
        'USD';
    final sentOriginal = evaluateToMinorUnits(
      _expression,
      decimalDigits: currencyDecimalDigits(fromCurrency),
    );
    if (from == to) {
      setState(() => _error = l.sameAccountError);
      return;
    }
    // Khoản đang 0 (do quy đổi tiền tệ, D-029) giữ nguyên thì vẫn lưu được.
    final unchangedZero =
        sentOriginal == 0 &&
        ((_original?.originalAmount ?? _original?.amount) == 0);
    if (sentOriginal == null || (sentOriginal <= 0 && !unchangedZero)) {
      setState(() => _error = l.amountMustBePositive);
      return;
    }
    final sameCurrency = fromCurrency == toCurrency;
    final typedReceived = _toExpression.trim();
    final receivedOriginal = sameCurrency
        ? sentOriginal
        : typedReceived.isEmpty
        // Chưa gõ số nhận: quy đổi số gửi theo tỷ giá đã lưu (mockup v4).
        ? (MoneyBag()..add(fromCurrency, sentOriginal)).convertTo(
            await ref.read(currencyServiceProvider.future),
            toCurrency,
            skipMissing: false,
          )
        : parseAmountField(
            context,
            typedReceived,
            currencyDecimalDigits(toCurrency),
          );
    if (!mounted) return;
    if (!sameCurrency && (receivedOriginal == null || receivedOriginal <= 0)) {
      setState(
        () => _receivedError = _toExpression.trim().isEmpty
            ? l.amountMustBePositive
            : l.invalidExpression,
      );
      return;
    }
    final service = await ref.read(currencyServiceProvider.future);
    final amount = service.toPrimary(sentOriginal, fromCurrency);
    final toAmount = service.toPrimary(receivedOriginal!, toCurrency);
    if (amount == null || toAmount == null) {
      if (!mounted) return;
      setState(() {
        if (amount == null) {
          _error = l.rateMissing(fromCurrency, service.primary);
        } else {
          _receivedError = l.rateMissing(toCurrency, service.primary);
        }
      });
      return;
    }
    final repo = ref.read(entryRepositoryProvider);
    final note = _note.text.trim().isEmpty ? null : _note.text.trim();
    final original = _original;
    int savedId;
    if (original == null) {
      savedId = await repo.addTransfer(
        fromAccountId: from,
        toAccountId: to,
        amount: amount,
        originalAmount: sentOriginal,
        currency: fromCurrency,
        toAmount: toAmount,
        toOriginalAmount: receivedOriginal,
        toCurrency: toCurrency,
        date: dateKey(_date),
        time: _time,
        note: note,
      );
    } else {
      await repo.update(
        original.copyWith(
          accountId: from,
          toAccountId: Value(to),
          amount: amount,
          // Giữ số chính xác cũ khi không đổi tiền tệ/số tiền (D-029).
          amountMicro: Value(
            fromCurrency == service.primary && amount == original.amount
                ? original.amountMicro
                : null,
          ),
          originalAmount: Value(sentOriginal),
          currency: fromCurrency,
          toAmount: Value(toAmount),
          toOriginalAmount: Value(receivedOriginal),
          toCurrency: Value(toCurrency),
          date: dateKey(_date),
          time: Value(_time),
          note: Value(note),
        ),
      );
      savedId = original.id;
    }
    // Chuyển tiền đi vừa lưu khớp một mục đang chờ (AC-94, AC-91).
    final matched = mounted ? await matchQueueFor(ref, context, savedId) : null;
    if (mounted) context.pop();
    matched?.showUndo();
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
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final all = ref.watch(allAccountsProvider).value ?? accounts;
    final from = _from ?? _defaultFrom(accounts);
    final to = _to ?? (accounts.length < 2 ? null : accounts[1].id);
    final fromAccount = all.where((a) => a.id == from).firstOrNull;
    final toAccount = all.where((a) => a.id == to).firstOrNull;
    // Tiền tệ của số gửi/nhận: khoản đang sửa giữ đúng tiền tệ đã lưu; khoản
    // mới bám tài khoản (D-037).
    final fromCurrency = _currency ?? fromAccount?.currency ?? primary;
    final toCurrency = _toCurrency ?? toAccount?.currency ?? primary;
    if (_currency == null && fromAccount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _currency == null) {
          setState(() => _currency = fromAccount.currency);
        }
      });
    }
    if (_toCurrency == null && toAccount != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _toCurrency == null) {
          setState(() => _toCurrency = toAccount.currency);
        }
      });
    }
    final digits = currencyDecimalDigits(fromCurrency);
    final cross = fromCurrency != toCurrency;
    final value = evaluateToMinorUnits(_expression, decimalDigits: digits);
    final service = ref.watch(currencyServiceProvider).value;
    final estimate = !cross || service == null || (value ?? 0) < 0
        ? null
        : (MoneyBag()..add(fromCurrency, value ?? 0)).convertTo(
            service,
            toCurrency,
            skipMissing: false,
          );
    final converted = fromCurrency == primary
        ? null
        : service?.toPrimary(value ?? 0, fromCurrency);
    final table = ref.watch(rateTableProvider).value;
    // Chiều dễ đọc: "1 USD = 25.974 VND" (đồng mạnh hơn đứng trước).
    final pair = table == null || !cross
        ? null
        : ratePairFor(table, fromCurrency, toCurrency);
    final pairRate = pair == null ? null : table!.rate(pair.$1, pair.$2)?.toDouble();
    final rateLine = pair == null || pairRate == null
        ? null
        : l.rateLine(pair.$1, formatRate(pairRate, l.localeName), pair.$2);
    final secondary = fromCurrency == primary
        ? null
        : converted == null
        ? l.rateMissing(fromCurrency, primary)
        : '≈ ${money(context, primary, converted)}';
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
      body:
          accounts.length < 2 &&
              _original == null &&
              !(widget.toAccountId != null && accounts.isNotEmpty)
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
                                      _currency = all
                                          .where((a) => a.id == v)
                                          .firstOrNull
                                          ?.currency;
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
                                      _toCurrency = all
                                          .where((a) => a.id == v)
                                          .firstOrNull
                                          ?.currency;
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
                            amount: money(context, fromCurrency, value ?? 0),
                            secondary: secondary,
                            color: scheme.onSurface,
                            error: error,
                          ),
                          if (cross && !_editReceived)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                VgSpace.s4,
                                0,
                                VgSpace.s4,
                                VgSpace.s2,
                              ),
                              child: _ReceiveCard(
                                amount: estimate == null
                                    ? '–'
                                    : money(context, toCurrency, estimate),
                                rateLine: rateLine,
                                error: _receivedError,
                                onTap: () => setState(() {
                                  _editReceived = true;
                                  if (estimate != null &&
                                      _toExpression.trim().isEmpty) {
                                    _toExpression = minorUnitsToInput(
                                      estimate,
                                      currencyDecimalDigits(toCurrency),
                                    );
                                    _toAmount.text = _toExpression;
                                  }
                                }),
                              ),
                            ),
                          if (cross && _editReceived)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                VgSpace.s4,
                                0,
                                VgSpace.s4,
                                VgSpace.s2,
                              ),
                              child: TextField(
                                controller: _toAmount,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: const TextStyle(
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                                onChanged: (v) {
                                  _toExpression = v;
                                  if (_receivedError != null) {
                                    setState(() => _receivedError = null);
                                  }
                                },
                                // "Bên nhận được" + số ước tính theo tỷ giá
                                // đã lưu (mockup v4 SCR-19).
                                decoration: InputDecoration(
                                  labelText: l.youReceive,
                                  helperText: estimate == null
                                      ? null
                                      : '≈ ${money(context, toCurrency, estimate)}',
                                  suffixText: toCurrency,
                                  errorText: _receivedError,
                                  errorMaxLines: 3,
                                ),
                              ),
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
                              child: Wrap(
                                spacing: VgSpace.s2,
                                children: [
                                  ActionChip(
                                    avatar: const Icon(
                                      Symbols.calendar_today_rounded,
                                      size: 18,
                                    ),
                                    label: Text(
                                      _date ==
                                              dateOnly(
                                                ref.read(clockProvider)(),
                                              )
                                          ? l.today
                                          : shortDate(context, _date),
                                    ),
                                    onPressed: () async {
                                      final now = ref.read(clockProvider)();
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _date,
                                        firstDate:
                                            _date.isBefore(DateTime(2000))
                                            ? _date
                                            : DateTime(2000),
                                        lastDate: DateTime(now.year + 10),
                                      );
                                      if (picked != null) {
                                        setState(
                                          () => _date = dateOnly(picked),
                                        );
                                      }
                                    },
                                  ),
                                  TimeChip(
                                    time: _time,
                                    fallback: nowTimeKey(
                                      ref.read(clockProvider)(),
                                    ),
                                    onChanged: (t) => setState(() => _time = t),
                                  ),
                                ],
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
                  // Thanh thông báo luôn nằm trên bàn phím số + Lưu (6.7,
                  // CHANGELOG "inverse-surface").
                  SnackBarClearance(
                    child: Keypad(
                      decimalDigits: digits,
                      onKey: _onKey,
                      saveLabel: l.save,
                      saveColor: scheme.primary,
                      saveForeground: scheme.onPrimary,
                      onSave: () => _save(accounts),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// Thẻ "Bên nhận được" (mockup v4 SCR-19): số nhận ước tính theo tỷ giá đã
/// lưu + dòng tỷ giá; chạm để tự gõ số nhận.
class _ReceiveCard extends StatelessWidget {
  const _ReceiveCard({
    required this.amount,
    required this.rateLine,
    required this.onTap,
    this.error,
  });

  final String amount;
  final String? rateLine;
  final String? error;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: [l.youReceive, amount, ?rateLine].join(', '),
      excludeSemantics: true,
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(VgRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(VgRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(VgSpace.s3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l.youReceive,
                        style: VgType.bodyMd.copyWith(color: scheme.onSurface),
                      ),
                    ),
                    Text(
                      amount,
                      style: VgType.amountMd.copyWith(color: scheme.onSurface),
                    ),
                    const SizedBox(width: VgSpace.s1),
                    Icon(
                      Symbols.edit_rounded,
                      size: 18,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (rateLine != null)
                  Text(
                    rateLine!,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: VgType.bodySm.copyWith(color: scheme.error),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
