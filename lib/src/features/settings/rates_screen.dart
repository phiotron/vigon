import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/dates.dart';
import '../../data/exchange_rate.dart';
import '../../data/money.dart';
import '../../data/rate_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import 'currency_conversion.dart' show formatRate;

/// Tiền tệ đang có số liệu; FutureProvider vì màn chỉ mở khi cần.
final _usedCurrenciesProvider = FutureProvider<Set<String>>(
  (ref) => ref.watch(rateRepositoryProvider).usedCurrencies(),
);

/// S10 › Tỷ giá (D-037): chỉ các cặp đang dùng, tỷ giá tự động/tự nhập, nút
/// "Cập nhật ngay", trạng thái ngoại tuyến và ghi công nguồn.
class RatesScreen extends ConsumerStatefulWidget {
  const RatesScreen({super.key});

  @override
  ConsumerState<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends ConsumerState<RatesScreen> {
  bool _busy = false;
  RatesRefreshResult? _last;

  @override
  void initState() {
    super.initState();
    // Chỉ tải khi bảng cũ ≥ 1 ngày; lỗi thì hiện trạng thái ngoại tuyến.
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh(force: false));
  }

  Future<void> _refresh({required bool force}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await ref
        .read(rateRepositoryProvider)
        .refreshIfStale(force: force);
    if (result == RatesRefreshResult.updated) {
      final settings = ref.read(settingsRepositoryProvider);
      final table = await ref.read(rateRepositoryProvider).load();
      final primary = await settings.readCurrency();
      await recomputeDerivedAmounts(
        ref.read(databaseProvider),
        CurrencyService(table, primary),
      );
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _last = result;
    });
    final l = AppLocalizations.of(context);
    if (force && result == RatesRefreshResult.updated) {
      showMessage(l.ratesUpdated);
    } else if (force && result == RatesRefreshResult.failed) {
      showMessage(l.ratesUpdateFailed);
    }
  }

  Future<void> _override(String from, String to) async {
    final table = await ref.read(rateRepositoryProvider).load();
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _OverrideSheet(from: from, to: to, table: table),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final table = ref.watch(rateTableProvider).value ?? RateTable.fallback;
    final currencies =
        (ref.watch(_usedCurrenciesProvider).value ?? {primary}).toList()
          ..sort();
    final pairs = [
      for (final c in currencies)
        if (c != primary) c,
    ];
    final offline =
        _last == RatesRefreshResult.failed ||
        (_last != RatesRefreshResult.notNeeded &&
            table.isStale(DateTime.now()));

    return Scaffold(
      appBar: AppBar(title: Text(l.exchangeRates)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: VgSpace.s6),
        children: [
          if (offline)
            VgHint(
              l.ratesOffline,
              icon: Symbols.cloud_off_rounded,
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                VgSpace.s2,
              ),
            ),
          if (table.isFallback)
            VgHint(
              l.ratesFallback,
              icon: Symbols.info_rounded,
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                0,
                VgSpace.s4,
                VgSpace.s2,
              ),
            ),
          if (pairs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(VgSpace.s4),
              child: Text(
                l.ratesNoPairs,
                style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final from in pairs)
            Builder(
              builder: (context) {
                final rate = table.rate(from, primary);
                final override =
                    table.overrides['$from>$primary'] != null ||
                    table.overrides['$primary>$from'] != null;
                return ListTile(
                  leading: const Icon(Symbols.currency_exchange_rounded),
                  title: Text('1 $from = ? $primary'),
                  subtitle: Text(
                    override
                        ? l.exchangeRateManualSource
                        : l.exchangeRateDate(
                            shortDate(context, parseDateKey(table.date)),
                          ),
                  ),
                  trailing: rate == null
                      ? Icon(Symbols.error_rounded, color: scheme.error)
                      : Text(
                          formatRate(rate.toDouble(), l.localeName),
                          style: const TextStyle(
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                  onTap: () => _override(from, primary),
                );
              },
            ),
          const Divider(),
          ListTile(
            leading: _busy
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Symbols.refresh_rounded),
            title: Text(l.ratesUpdateNow),
            onTap: _busy ? null : () => _refresh(force: true),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s2,
              VgSpace.s4,
              VgSpace.s2,
            ),
            child: Text(
              l.ratesSource,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi đè tỷ giá của một cặp: xem tỷ giá tự động, dùng tỷ giá của mình.
class _OverrideSheet extends ConsumerStatefulWidget {
  const _OverrideSheet({
    required this.from,
    required this.to,
    required this.table,
  });

  final String from;
  final String to;
  final RateTable table;

  @override
  ConsumerState<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends ConsumerState<_OverrideSheet> {
  late final _controller = TextEditingController(
    text: _currentOverride?.toStorage() ?? _autoRate?.toStorage() ?? '',
  );
  String? _error;
  bool _saving = false;
  Account? _previewAccount;
  int? _previewBalance;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  /// Xem trước số dư (theo tiền tệ của tài khoản) của tài khoản ĐẦU TIÊN dùng
  /// tiền tệ [widget.from], quy đổi bằng tỷ giá đang gõ (Q19, D-037).
  Future<void> _loadPreview() async {
    final db = ref.read(databaseProvider);
    final accounts = await db.select(db.accounts).get();
    Account? account;
    for (final a in accounts) {
      if (a.currency == widget.from) {
        account = a;
        break;
      }
    }
    if (account == null) return;
    final entries = await db.select(db.entries).get();
    var balance = account.initialBalanceOriginal ?? account.initialBalance;
    for (final e in entries) {
      switch (e.type) {
        case EntryType.income:
          if (e.accountId == account.id && e.currency == widget.from) {
            balance += e.originalAmount ?? e.amount;
          }
        case EntryType.expense:
          if (e.accountId == account.id && e.currency == widget.from) {
            balance -= e.originalAmount ?? e.amount;
          }
        case EntryType.transfer:
          if (e.accountId == account.id && e.currency == widget.from) {
            balance -= e.originalAmount ?? e.amount;
          }
          if (e.toAccountId == account.id && e.toCurrency == widget.from) {
            balance += e.toOriginalAmount ?? e.toAmount ?? e.amount;
          }
      }
    }
    if (!mounted) return;
    setState(() {
      _previewAccount = account;
      _previewBalance = balance;
    });
  }

  ExchangeRate? get _currentOverride {
    final direct = widget.table.overrides['${widget.from}>${widget.to}'];
    if (direct != null) return direct;
    return widget.table.overrides['${widget.to}>${widget.from}']?.inverse;
  }

  ExchangeRate? get _autoRate {
    final table = RateTable(
      base: widget.table.base,
      date: widget.table.date,
      rates: widget.table.rates,
    );
    return table.rate(widget.from, widget.to);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save({required bool own}) async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final settings = ref.read(settingsRepositoryProvider);
    if (!own) {
      _saving = true;
      await settings.clearRateOverride(widget.from, widget.to);
      await _recompute();
      if (mounted) Navigator.pop(context);
      return;
    }
    final rate = ExchangeRate.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    if (rate == null) {
      setState(() => _error = l.exchangeRateInvalid);
      return;
    }
    _saving = true;
    await settings.setRateOverride(widget.from, widget.to, rate);
    await _recompute();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _recompute() async {
    final table = await ref.read(rateRepositoryProvider).load();
    final primary = await ref.read(settingsRepositoryProvider).readCurrency();
    await recomputeDerivedAmounts(
      ref.read(databaseProvider),
      CurrencyService(table, primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final auto = _autoRate;
    final typedRate = ExchangeRate.tryParse(
      _controller.text.trim().replaceAll(',', '.'),
    );
    final previewAccount = _previewAccount;
    final previewBalance = _previewBalance;
    final previewConverted = typedRate == null || previewBalance == null
        ? null
        : convertMinorUnits(
            previewBalance,
            typedRate,
            fromDigits: currencyDecimalDigits(widget.from),
            toDigits: currencyDecimalDigits(widget.to),
          ).toInt();
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s1,
              VgSpace.s4,
              VgSpace.s2,
            ),
            child: Text('${widget.from} · ${widget.to}', style: VgType.titleMd),
          ),
          if (auto != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
              child: Text(
                l.exchangeRatePair(
                  widget.from,
                  formatRate(auto.toDouble(), l.localeName),
                  widget.to,
                ),
                style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (previewAccount != null &&
              previewBalance != null &&
              previewConverted != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4,
                VgSpace.s2,
                VgSpace.s4,
                0,
              ),
              child: Text(
                l.ratesPreviewBalance(
                  accountLabel(l, previewAccount),
                  money(context, widget.from, previewBalance),
                  money(context, widget.to, previewConverted),
                ),
                style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s4,
              VgSpace.s3,
              VgSpace.s4,
              0,
            ),
            child: TextField(
              controller: _controller,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: const TextStyle(
                fontFeatures: [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l.exchangeRateFieldLabel(widget.from, widget.to),
                errorText: _error,
                errorMaxLines: 3,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(VgSpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  onPressed: _saving ? null : () => _save(own: true),
                  child: Text(l.ratesUseOwn),
                ),
                const SizedBox(height: VgSpace.s2),
                TextButton(
                  onPressed: _saving ? null : () => _save(own: false),
                  child: Text(l.ratesUseAuto),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
