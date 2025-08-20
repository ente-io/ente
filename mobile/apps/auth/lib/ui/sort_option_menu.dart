import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/services/preference_service.dart';
import 'package:flutter/material.dart';

class SortCodeMenuWidget extends StatelessWidget {
  final CodeSortKey currentKey;
  final void Function(CodeSortKey) onSelected;
  const SortCodeMenuWidget({
    super.key,
    required this.currentKey,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Text sortOptionText(CodeSortKey key) {
      String text = key.toString();
      switch (key) {
        case CodeSortKey.issuerName:
          text = context.l10n.codeIssuerHint;
          break;
        case CodeSortKey.accountName:
          text = context.l10n.account;
          break;
        case CodeSortKey.mostFrequentlyUsed:
          text = context.l10n.mostFrequentlyUsed;
          break;
        case CodeSortKey.recentlyUsed:
          text = context.l10n.mostRecentlyUsed;
          break;
        case CodeSortKey.manual:
          text = context.l10n.manualSort;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.7),
            ),
      );
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) async {
        final int? selectedValue = await showMenu<int>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy + 300,
          ),
          items: List.generate(CodeSortKey.values.length, (index) {
            return PopupMenuItem(
              value: index,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  sortOptionText(CodeSortKey.values[index]),
                  if (CodeSortKey.values[index] == currentKey)
                    Icon(
                      CodeSortKey.values[index] == CodeSortKey.manual
                          ? Icons.mode_edit
                          : Icons.check,
                      color: Theme.of(context).iconTheme.color,
                    ),
                ],
              ),
            );
          }),
        );
        if (selectedValue != null) {
          onSelected(CodeSortKey.values[selectedValue]);
        }
      },
      child: const Icon(Icons.sort_outlined),
    );
  }
}
