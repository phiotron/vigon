import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/balance_guard.dart';
import '../../data/database.dart';
import '../../data/money.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/dialog.dart';
import '../../ui/messenger.dart';
import '../../ui/money_lines.dart';

/// "Có thu mới có chi" (D-046) ở tầng giao diện: dựng [BalanceGuard] với tỷ
/// giá hiện tại và chữ báo lỗi theo SPEC F-49.
Future<BalanceGuard> readBalanceGuard(WidgetRef ref) async => BalanceGuard(
  ref.read(databaseProvider),
  await ref.read(currencyServiceProvider.future),
);

/// "Trip chỉ còn 500.000 ₫" (AC-160): số dư hiện tại trước khi lưu, theo
/// AC-146 (Tiền tệ chính trước, số gốc trong ngoặc khi khác tiền tệ).
String shortfallMessage(BuildContext context, WidgetRef ref, Shortfall s) {
  final l = AppLocalizations.of(context);
  return l.ledgerOnlyLeft(
    accountLabel(l, s.account),
    moneyOneLine(context, ref, s.before, s.account.currency),
  );
}

/// "Không xoá được: Trip sẽ âm 200.000 ₫" (AC-161).
String deleteBlockedMessage(BuildContext context, WidgetRef ref, Shortfall s) {
  final l = AppLocalizations.of(context);
  return l.ledgerDeleteBlocked(
    accountLabel(l, s.account),
    moneyOneLine(context, ref, s.missing, s.account.currency),
  );
}

/// Hộp báo không xoá được (AC-161), một nút "Đã hiểu".
Future<void> showDeleteBlocked(
  BuildContext context,
  WidgetRef ref,
  Shortfall s,
) {
  final l = AppLocalizations.of(context);
  final body = deleteBlockedMessage(context, ref, s);
  return showDialog<void>(
    context: context,
    builder: (context) => VgDialog(
      title: l.ledgerDeleteBlockedTitle,
      body: body,
      icon: Symbols.account_balance_wallet_rounded,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l.ledgerOk),
        ),
      ],
    ),
  );
}

/// Kiểm trước khi xoá [entry] (AC-161): làm âm tài khoản thì hiện hộp báo và
/// trả về false. Dùng cho `confirmDismiss` của vuốt xoá.
Future<bool> canDeleteEntry(
  BuildContext context,
  WidgetRef ref,
  Entry entry,
) async {
  final guard = await readBalanceGuard(ref);
  final short = await guard.checkDelete([entry]);
  if (short == null) return true;
  if (context.mounted) await showDeleteBlocked(context, ref, short);
  return false;
}

/// Xoá [entry] (đã qua [canDeleteEntry]) và hiện thanh Hoàn tác (AC-14).
/// Hoàn tác ghi lại khoản; khoản chi/chuyển đi đó giờ làm âm tài khoản (vì
/// trong lúc chờ đã chi thêm) thì báo "… chỉ còn …" và không ghi (AC-160).
Future<void> deleteEntryWithUndo(
  BuildContext context,
  WidgetRef ref,
  Entry entry,
) async {
  final l = AppLocalizations.of(context);
  final locale = Localizations.localeOf(context).toString();
  final repo = ref.read(entryRepositoryProvider);
  // Lúc bấm Hoàn tác màn có thể đã đóng (không dùng được `ref`): giữ sẵn.
  final guard = await readBalanceGuard(ref);
  final deleted = await repo.delete(entry.id);
  if (deleted == null) return;
  showUndoSnackBar(
    message: l.deleted,
    undoLabel: l.undo,
    onUndo: () async {
      final short = await guard.check(add: entryEffects(deleted));
      if (short != null) {
        showMessage(shortfallText(l, locale, short));
        return;
      }
      await repo.restore(deleted);
    },
  );
}

/// Như [shortfallMessage] nhưng không cần `BuildContext` (sau khi màn đã
/// đóng): một dòng theo tiền tệ tài khoản.
String shortfallText(AppLocalizations l, String locale, Shortfall s) =>
    l.ledgerOnlyLeft(
      accountLabel(l, s.account),
      formatMoney(s.before, currencyCode: s.account.currency, locale: locale),
    );
