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
import 'features/entries/entries_screen.dart';
import 'features/entry/entry_editor_screen.dart';
import 'features/home/home_screen.dart';
import 'features/lock/app_lock.dart';
import 'features/lock/lock_screen.dart';
import 'features/recurring/recurring_screen.dart';
import 'features/reminder/reminder_providers.dart';
import 'features/settings/secure_window.dart';
import 'features/settings/settings_screen.dart';
import 'providers.dart';
import 'ui/messenger.dart';

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
          builder: (context, state) => const TransferScreen(),
        ),
        GoRoute(
          path: 'transfer/:id',
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
            );
          },
        ),
        GoRoute(
          path: 'entry/:id',
          builder: (context, state) => EntryEditorScreen(
            entryId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
  ],
);

final _router = createRouter();

const _seedColor = Color(0xFF2E7D6B);

class VigonApp extends ConsumerWidget {
  const VigonApp({super.key, this.router});

  /// Test truyền router từ [createRouter].
  final GoRouter? router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(startupProvider);
    ref.watch(secureWindowSyncProvider);
    ref.watch(reminderSyncProvider);
    final appRouter = router ?? _router;
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;
    final localeCode = ref.watch(localeCodeProvider).value;
    final lock = ref.watch(lockProvider);
    return MaterialApp.router(
      // Màn khóa phủ lên toàn app; phần bên dưới ẩn khỏi trình đọc màn hình (AC-32).
      builder: (context, child) => ReminderTapBinder(
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
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: appRouter,
      scaffoldMessengerKey: rootMessengerKey,
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.dark,
        ),
      ),
      locale: localeCode == null ? null : Locale(localeCode),
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
