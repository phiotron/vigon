import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../l10n/app_localizations.dart';
import '../../data/database.dart';
import '../../l10n_names.dart';
import '../../providers.dart';
import '../../ui/messenger.dart';
import '../../ui/tokens.g.dart';
import 'import_queue_providers.dart';

/// "Gợi ý đã nhớ" (AC-97): xem và xoá từng gợi ý theo người thụ hưởng — danh
/// mục, hoặc "Chuyển sang tài khoản X".
class PayeeSuggestionsScreen extends ConsumerWidget {
  const PayeeSuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final suggestions = ref.watch(payeeSuggestionsProvider).value ?? const [];
    final categories = {
      for (final type in CategoryType.values)
        for (final c in ref.watch(categoriesProvider(type)).value ?? const [])
          c.id: c,
    };
    final accounts = {
      for (final a in ref.watch(allAccountsProvider).value ?? const <Account>[])
        a.id: a,
    };
    String target(PayeeSuggestion s) {
      final c = categories[s.categoryId];
      if (c != null) return categoryLabel(l, c);
      final a = accounts[s.toAccountId];
      return a == null ? '' : l.queueSuggestionMove(accountLabel(l, a));
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.queueSuggestions)),
      body: suggestions.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: VgSpace.s8),
                child: Text(
                  l.queueSuggestionsEmpty,
                  textAlign: TextAlign.center,
                  style: VgType.bodyMd.copyWith(color: scheme.onSurfaceVariant),
                ),
              ),
            )
          : ListView.builder(
              itemCount: suggestions.length,
              itemBuilder: (context, i) {
                final s = suggestions[i];
                return ListTile(
                  title: Text(
                    s.payee,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(target(s)),
                  trailing: IconButton(
                    tooltip: l.queueSuggestionDelete,
                    icon: const Icon(Symbols.delete_rounded),
                    onPressed: () async {
                      await ref
                          .read(payeeSuggestionRepositoryProvider)
                          .delete(s.payeeKey);
                      showMessage(l.queueSuggestionDeleted);
                    },
                  ),
                );
              },
            ),
    );
  }
}
