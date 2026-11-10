import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/currency_table.dart';
import '../../data/database.dart';
import '../../providers.dart';
import '../../ui/choice_sheet.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import '../lock/app_lock.dart';
import '../reminder/reminder_providers.dart';
import '../settings/currency_picker.dart';
import '../settings/data_actions.dart' show setupPin;

/// Màn chào (F-44), chỉ khi máy vừa cài mới (D-041), theo khung A001:
/// 1 Ngôn ngữ → 2 Chào mừng → 3 Tiền tệ chính → 4 Nhắc ghi sổ → 5 Khoá PIN →
/// màn chính.
///
/// Mỗi lựa chọn được lưu ngay khi chạm. "Bỏ qua" (bước 2–5) vào app luôn: bước
/// chưa chọn giữ mặc định (English, USD, Nhắc tắt và không xin quyền, không
/// PIN). Back của hệ thống lùi một bước. Xong hoặc Bỏ qua thì không hiện lại.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const steps = 5;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _language = 0,
      _welcome = 1,
      _currency = 2,
      _reminder = 3,
      _pin = 4;

  int _step = _language;
  bool _busy = false;

  void _go(int step) => setState(() => _step = step);

  /// Xong / Bỏ qua: xoá cờ cài mới → router đưa về màn chính.
  Future<void> _finish() async {
    if (_busy) return;
    setState(() => _busy = true);
    await ref.read(settingsRepositoryProvider).finishOnboarding();
  }

  Future<void> _setCurrency(String code) async {
    final settings = ref.read(settingsRepositoryProvider);
    await settings.setCurrency(code);
    // Cài mới: chỉ có tài khoản Tiền mặt, chưa có khoản nào → tài khoản lấy
    // luôn tiền tệ vừa chọn (D-041), không có dòng "≈" thừa.
    final db = ref.read(databaseProvider);
    await db
        .update(db.accounts)
        .write(
          AccountsCompanion(
            currency: Value(code),
            initialCurrency: Value(code),
          ),
        );
  }

  Future<void> _turnOnReminder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final l = AppLocalizations.of(context);
      final scheduler = ref.read(reminderSchedulerProvider);
      final granted = await scheduler.requestPermission();
      if (granted) {
        await ref.read(settingsRepositoryProvider).setReminderEnabled(true);
      } else {
        showVgSnackBar(
          l.reminderDenied,
          actionLabel: l.reminderOpenSettings,
          onAction: scheduler.openSystemSettings,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) _go(_pin);
  }

  Future<void> _pickTime(TimeOfDay current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: AppLocalizations.of(context).reminderTime,
    );
    if (picked != null && picked != current) {
      await ref.read(settingsRepositoryProvider).setReminderTime(picked);
    }
  }

  Future<void> _setPin() async {
    await setupPin(context, ref);
    if (!mounted) return;
    // Hủy giữa chừng (Back) thì PIN chưa bật: ở lại bước này.
    if (await ref.read(pinEnabledProvider.future)) await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final Widget body = switch (_step) {
      _language => _languageStep(l),
      _welcome => _welcomeStep(l),
      _currency => _currencyStep(l),
      _reminder => _reminderStep(l),
      _ => _pinStep(l),
    };
    return PopScope(
      canPop: _step == _language,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _go(_step - 1);
      },
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: KeyedSubtree(key: ValueKey(_step), child: body),
        ),
      ),
    );
  }

  Widget _languageStep(AppLocalizations l) {
    final code = ref.watch(localeCodeProvider).value == 'vi' ? 'vi' : 'en';
    return _StepScaffold(
      step: _language + 1,
      title: l.onboardingLanguageTitle,
      hint: l.onboardingLanguageHint,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (value, label) in const [
            ('en', 'English'),
            ('vi', 'Tiếng Việt'),
          ])
            _Row(
              key: ValueKey('onboarding-lang-$value'),
              label: label,
              selected: value == code,
              onTap: () =>
                  ref.read(settingsRepositoryProvider).setLocaleCode(value),
            ),
        ],
      ),
      primary: _Action(l.onboardingContinue, () => _go(_welcome)),
    );
  }

  Widget _welcomeStep(AppLocalizations l) => _StepScaffold(
    step: _welcome + 1,
    onSkip: _finish,
    icon: Symbols.account_balance_wallet_rounded,
    title: l.onboardingWelcomeTitle,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Benefit(
          icon: Symbols.touch_app_rounded,
          title: l.onboardingBenefitFast,
          body: l.onboardingBenefitFastSub,
        ),
        _Benefit(
          icon: Symbols.donut_large_rounded,
          title: l.onboardingBenefitClear,
          body: l.onboardingBenefitClearSub,
        ),
        _Benefit(
          icon: Symbols.shield_lock_rounded,
          title: l.onboardingBenefitPrivate,
          body: l.onboardingBenefitPrivateSub,
        ),
      ],
    ),
    primary: _Action(l.onboardingStart, () => _go(_currency)),
  );

  Widget _currencyStep(AppLocalizations l) {
    final current = ref.watch(currencyProvider).value ?? 'USD';
    final lang = Localizations.localeOf(context).languageCode;
    // USD (mặc định toàn cầu, S-90) và VND luôn có; tiền tệ khác đã chọn hiện
    // thêm một dòng.
    final codes = [
      'USD',
      'VND',
      if (current != 'USD' && current != 'VND') current,
    ];
    return _StepScaffold(
      step: _currency + 1,
      onSkip: _finish,
      title: l.onboardingCurrencyTitle,
      hint: l.onboardingCurrencyHint,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final code in codes)
            _Row(
              key: ValueKey('onboarding-currency-$code'),
              label:
                  '${currencyInfo(code)?.name(lang) ?? code} · '
                  '${currencyCodeLabel(code)}',
              selected: code == current,
              onTap: () => _setCurrency(code),
            ),
          _Row(
            key: const ValueKey('onboarding-currency-other'),
            icon: Symbols.search_rounded,
            label: l.onboardingOtherCurrency,
            selected: false,
            onTap: () async {
              final code = await showCurrencyPicker(context, current);
              if (code != null) await _setCurrency(code);
            },
          ),
        ],
      ),
      primary: _Action(l.onboardingContinue, () => _go(_reminder)),
    );
  }

  Widget _reminderStep(AppLocalizations l) {
    final time =
        ref.watch(reminderTimeProvider).value ??
        const TimeOfDay(hour: 20, minute: 0);
    return _StepScaffold(
      step: _reminder + 1,
      onSkip: _finish,
      icon: Symbols.notifications_rounded,
      title: l.onboardingReminderTitle,
      hint: l.onboardingReminderHint,
      body: ListTile(
        key: const Key('onboarding-reminder-time'),
        contentPadding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
        leading: const Icon(Symbols.schedule_rounded),
        title: Text(l.reminderTime),
        trailing: Text(
          time.format(context),
          style: VgType.titleSm.copyWith(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        onTap: () => _pickTime(time),
      ),
      primary: _Action(l.onboardingReminderOn, _turnOnReminder),
      secondary: _Action(l.onboardingLater, () => _go(_pin)),
    );
  }

  Widget _pinStep(AppLocalizations l) => _StepScaffold(
    step: _pin + 1,
    onSkip: _finish,
    icon: Symbols.lock_rounded,
    title: l.onboardingPinTitle,
    hint: l.onboardingPinHint,
    primary: _Action(l.onboardingPinSet, _setPin),
    secondary: _Action(l.onboardingLater, _finish),
  );
}

class _Action {
  const _Action(this.label, this.onPressed);

  final String label;
  final VoidCallback onPressed;
}

/// Khung một bước: "Bước n/5" + "Bỏ qua" ở trên; biểu tượng, tiêu đề, giải
/// thích, nội dung cuộn được; nút chính (và nút phụ) ghim ở đáy.
class _StepScaffold extends StatelessWidget {
  const _StepScaffold({
    required this.step,
    required this.title,
    required this.primary,
    this.hint,
    this.icon,
    this.body,
    this.secondary,
    this.onSkip,
  });

  final int step;
  final String title;
  final String? hint;
  final IconData? icon;
  final Widget? body;
  final _Action primary;
  final _Action? secondary;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s6,
              VgSpace.s2,
              VgSpace.s2,
              0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l.onboardingStep(step, OnboardingScreen.steps),
                    style: VgType.labelMd.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                // Giữ chiều cao hàng khi không có "Bỏ qua" (bước 1).
                SizedBox(
                  height: VgSize.tapMin,
                  child: onSkip == null
                      ? null
                      : TextButton(
                          key: const Key('onboarding-skip'),
                          onPressed: onSkip,
                          child: Text(l.onboardingSkip),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, VgSpace.s6, 0, VgSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: VgSpace.s6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (icon != null) ...[
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: scheme.primaryContainer,
                              borderRadius: BorderRadius.circular(VgRadius.md),
                            ),
                            child: Icon(
                              icon,
                              size: 28,
                              color: scheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(height: VgSpace.s4),
                        ],
                        Semantics(
                          header: true,
                          child: Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        if (hint != null) ...[
                          const SizedBox(height: VgSpace.s2),
                          Text(
                            hint!,
                            style: VgType.bodyMd.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: VgSpace.s6),
                      ],
                    ),
                  ),
                  ?body,
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              VgSpace.s6,
              VgSpace.s2,
              VgSpace.s6,
              VgSpace.s4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton(
                  key: const Key('onboarding-primary'),
                  onPressed: primary.onPressed,
                  child: Text(primary.label),
                ),
                if (secondary != null) ...[
                  const SizedBox(height: VgSpace.s2),
                  TextButton(
                    key: const Key('onboarding-secondary'),
                    onPressed: secondary!.onPressed,
                    child: Text(secondary!.label),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  const _Benefit({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          VgSpace.s6,
          0,
          VgSpace.s6,
          VgSpace.s4,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(width: VgSpace.s4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: VgType.titleSm.copyWith(color: scheme.onSurface),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    body,
                    style: VgType.bodySm.copyWith(
                      color: scheme.onSurfaceVariant,
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

/// Dòng chọn của Màn chào: [ChoiceRow] thụt thêm khi chưa chọn để chữ của mọi
/// dòng thẳng hàng (dòng đang chọn đã tự thụt vào trong viên nền).
class _Row extends StatelessWidget {
  const _Row({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(horizontal: selected ? 0 : VgSpace.s3),
    child: ChoiceRow(
      label: label,
      selected: selected,
      onTap: onTap,
      icon: icon,
    ),
  );
}
