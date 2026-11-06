import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'data/database.dart';
import 'features/about/about_screen.dart';
import 'features/accounts/accounts_screen.dart';
import 'features/accounts/transfer_screen.dart';
import 'features/categories/categories_screen.dart';
import 'features/debts/debts_screen.dart';
import 'features/entries/entries_screen.dart';
import 'features/entry/entry_editor_screen.dart';
import 'features/home/home_screen.dart';
import 'features/import_queue/import_queue_screen.dart';
import 'features/import_queue/payee_suggestions_screen.dart';
import 'features/lock/app_lock.dart';
import 'features/lock/lock_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reminder/reminder_providers.dart';
import 'features/savings/savings_screen.dart';
import 'features/settings/email_import_screen.dart';
import 'features/settings/email_mailbox_form.dart';
import 'features/settings/secure_window.dart';
import 'features/settings/settings_screen.dart';
import 'features/widget/deep_link.dart';
import 'features/widget/widget_sync.dart';
import 'import/mail/mailbox_store.dart';
import 'providers.dart';
import 'ui/messenger.dart';
import 'ui/theme.dart';

/// Đường dẫn có `:id` mà id không phải số nguyên thì về màn chính, không ném lỗi.
String? _idOrHome(BuildContext context, GoRouterState state) =>
    int.tryParse(state.pathParameters['id'] ?? '') == null ? '/' : null;

/// Mỗi lần gọi tạo router mới; test dùng để mỗi test bắt đầu ở màn chính.
GoRouter createRouter() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'about',
          builder: (context, state) => const AboutScreen(),
        ),
        GoRoute(
          path: 'recurring',
          builder: (context, state) => const RecurringScreen(),
        ),
        GoRoute(
          path: 'categories',
          builder: (context, state) => const CategoriesScreen(),
        ),
        GoRoute(
          path: 'accounts',
          builder: (context, state) => const AccountsScreen(),
        ),
        GoRoute(
          path: 'transfer',
          builder: (context, state) => TransferScreen(
            // `?to=` điền sẵn ô Đến (Góp tiền, AC-102); chỉ nhận số nguyên.
            toAccountId: int.tryParse(state.uri.queryParameters['to'] ?? ''),
          ),
        ),
        GoRoute(
          path: 'transfer/:id',
          redirect: _idOrHome,
          builder: (context, state) =>
              TransferScreen(entryId: int.parse(state.pathParameters['id']!)),
        ),
        GoRoute(
          path: 'entries',
          builder: (context, state) => const EntriesScreen(),
        ),
        GoRoute(
          path: 'entry/new',
          builder: (context, state) {
            final q = state.uri.queryParameters;
            return EntryEditorScreen(
              type: q['type'] == 'income'
                  ? EntryType.income
                  : EntryType.expense,
              categoryId: int.tryParse(q['category'] ?? ''),
              // `?queue=` chỉ nhận số nguyên: "Sửa trước khi lưu" mục hàng đợi.
              queueItemId: int.tryParse(q['queue'] ?? ''),
            );
          },
        ),
        GoRoute(
          path: 'entry/:id',
          redirect: _idOrHome,
          builder: (context, state) => EntryEditorScreen(
            entryId: int.parse(state.pathParameters['id']!),
          ),
        ),
        // F-32: Hàng đợi chọn danh mục + Gợi ý đã nhớ.
        GoRoute(
          path: 'import-queue',
          builder: (context, state) => const ImportQueueScreen(),
          routes: [
            GoRoute(
              path: 'suggestions',
              builder: (context, state) => const PayeeSuggestionsScreen(),
            ),
          ],
        ),
        // F-34: Khoản nợ.
        GoRoute(
          path: 'debts',
          builder: (context, state) => const DebtsScreen(),
        ),
        // F-33: Tiết kiệm.
        GoRoute(
          path: 'savings',
          builder: (context, state) => const SavingsScreen(),
        ),
        // F-28: hộp thư email; `?id=` chỉ nhận id ô có thật (nhập lại mật khẩu).
        GoRoute(
          path: 'email-import',
          builder: (context, state) => const EmailImportScreen(),
          routes: [
            GoRoute(
              path: 'add',
              builder: (context, state) {
                final id = state.uri.queryParameters['id'];
                return EmailMailboxForm(
                  mailboxId: MailboxStore.slotIds.contains(id) ? id : null,
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);

final _router = createRouter();

final _lightTheme = buildTheme(Brightness.light);
final _darkTheme = buildTheme(Brightness.dark);

class VigonApp extends ConsumerWidget {
  const VigonApp({super.key, this.router});

  /// Test truyền router từ [createRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(startupProvider);
    ref.watch(secureWindowSyncProvider);
    ref.watch(widgetSyncProvider);
    ref.watch(reminderSyncProvider);
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeCode = ref.watch(localeCodeProvider).value;
    final lock = ref.watch(lockProvider);
    final appRouter = router ?? _router;
    return MaterialApp.router(
      // Màn khóa phủ lên toàn app; phần bên dưới ẩn khỏi trình đọc màn hình (AC-32).
      builder: (context, child) => DeepLinkBinder(
        router: appRouter,
        child: ReminderTapBinder(
          router: appRouter,
          child: AppLifecycleWatcher(
            child: Stack(
              children: [
                Offstage(offstage: lock != AppLockState.unlocked, child: child),
                if (lock != AppLockState.unlocked)
                  LockScreen(checking: lock == AppLockState.checking),
              ],
            ),
          ),
        ),
      ),
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: appRouter,
      scaffoldMessengerKey: rootMessengerKey,
      themeMode: themeMode,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      // D-036: mặc định English, không theo ngôn ngữ máy.
      locale: Locale(localeCode ?? 'en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
