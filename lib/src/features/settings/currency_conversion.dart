import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency.dart';
import '../../data/dates.dart';
import '../../data/exchange_rate.dart';
import '../../data/money.dart';
import '../../data/settings_repository.dart';
import '../../providers.dart';
import '../../ui/dialog.dart';
import '../../ui/format.dart';
import '../../ui/hint.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';

export '../../providers.dart' show exchangeRateSourceProvider;

/// Tỉ giá để hiển thị: tối đa 6 chữ số có nghĩa, theo ngôn ngữ
/// ("0,0000385", "25.974" ở vi).
String formatRate(double value, String locale) {
  final f = NumberFormat.decimalPattern(locale)
    ..significantDigitsInUse = true
    ..minimumSignificantDigits = 1
    ..maximumSignificantDigits = 6;
  return f.format(value);
}

/// Đổi tiền tệ [from] → [to] (AC-21, D-025): hộp thoại tải tỉ giá, xác nhận
/// (hoặc nhập tay khi lỗi), rồi quy đổi mọi số tiền trong một giao dịch.
/// Hủy ở bất kỳ bước nào thì không đổi gì.
Future<void> changeCurrencyWithConversion(
  BuildContext context,
  WidgetRef ref,
  String from,
  String to,
) async {
  final l = AppLocalizations.of(context);
  final db = ref.read(databaseProvider);
  final example = await conversionExampleAmount(db);
  if (!context.mounted) return;
  final rate = await showDialog<ExchangeRate>(
    context: context,
    barrierDismissible: false,
    builder: (_) => CurrencyConversionDialog(
      from: from,
      to: to,
      example: example,
      source: ref.read(exchangeRateSourceProvider),
      settings: ref.read(settingsRepositoryProvider),
      today: ref.read(clockProvider)(),
    ),
  );
  if (rate == null) return;
  try {
    await convertCurrency(db, to, rate);
    showMessage(l.currencyConverted(to));
  } on CurrencyConversionOverflow {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => VgDialog(
        icon: Symbols.error_rounded,
        title: l.currencyConvertTooLargeTitle,
        body: l.currencyConvertTooLargeBody,
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.currencyConvertOk),
          ),
        ],
      ),
    );
  } catch (_) {
    showMessage(l.currencyConvertFailed);
  }
}

enum _Stage { loading, confirm, manual }

/// Hộp thoại quy đổi: đang tải → xác nhận "1 cũ = X mới", nguồn và ngày, ví
/// dụ, cảnh báo → Quy đổi / Hủy. Lỗi mạng hoặc thiếu tỉ giá cho cặp → báo rõ
/// và ô nhập tỉ giá tay (điền sẵn tỉ giá gần nhất nếu có). Trả về tỉ giá
/// "1 [from] = ? [to]" người dùng đã xác nhận, hoặc null khi hủy.
class CurrencyConversionDialog extends StatefulWidget {
  const CurrencyConversionDialog({
    super.key,
    required this.from,
    required this.to,
    required this.example,
    required this.source,
    required this.settings,
    required this.today,
  });

  final String from;
  final String to;

  /// Số tiền ví dụ ([conversionExampleAmount]: số đang hiện, đơn vị nhỏ nhất
  /// của [from], và số chính xác micro); null thì lấy 100 đơn vị lớn.
  final ({int minor, int exact})? example;
  final ExchangeRateSource source;
  final SettingsRepository settings;
  final DateTime today;

  @override
  State<CurrencyConversionDialog> createState() =>
      _CurrencyConversionDialogState();
}

class _CurrencyConversionDialogState extends State<CurrencyConversionDialog> {
  _Stage _stage = _Stage.loading;

  // Bước xác nhận.
  ExchangeRate? _rate;
  String? _rateDate;
  bool _manualRate = false;

  // Bước nhập tay.
  final _field = TextEditingController();
  ExchangeRateError? _error;
  bool _missingPair = false;
  bool _inverse = false;
  String? _fieldError;
  String? _prefilledDate;

  bool _busy = false;

  String get _locale => Localizations.localeOf(context).languageCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _stage = _Stage.loading);
    try {
      final table = await widget.source.fetch();
      try {
        await widget.settings.setRateTable(table);
      } catch (_) {
        // Lưu cache hỏng không chặn việc đổi tiền tệ.
      }
      final rate = table.rate(widget.from, widget.to);
      if (!mounted) return;
      if (rate == null) {
        await _toManual(missingPair: true);
      } else {
        setState(() {
          _rate = rate;
          _rateDate = table.date;
          _manualRate = false;
          _stage = _Stage.confirm;
        });
      }
    } on ExchangeRateException catch (e) {
      await _toManual(error: e.kind);
    } catch (_) {
      await _toManual(error: ExchangeRateError.unavailable);
    }
  }

  /// Sang bước nhập tay. [prefill] có sẵn (Dùng tỉ giá khác) thì điền nó;
  /// không thì tìm tỉ giá gần nhất trong cache (bảng tải về hoặc lần nhập tay).
  Future<void> _toManual({
    ExchangeRateError? error,
    bool missingPair = false,
    ({ExchangeRate rate, String date})? prefill,
  }) async {
    var candidate = prefill;
    if (candidate == null) {
      try {
        final table = await widget.settings.readRateTable();
        final fromTable = table?.rate(widget.from, widget.to);
        final manual = await widget.settings.readManualRate(
          widget.from,
          widget.to,
        );
        if (fromTable != null) candidate = (rate: fromTable, date: table!.date);
        if (manual != null &&
            (candidate == null || manual.date.compareTo(candidate.date) > 0)) {
          candidate = manual;
        }
      } catch (_) {
        candidate = null;
      }
    }
    if (!mounted) return;
    setState(() {
      _stage = _Stage.manual;
      _error = error;
      _missingPair = missingPair;
      _fieldError = null;
      _prefilledDate = candidate?.date;
      if (candidate != null) {
        // Tỉ giá < 1 (VND → USD) đọc khó: hiện chiều ngược lại.
        _inverse = candidate.rate.toDouble() < 1;
        final shown = _inverse ? candidate.rate.inverse : candidate.rate;
        _field.text = formatRate(shown.toDouble(), _locale);
      } else {
        _inverse = false;
        _field.clear();
      }
    });
  }

  ExchangeRate? _parseField() {
    final normalized = normalizeAmountInput(_field.text, locale: _locale);
    final rate = normalized == null ? null : ExchangeRate.tryParse(normalized);
    if (rate == null) return null;
    return _inverse ? rate.inverse : rate;
  }

  void _swap() {
    final current = _parseField();
    setState(() {
      _inverse = !_inverse;
      _fieldError = null;
      if (current != null) {
        final shown = _inverse ? current.inverse : current;
        _field.text = formatRate(shown.toDouble(), _locale);
      }
    });
  }

  void _continueManual() {
    final rate = _parseField();
    if (rate == null) {
      setState(
        () => _fieldError = AppLocalizations.of(context).exchangeRateInvalid,
      );
      return;
    }
    setState(() {
      _rate = rate;
      _rateDate = dateKey(widget.today);
      _manualRate = true;
      _stage = _Stage.confirm;
    });
  }

  Future<void> _confirm() async {
    final rate = _rate!;
    setState(() => _busy = true);
    if (_manualRate) {
      try {
        await widget.settings.setManualRate(
          widget.from,
          widget.to,
          rate,
          _rateDate!,
        );
      } catch (_) {
        // Không lưu được tỉ giá gợi ý lần sau: vẫn quy đổi.
      }
    }
    if (mounted) Navigator.pop(context, rate);
  }

  Future<void> _openSource() async {
    final l = AppLocalizations.of(context);
    bool ok;
    try {
      ok = await launchUrl(
        widget.source.homepage,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      ok = false;
    }
    if (!ok) showMessage(l.linkOpenFailed(widget.source.homepage.host));
  }

  String _date(String ymd) => shortDate(context, parseDateKey(ymd));

  @override
  Widget build(BuildContext context) => switch (_stage) {
    _Stage.loading => _buildLoading(context),
    _Stage.confirm => _buildConfirm(context),
    _Stage.manual => _buildManual(context),
  };

  Widget _buildLoading(BuildContext context) {
    final l = AppLocalizations.of(context);
    return VgDialog(
      icon: Symbols.currency_exchange_rounded,
      tone: VgDialogTone.neutral,
      title: l.currencyConvertTitle(widget.to),
      content: [
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
              const SizedBox(width: VgSpace.s3),
              Expanded(
                child: Text(l.exchangeRateLoading, style: VgType.bodyMd),
              ),
            ],
          ),
        ),
      ],
      actions: [VgDialog.cancelButton(context)],
    );
  }

  Widget _buildConfirm(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final rate = _rate!;
    final from = widget.from;
    final to = widget.to;
    const digits = TextStyle(fontFeatures: [FontFeature.tabularFigures()]);
    final fromDigits = currencyDecimalDigits(from);
    final toDigits = currencyDecimalDigits(to);
    final example = widget.example?.minor ?? 100 * pow(10, fromDigits).toInt();
    // Tính như khi đổi thật (D-029): từ số chính xác, làm tròn về tiền mới.
    final converted = convertExact(
      widget.example?.exact ?? example * microPerMinor(fromDigits),
      rate,
      toDigits: toDigits,
    ).minor;
    final after = converted > BigInt.from(1 << 52) ? null : converted.toInt();
    final muted = VgType.bodySm.copyWith(color: scheme.onSurfaceVariant);
    return VgDialog(
      icon: Symbols.currency_exchange_rounded,
      tone: VgDialogTone.neutral,
      title: l.currencyConvertTitle(to),
      content: [
        Text(
          l.exchangeRatePair(from, formatRate(rate.toDouble(), _locale), to),
          style: Theme.of(context).textTheme.titleMedium!.merge(digits),
        ),
        Text(
          l.exchangeRatePair(
            to,
            formatRate(rate.inverse.toDouble(), _locale),
            from,
          ),
          style: muted.merge(digits),
        ),
        const SizedBox(height: VgSpace.s2),
        if (_manualRate)
          Text(l.exchangeRateManualSource, style: muted)
        else ...[
          Text(l.exchangeRateDate(_date(_rateDate!)), style: muted),
          // Ghi công nguồn kèm link (điều khoản ExchangeRate-API Open Access).
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                foregroundColor: scheme.onPrimaryContainer,
                padding: EdgeInsets.zero,
                minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
              ),
              onPressed: _openSource,
              icon: const Icon(Symbols.open_in_new_rounded, size: 18),
              label: Text(widget.source.attribution),
            ),
          ),
        ],
        if (after != null) ...[
          const SizedBox(height: VgSpace.s2),
          Text(
            l.currencyConvertExample(
              money(context, from, example),
              money(context, to, after),
            ),
            style: VgType.bodyMd.merge(digits),
          ),
        ],
        const SizedBox(height: VgSpace.s3),
        VgHint(l.currencyConvertWarning(to), icon: Symbols.warning_rounded),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            style: TextButton.styleFrom(
              foregroundColor: scheme.onPrimaryContainer,
              padding: EdgeInsets.zero,
              minimumSize: const Size(VgSize.tapMin, VgSize.tapMin),
            ),
            onPressed: _busy
                ? null
                : () => _toManual(prefill: (rate: rate, date: _rateDate!)),
            child: Text(l.exchangeRateUseOther),
          ),
        ),
      ],
      actions: [
        VgDialog.cancelButton(context, enabled: !_busy),
        FilledButton(
          onPressed: _busy ? null : _confirm,
          child: Text(l.currencyConvertAction),
        ),
      ],
    );
  }

  Widget _buildManual(BuildContext context) {
    final l = AppLocalizations.of(context);
    final failed = _error != null || _missingPair;
    final body = _missingPair
        ? l.exchangeRateMissingPairBody(widget.from, widget.to)
        : switch (_error) {
            ExchangeRateError.offline => l.exchangeRateOfflineBody,
            ExchangeRateError.unavailable => l.exchangeRateUnavailableBody,
            null => null,
          };
    final (a, b) = _inverse
        ? (widget.to, widget.from)
        : (widget.from, widget.to);
    return VgDialog(
      icon: failed
          ? Symbols.cloud_off_rounded
          : Symbols.currency_exchange_rounded,
      tone: VgDialogTone.neutral,
      title: failed ? l.exchangeRateErrorTitle : l.exchangeRateManualTitle,
      body: body,
      content: [
        TextField(
          controller: _field,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          style: const TextStyle(fontFeatures: [FontFeature.tabularFigures()]),
          onSubmitted: (_) => _continueManual(),
          decoration: InputDecoration(
            labelText: l.exchangeRateFieldLabel(a, b),
            errorText: _fieldError,
            errorMaxLines: 3,
            suffixIcon: IconButton(
              tooltip: l.exchangeRateSwap,
              onPressed: _swap,
              icon: const Icon(Symbols.swap_horiz_rounded),
            ),
          ),
        ),
        if (_prefilledDate != null)
          Padding(
            padding: const EdgeInsets.only(top: VgSpace.s2),
            child: VgHint(l.exchangeRatePrefilled(_date(_prefilledDate!))),
          ),
      ],
      actions: [
        VgDialog.cancelButton(context),
        if (failed && !_missingPair)
          TextButton(
            // `primary` trên nền hộp thoại chỉ 4,06:1 → tông xanh đậm hơn.
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            onPressed: _load,
            child: Text(l.exchangeRateRetry),
          ),
        FilledButton(
          onPressed: _continueManual,
          child: Text(l.exchangeRateContinue),
        ),
      ],
    );
  }
}
