import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vigon/l10n/app_localizations.dart';
import 'package:vigon/src/data/backup.dart';
import 'package:vigon/src/features/budget_alert/budget_alerts.dart';
import 'package:vigon/src/features/budget_alert/budget_status.dart';
import 'package:vigon/src/data/database.dart';
import 'package:vigon/src/features/budget_alert/budget_alert_settings.dart';
import 'package:vigon/src/features/budget_alert/budget_alert_text.dart';
import 'package:vigon/src/features/budget_alert/budget_notifier.dart';

import '../helpers.dart' show plain;

import 'package:vigon/src/data/money.dart';

class _FakeNotifier implements BudgetNotifier {
  final shown = <(BudgetAlert, BudgetAlertContent)>[];

  @override
  Future<void> show(BudgetAlert alert, BudgetAlertContent content) async =>
      shown.add((alert, content));
}

BudgetAlertContent _content(BudgetAlert a) => BudgetAlertContent(
  title: 'Vigon',
  body: '${a.id} ${a.percent}',
  channelName: 'c',
  channelDescription: 'd',
);

void main() {
  group('trạng thái ngân sách đúng ở biên (AC-111)', () {
    BudgetState at(int spent, {int limit = 5000000, int warn = 80}) =>
        budgetStateOf(spent: spent, limit: limit, warnPercent: warn);

    test('hạn mức 5.000.000, ngưỡng 80%', () {
      expect(at(0), BudgetState.normal);
      expect(at(3999999), BudgetState.normal);
      expect(at(4000000), BudgetState.almostOver);
      expect(at(4100000), BudgetState.almostOver);
      expect(at(5000000), BudgetState.almostOver);
      expect(at(5000001), BudgetState.over);
    });

    test('ngưỡng khác: 50% và 95%', () {
      expect(at(2499999, warn: 50), BudgetState.normal);
      expect(at(2500000, warn: 50), BudgetState.almostOver);
      expect(at(4749999, warn: 95), BudgetState.normal);
      expect(at(4750000, warn: 95), BudgetState.almostOver);
    });

    test('hạn mức nhỏ vẫn đúng bằng số nguyên', () {
      // 80% của 3 là 2,4: chi 2 chưa tới, chi 3 (đúng hạn mức) là sắp vượt.
      expect(at(2, limit: 3), BudgetState.normal);
      expect(at(3, limit: 3), BudgetState.almostOver);
      expect(at(4, limit: 3), BudgetState.over);
      expect(at(1, limit: 1), BudgetState.almostOver);
    });

    test('hạn mức chưa đặt hoặc ≤ 0 luôn bình thường', () {
      expect(at(100, limit: 0), BudgetState.normal);
      expect(at(100, limit: -5), BudgetState.normal);
    });

    test('phần trăm đã dùng làm tròn xuống', () {
      expect(budgetUsedPercent(spent: 4100000, limit: 5000000), 82);
      expect(budgetUsedPercent(spent: 4999999, limit: 5000000), 99);
      expect(budgetUsedPercent(spent: 5000000, limit: 5000000), 100);
      expect(budgetUsedPercent(spent: 0, limit: 5000000), 0);
      expect(budgetUsedPercent(spent: 5, limit: 0), 0);
    });

    test('ngưỡng hợp lệ: mặc định 80, kẹp 50–95, bước 5', () {
      expect(normalizeBudgetWarnPercent(null), 80);
      expect(normalizeBudgetWarnPercent(10), 50);
      expect(normalizeBudgetWarnPercent(100), 95);
      expect(normalizeBudgetWarnPercent(83), 85);
      expect(normalizeBudgetWarnPercent(82), 80);
      expect(budgetWarnPercentChoices, [
        50, 55, 60, 65, 70, 75, 80, 85, 90, 95, //
      ]);
    });

    test('mốc đã chạm: ngưỡng, rồi 100% khi đã chi ≥ hạn mức', () {
      Set<BudgetMilestone> m(int spent) =>
          budgetMilestonesReached(spent: spent, limit: 5000000);
      expect(m(3999999), isEmpty);
      expect(m(4000000), {BudgetMilestone.threshold});
      expect(m(4999999), {BudgetMilestone.threshold});
      expect(m(5000000), {BudgetMilestone.threshold, BudgetMilestone.full});
    });
  });

  group('lên kế hoạch thông báo (AC-112)', () {
    const month = '2026-11-01';
    BudgetAlertInput monthly(int spent, {int limit = 5000000}) =>
        BudgetAlertInput(id: monthlyBudgetId, limit: limit, spent: spent);

    BudgetAlertState baseline([List<BudgetAlertInput>? budgets]) =>
        planBudgetAlerts(
          previous: null,
          month: month,
          warnPercent: 80,
          budgets: budgets ?? [monthly(0)],
        ).state;

    test('mới bật: không gửi gì dù đang vượt, chỉ ghi nhận', () {
      final plan = planBudgetAlerts(
        previous: null,
        month: month,
        warnPercent: 80,
        budgets: [monthly(6000000)],
      );
      expect(plan.alerts, isEmpty);
      expect(plan.state.done, isNotEmpty);
    });

    test('mỗi mốc đúng một lần: ngưỡng rồi 100%, sau đó im lặng', () {
      var state = baseline();
      var plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(3999999)],
      );
      expect(plan.alerts, isEmpty);
      state = plan.state;

      plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(4000000)],
      );
      expect(plan.alerts.map((a) => (a.milestone, a.percent)), [
        (BudgetMilestone.threshold, 80),
      ]);
      state = plan.state;

      // Chi thêm vẫn dưới hạn mức: không báo lại.
      plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(4900000)],
      );
      expect(plan.alerts, isEmpty);
      state = plan.state;

      plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(5000000)],
      );
      expect(plan.alerts.map((a) => (a.milestone, a.percent)), [
        (BudgetMilestone.full, 100),
      ]);
      state = plan.state;

      plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(9000000)],
      );
      expect(plan.alerts, isEmpty);
    });

    test('giảm xuống rồi lên lại trong tháng không báo lại', () {
      var state = baseline();
      // Số đã chi → số thông báo gửi ở bước đó.
      const steps = [
        (4500000, 1), // chạm ngưỡng
        (1000000, 0), // xóa bớt
        (4500000, 0), // lên lại: không báo lại ngưỡng
        (5200000, 1), // chạm 100%
        (100, 0),
        (6000000, 0), // lên lại: không báo lại
      ];
      for (final (spent, count) in steps) {
        final plan = planBudgetAlerts(
          previous: state,
          month: month,
          warnPercent: 80,
          budgets: [monthly(spent)],
        );
        state = plan.state;
        expect(plan.alerts, hasLength(count), reason: 'đã chi $spent');
      }
      expect(state.done, hasLength(2));
    });

    test('một khoản nhảy qua cả hai mốc: một thông báo, ở 100%', () {
      final plan = planBudgetAlerts(
        previous: baseline(),
        month: month,
        warnPercent: 80,
        budgets: [monthly(7000000)],
      );
      expect(plan.alerts, hasLength(1));
      expect(plan.alerts.single.milestone, BudgetMilestone.full);
      expect(plan.alerts.single.percent, 100);
      // Mốc ngưỡng cũng đã tính là báo: không gửi thêm sau đó.
      final again = planBudgetAlerts(
        previous: plan.state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(7500000)],
      );
      expect(again.alerts, isEmpty);
    });

    test('sang tháng mới đặt lại', () {
      var state = baseline();
      state = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(5000000)],
      ).state;
      final next = planBudgetAlerts(
        previous: state,
        month: '2026-12-01',
        warnPercent: 80,
        budgets: [monthly(4000000)],
      );
      expect(next.alerts.single.milestone, BudgetMilestone.threshold);
      expect(next.state.month, '2026-12-01');
    });

    test('đổi hạn mức hoặc ngưỡng: không báo (không phải khoản làm vượt)', () {
      final state = baseline();
      final lowerLimit = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(4500000, limit: 4000000)],
      );
      expect(lowerLimit.alerts, isEmpty);
      final lowerWarn = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 50,
        budgets: [monthly(3000000)],
      );
      expect(lowerWarn.alerts, isEmpty);
      // Sau khi đã ghi nhận, mốc cao hơn vẫn báo được.
      final later = planBudgetAlerts(
        previous: lowerLimit.state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(4000000, limit: 4000000)],
      );
      expect(later.alerts, isEmpty); // đã được ghi nhận ở lần đổi hạn mức
      final more = planBudgetAlerts(
        previous: lowerLimit.state,
        month: month,
        warnPercent: 80,
        budgets: [monthly(4500000, limit: 4000000)],
      );
      expect(more.alerts, isEmpty);
    });

    test('ngân sách danh mục độc lập với ngân sách tháng và với nhau', () {
      final a = BudgetAlertInput(
        id: categoryBudgetId(1),
        limit: 1000,
        spent: 0,
        categoryId: 1,
      );
      final b = BudgetAlertInput(
        id: categoryBudgetId(2),
        limit: 1000,
        spent: 0,
        categoryId: 2,
      );
      final state = baseline([monthly(0), a, b]);
      final plan = planBudgetAlerts(
        previous: state,
        month: month,
        warnPercent: 80,
        budgets: [
          monthly(900000),
          BudgetAlertInput(
            id: categoryBudgetId(1),
            limit: 1000,
            spent: 800,
            categoryId: 1,
          ),
          b,
        ],
      );
      expect(plan.alerts.map((x) => x.id), [categoryBudgetId(1)]);
    });
  });

  group('BudgetAlertMonitor lưu trạng thái giữa các lần chạy', () {
    late AppDatabase db;
    late BudgetAlertSettings settings;
    late _FakeNotifier notifier;
    late BudgetAlertMonitor monitor;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = BudgetAlertSettings(db);
      notifier = _FakeNotifier();
      monitor = BudgetAlertMonitor(settings, notifier);
    });
    tearDown(() => db.close());

    Future<void> eval(int spent, {String month = '2026-11-01'}) =>
        monitor.evaluate(
          month: month,
          warnPercent: 80,
          budgets: [
            BudgetAlertInput(id: monthlyBudgetId, limit: 5000000, spent: spent),
          ],
          contentFor: _content,
        );

    test('lần đầu ghi nhận, lần sau báo mỗi mốc một lần', () async {
      await eval(0);
      await eval(4000000);
      await eval(3000000);
      await eval(4000000);
      await eval(5000000);
      await eval(1000000);
      await eval(5000001);
      expect(notifier.shown.map((s) => s.$1.percent), [80, 100]);
    });

    test(
      'tắt công tắc xóa trạng thái; bật lại không báo mốc đang có',
      () async {
        await eval(0);
        await eval(4000000);
        expect(notifier.shown, hasLength(1));
        await monitor.disable();
        expect(await settings.readState(), isNull);
        await eval(4500000);
        expect(notifier.shown, hasLength(1));
      },
    );

    test('trạng thái sống sót khi mở lại app (monitor mới)', () async {
      await eval(0);
      await eval(4000000);
      final again = BudgetAlertMonitor(settings, notifier);
      await again.evaluate(
        month: '2026-11-01',
        warnPercent: 80,
        budgets: [
          const BudgetAlertInput(
            id: monthlyBudgetId,
            limit: 5000000,
            spent: 4200000,
          ),
        ],
        contentFor: _content,
      );
      expect(notifier.shown, hasLength(1));
    });

    test('các lần gọi chồng nhau vẫn tuần tự, chỉ một thông báo', () async {
      await eval(0);
      await Future.wait([eval(4000000), eval(4000000), eval(4100000)]);
      expect(notifier.shown, hasLength(1));
    });

    test('trạng thái hỏng thì coi như chưa có, không ném lỗi', () async {
      await settings.writeState('không phải json');
      await eval(4500000);
      expect(notifier.shown, isEmpty);
      expect(BudgetAlertState.tryParse(await settings.readState()), isNotNull);
    });
  });

  group('cài đặt', () {
    late AppDatabase db;
    late BudgetAlertSettings settings;
    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = BudgetAlertSettings(db);
    });
    tearDown(() => db.close());

    test(
      'ngưỡng mặc định 80, lưu được, giá trị lạ được đưa về hợp lệ',
      () async {
        expect(await settings.readThreshold(), 80);
        await settings.setThreshold(65);
        expect(await settings.readThreshold(), 65);
        await settings.setThreshold(99);
        expect(await settings.readThreshold(), 95);
        expect(await settings.watchThreshold().first, 95);
      },
    );

    test('công tắc thông báo mặc định tắt', () async {
      expect(await settings.readEnabled(), isFalse);
      await settings.setEnabled(true);
      expect(await settings.readEnabled(), isTrue);
      await settings.setEnabled(false);
      expect(await settings.readEnabled(), isFalse);
    });

    test(
      'sao lưu: ngưỡng đi theo file; công tắc và mốc đã báo thì không',
      () async {
        await settings.setThreshold(70);
        await settings.setEnabled(true);
        await settings.writeState('{"month":"x","sig":"y","done":[]}');
        final json = await exportBackup(db, now: DateTime(2026, 11, 6));
        expect(json, contains('budgetAlertThreshold'));
        expect(json, isNot(contains('budgetAlertEnabled')));
        expect(json, isNot(contains('budgetAlertState')));
      },
    );
  });

  group('nội dung thông báo không có số tiền (AC-113)', () {
    final monthStart = DateTime(2026, 11, 1);
    final monthEnd = DateTime(2026, 11, 30);
    final alerts = [
      const BudgetAlert(
        id: monthlyBudgetId,
        milestone: BudgetMilestone.threshold,
        percent: 80,
      ),
      const BudgetAlert(
        id: monthlyBudgetId,
        milestone: BudgetMilestone.full,
        percent: 100,
      ),
      const BudgetAlert(
        id: 'cat1',
        milestone: BudgetMilestone.full,
        percent: 100,
        categoryId: 1,
      ),
      const BudgetAlert(
        id: 'cat1',
        milestone: BudgetMilestone.threshold,
        percent: 85,
        categoryId: 1,
      ),
    ];

    test('đúng chữ, tiếng Anh và tiếng Việt', () {
      final en = lookupAppLocalizations(const Locale('en'));
      final vi = lookupAppLocalizations(const Locale('vi'));
      expect(
        budgetAlertContent(
          en,
          alerts[0],
          monthStart: monthStart,
          monthEnd: monthEnd,
        ).body,
        'November budget: 80% used',
      );
      expect(
        budgetAlertContent(
          en,
          alerts[2],
          monthStart: monthStart,
          monthEnd: monthEnd,
          categoryName: 'Food',
        ).body,
        'Food: 100% of the November limit used',
      );
      expect(
        budgetAlertContent(
          vi,
          alerts[0],
          monthStart: monthStart,
          monthEnd: monthEnd,
        ).body,
        'Ngân sách tháng 11: đã dùng 80%',
      );
      expect(
        budgetAlertContent(
          vi,
          alerts[2],
          monthStart: monthStart,
          monthEnd: monthEnd,
          categoryName: 'Ăn uống',
        ).body,
        'Ăn uống: đã dùng 100% hạn mức tháng 11',
      );
    });

    test('không chứa số tiền hay ký hiệu tiền tệ', () {
      // Số tiền mẫu ở mọi dạng hiển thị của app; nội dung không được chứa.
      const spentAmounts = [4000000, 5000000, 5234567, 12];
      for (final code in ['en', 'vi']) {
        final l = lookupAppLocalizations(Locale(code));
        for (final currency in ['VND', 'USD', 'EUR', 'JPY']) {
          for (final a in alerts) {
            final c = budgetAlertContent(
              l,
              a,
              monthStart: monthStart,
              monthEnd: monthEnd,
              categoryName: code == 'vi' ? 'Ăn uống' : 'Food',
            );
            for (final text in [c.title, c.body]) {
              for (final amount in spentAmounts) {
                final shown = formatMoney(
                  amount,
                  currencyCode: currency,
                  locale: code,
                );
                expect(
                  plain(text),
                  isNot(contains(plain(shown))),
                  reason: '$code $currency $text',
                );
              }
              expect(
                text,
                isNot(matches(RegExp(r'[₫$€£¥]|\bVND\b|\bUSD\b|\bđ\b'))),
                reason: text,
              );
              // Chỉ số có mặt: phần trăm (kèm tháng ở tiếng Việt).
              final numbers = RegExp(r'\d+').allMatches(text).map((m) => m[0]);
              for (final n in numbers) {
                expect(['80', '85', '100', '11'], contains(n), reason: text);
              }
            }
          }
        }
      }
    });
  });

  test('mã thông báo ngân sách ổn định, trong [40000, 50000)', () {
    const a = BudgetAlert(
      id: 'cat7',
      milestone: BudgetMilestone.full,
      percent: 100,
      categoryId: 7,
    );
    const b = BudgetAlert(
      id: 'cat7',
      milestone: BudgetMilestone.threshold,
      percent: 80,
      categoryId: 7,
    );
    const m = BudgetAlert(
      id: monthlyBudgetId,
      milestone: BudgetMilestone.full,
      percent: 100,
    );
    final ids = [a, b, m].map(budgetNotificationId).toList();
    expect(budgetNotificationId(a), budgetNotificationId(a));
    expect(ids.toSet(), hasLength(3));
    for (final id in ids) {
      // Không đụng 1001 (Nhắc ghi sổ) và [20000, 30000) (Nhắc hạn).
      expect(id, inInclusiveRange(40000, 49999));
    }
  });
}
