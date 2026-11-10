import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../data/exchange_rate.dart';
import '../../data/money.dart';
import '../../data/rate_repository.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/format.dart';
import '../../ui/messenger.dart';
import '../../ui/settings_rows.dart';
import '../../ui/theme.dart';
import '../../ui/tokens.g.dart';
import 'currency_conversion.dart' show formatRate;
import 'rates_format.dart';

/// S10 › Tỷ giá (D-037), bố cục theo A001: lời dẫn, các cặp đang dùng dạng
/// "1 USD → 25.400 VND" + trạng thái, banner ngoại tuyến, "Cập nhật ngay",
/// ghi chú và dòng ghi công nguồn mở được.
class RatesScreen extends ConsumerStatefulWidget {
  const RatesScreen({super.key});

  @override
  ConsumerState<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends ConsumerState<RatesScreen> {
  bool _busy = false;

  /// Chỉ bật sau khi một lần tải thật sự lỗi (tránh banner nhấp nháy lúc mở).
  bool _offline = false;

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
      if (result != RatesRefreshResult.notNeeded) {
        _offline = result == RatesRefreshResult.failed;
      }
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
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => _OverrideSheet(from: from, to: to, table: table),
    );
  }

  Future<void> _openSource() async {
    final l = AppLocalizations.of(context);
    final source = ref.read(exchangeRateSourceProvider);
    var opened = false;
    try {
      opened = await launchUrl(
        source.homepage,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (!opened && mounted) {
      showMessage(l.ratesLinkFailed(source.homepage.host));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final primary = ref.watch(currencyProvider).value ?? 'USD';
    final table = ref.watch(rateTableProvider).value ?? RateTable.fallback;
    final used = ref.watch(usedCurrenciesProvider).value ?? <String>{primary};
    final now = ref.watch(clockProvider)();
    final pairs = used.where((c) => c != primary).toList()..sort();

    return Scaffold(
      appBar: AppBar(title: Text(l.exchangeRates)),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: VgSpace.s6),
          children: [
            // Ngoại tuyến: dải hổ phách ở đầu màn (mockup v4 SCR-50 offline).
            if (_offline)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4,
                  VgSpace.s2,
                  VgSpace.s4,
                  0,
                ),
                child: _OfflineBanner(
                  title: l.ratesOfflineTitle,
                  body: l.ratesOfflineBody,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                VgSpace.s4 + VgSpace.s1,
                VgSpace.s2,
                VgSpace.s4 + VgSpace.s1,
                VgSpace.s4,
              ),
              child: Text(
                l.ratesIntro(primary),
                style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
            if (pairs.isEmpty)
              SettingsCard(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(VgSpace.s4),
                    child: Text(
                      l.ratesNoneUsed(primary),
                      style: VgType.bodyMd.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              )
            else
              SettingsCard(
                dividerIndent: VgSpace.s4,
                children: [
                  for (final from in pairs)
                    Builder(
                      builder: (context) {
                        final (a, b) = ratePairFor(table, from, primary);
                        return _PairRow(
                          from: a,
                          to: b,
                          rate: table.rate(a, b),
                          subtitle: ratePairSubtitle(
                            l,
                            table,
                            from,
                            primary,
                            offline: _offline,
                            now: now,
                          ),
                          onTap: () => _override(from, primary),
                        );
                      },
                    ),
                ],
              ),
            const SizedBox(height: VgSpace.s4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.tonalIcon(
                  onPressed: _busy ? null : () => _refresh(force: true),
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Symbols.refresh_rounded),
                  label: Text(l.ratesUpdateNow),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(VgSize.tapMin),
                  ),
                ),
              ),
            ),
            if (pairs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  VgSpace.s4 + VgSpace.s1,
                  VgSpace.s2,
                  VgSpace.s4 + VgSpace.s1,
                  0,
                ),
                child: Text(
                  l.ratesListedNote,
                  style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            const SizedBox(height: VgSpace.s2),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s2),
                child: TextButton.icon(
                  onPressed: _openSource,
                  icon: Icon(
                    Symbols.open_in_new_rounded,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  label: Text(
                    l.ratesSource,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "1 USD → **25.400 VND**" + "Tự động · cập nhật hôm nay" (mũi tên là icon vì
/// font không chắc có U+2192).
class _PairRow extends StatelessWidget {
  const _PairRow({
    required this.from,
    required this.to,
    required this.rate,
    required this.subtitle,
    required this.onTap,
  });

  final String from;
  final String to;
  final ExchangeRate? rate;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final value = rate == null
        ? '–'
        : formatRate(rate!.toDouble(), l.localeName);
    final style = VgType.bodyMd.copyWith(color: scheme.onSurface);
    final tabular = style.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: '${l.ratesPairLabel(from, value, to)}. $subtitle',
      button: true,
      excludeSemantics: true,
      onTap: onTap,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: VgSize.tapKey),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: VgSpace.s4,
              vertical: VgSpace.s2,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(
                        TextSpan(
                          style: style,
                          children: [
                            TextSpan(text: '1 $from '),
                            WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(
                                Symbols.arrow_right_alt_rounded,
                                size: 18,
                                color: scheme.onSurface,
                              ),
                            ),
                            const TextSpan(text: ' '),
                            TextSpan(text: '$value $to', style: tabular),
                          ],
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: VgType.bodySm.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: VgSpace.s2),
                Icon(
                  Symbols.chevron_right_rounded,
                  size: 20,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Banner ngoại tuyến (A001: card `surface` + icon + tiêu đề + lời giải thích).
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final vg = context.vg;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4, vertical: 14),
      decoration: BoxDecoration(
        color: vg.warningContainer,
        borderRadius: BorderRadius.circular(VgRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              Symbols.cloud_off_rounded,
              size: 20,
              color: vg.onWarningContainer,
            ),
          ),
          const SizedBox(width: VgSpace.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: VgType.bodyMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: vg.onWarningContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: VgType.bodySm.copyWith(color: vg.onWarningContainer),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ghi đè tỷ giá của một cặp (A001): xem tỷ giá tự động, tắt công tắc để dùng
/// tỷ giá của mình, xem trước số dư tài khoản đầu tiên dùng tiền tệ đó.
class _OverrideSheet extends ConsumerStatefulWidget {
  const _OverrideSheet({
    required this.from,
    required this.to,
    required this.table,
  });

  /// Tiền tệ của dữ liệu (ví dụ USD); [to] là Tiền tệ chính.
  final String from;
  final String to;
  final RateTable table;

  @override
  ConsumerState<_OverrideSheet> createState() => _OverrideSheetState();
}

class _OverrideSheetState extends ConsumerState<_OverrideSheet> {
  late final TextEditingController _controller = TextEditingController();
  late final bool _wasOverridden = _currentOverride != null;
  late bool _useAuto = !_wasOverridden;
  late final String _a;
  late final String _b;

  String? _error;
  bool _saving = false;
  Account? _previewAccount;
  int? _previewBalance;
  bool _filled = false;

  @override
  void initState() {
    super.initState();
    final pair = ratePairFor(widget.table, widget.from, widget.to);
    _a = pair.$1;
    _b = pair.$2;
    _loadPreview();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_filled) return;
    _filled = true;
    final rate = _currentOverride ?? _autoRate;
    if (rate != null) {
      _controller.text = formatRate(
        rate.toDouble(),
        Localizations.localeOf(context).languageCode,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Ghi đè đang có, quy về chiều hiển thị [_a] → [_b].
  ExchangeRate? get _currentOverride {
    final direct = widget.table.overrides['${widget.from}>${widget.to}'];
    final inverse = widget.table.overrides['${widget.to}>${widget.from}'];
    final logical = direct ?? inverse?.inverse;
    if (logical == null) return null;
    return _a == widget.from ? logical : logical.inverse;
  }

  /// Tỷ giá tự động (bỏ ghi đè) theo chiều hiển thị.
  ExchangeRate? get _autoRate => RateTable(
    base: widget.table.base,
    date: widget.table.date,
    rates: widget.table.rates,
  ).rate(_a, _b);

  /// Tỷ giá đang gõ, theo chiều hiển thị; null nếu sai.
  ExchangeRate? get _typed {
    final normalized = normalizeAmountInput(
      _controller.text,
      locale: Localizations.localeOf(context).languageCode,
    );
    if (normalized == null) return null;
    return ExchangeRate.tryParse(normalized);
  }

  /// Tỷ giá đang gõ, quy về chiều dữ liệu [widget.from] → [widget.to].
  ExchangeRate? get _typedLogical {
    final typed = _typed;
    if (typed == null) return null;
    return _a == widget.from ? typed : typed.inverse;
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

  Future<void> _save() async {
    if (_saving) return;
    final l = AppLocalizations.of(context);
    final settings = ref.read(settingsRepositoryProvider);
    if (_useAuto) {
      if (_wasOverridden) {
        _saving = true;
        await settings.clearRateOverride(widget.from, widget.to);
        await _recompute();
      }
      if (mounted) Navigator.pop(context);
      return;
    }
    final rate = _typed;
    if (rate == null) {
      setState(() => _error = l.exchangeRateInvalid);
      return;
    }
    _saving = true;
    await settings.setRateOverride(_a, _b, rate);
    await _recompute();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _restoreAuto() async {
    if (_saving) return;
    _saving = true;
    await ref
        .read(settingsRepositoryProvider)
        .clearRateOverride(widget.from, widget.to);
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
    final autoText = auto == null
        ? '–'
        : formatRate(auto.toDouble(), l.localeName);
    final now = ref.watch(clockProvider)();
    final autoMeta = widget.table.isFallback
        ? l.rateAutoValueBuiltIn(autoText)
        : l.rateAutoValue(autoText, ratesAgoLabel(l, widget.table, now));
    final previewAccount = _previewAccount;
    final previewBalance = _previewBalance;
    final typedLogical = _typedLogical;
    final previewConverted = typedLogical == null || previewBalance == null
        ? null
        : convertMinorUnits(
            previewBalance,
            typedLogical,
            fromDigits: currencyDecimalDigits(widget.from),
            toDigits: currencyDecimalDigits(widget.to),
          ).toInt();
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        VgSpace.s4 + VgSpace.s1,
        0,
        VgSpace.s4 + VgSpace.s1,
        VgSpace.s4 + viewPadding.bottom + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    header: true,
                    label: '$_a → $_b',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Text(_a, style: VgType.titleMd),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: VgSpace.s2,
                          ),
                          child: Icon(
                            Symbols.arrow_right_alt_rounded,
                            size: 20,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(_b, style: VgType.titleMd),
                      ],
                    ),
                  ),
                  const SizedBox(height: VgSpace.s4),
                  MergeSemantics(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.rateUseAuto,
                                style: VgType.bodyMd.copyWith(
                                  color: scheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                autoMeta,
                                style: VgType.bodySm.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: VgSpace.s3),
                        Switch(
                          value: _useAuto,
                          onChanged: (value) => setState(() {
                            _useAuto = value;
                            _error = null;
                          }),
                        ),
                      ],
                    ),
                  ),
                  if (!_useAuto) ...[
                    const SizedBox(height: VgSpace.s4 + VgSpace.s1),
                    _RateBox(
                      controller: _controller,
                      from: _a,
                      to: _b,
                      preview:
                          previewAccount == null ||
                              previewBalance == null ||
                              previewConverted == null
                          ? null
                          : l.ratesPreviewBalance(
                              accountLabel(l, previewAccount),
                              money(context, widget.from, previewBalance),
                              money(context, widget.to, previewConverted),
                            ),
                      error: _error,
                      onChanged: () => setState(() => _error = null),
                      onSubmitted: _save,
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: VgSpace.s4),
          if (_useAuto)
            FilledButton(onPressed: _saving ? null : _save, child: Text(l.done))
          else ...[
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(l.rateSave),
            ),
            if (_wasOverridden) ...[
              const SizedBox(height: VgSpace.s2),
              TextButton(
                onPressed: _saving ? null : _restoreAuto,
                child: Text(l.rateRestoreAuto),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// `amount-box`: "Tỷ giá của bạn · 1 USD =" với ô số lớn + tiền tệ, dòng xem
/// trước hoặc lỗi bên dưới.
class _RateBox extends StatelessWidget {
  const _RateBox({
    required this.controller,
    required this.from,
    required this.to,
    required this.preview,
    required this.error,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final String from;
  final String to;
  final String? preview;
  final String? error;
  final VoidCallback onChanged;
  final VoidCallback onSubmitted;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final label = l.rateYours(from);
    final number = VgType.titleLg.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: VgSpace.s4, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(VgRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                // Trình đọc màn hình đọc "Tỷ giá của bạn · 1 USD =" làm tên ô.
                child: Semantics(
                  label: label,
                  child: MediaQuery(
                    // Số lớn không phình quá 1,6 lần khi chữ hệ thống to.
                    data: MediaQuery.of(context).copyWith(
                      textScaler: MediaQuery.textScalerOf(context)
                          .clamp(maxScaleFactor: 1.6),
                    ),
                    child: TextField(
                      controller: controller,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]')),
                      ],
                      textInputAction: TextInputAction.done,
                      onChanged: (_) => onChanged(),
                      onSubmitted: (_) => onSubmitted(),
                      style: number,
                      cursorColor: scheme.primary,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: VgSpace.s1,
                        ),
                        hintText: '0',
                        hintStyle: number.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: VgSpace.s3),
              Text(to, style: VgType.titleSm.copyWith(color: scheme.onSurface)),
            ],
          ),
          if (error != null)
            Row(
              children: [
                Icon(Symbols.error_rounded, size: 14, color: scheme.error),
                const SizedBox(width: VgSpace.s1),
                Expanded(
                  child: Text(
                    error!,
                    style: VgType.bodySm.copyWith(color: scheme.error),
                  ),
                ),
              ],
            )
          else if (preview != null)
            Text(
              preview!,
              style: VgType.bodySm.copyWith(color: scheme.onSurfaceVariant),
            ),
        ],
      ),
    );
  }
}
