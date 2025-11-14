import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/onboarding/model/tag_enums.dart";
import "package:ente_auth/store/code_display_store.dart";
import "package:ente_auth/theme/ente_theme.dart";
import "package:flutter/material.dart";

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final TagChipState state;
  final TagChipAction action;
  final IconData? iconData;

  const TagChip({
    super.key,
    required this.label,
    this.state = TagChipState.unselected,
    this.action = TagChipAction.none,
    this.onTap,
    this.iconData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isSelected = state == TagChipState.selected;
    final textColor = isSelected ? Colors.white : colorScheme.textBase;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 40),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : colorScheme.fillFaint,
          borderRadius: const BorderRadius.all(Radius.circular(24.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16)
            .copyWith(right: 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1),
              ),
              child: Row(
                children: [
                  if (iconData != null)
                    Icon(
                      iconData,
                      size: label.isNotEmpty ? 16 : 20,
                      color: textColor,
                    ),
                  if (iconData != null && label.isNotEmpty)
                    const SizedBox(width: 8),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: textTheme.small.copyWith(
                        color: textColor,
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected && action == TagChipAction.check) ...[
              const SizedBox(width: 16),
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
            ] else if (isSelected && action == TagChipAction.menu) ...[
              SizedBox(
                width: 48,
                child: PopupMenuButton<int>(
                  iconSize: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  surfaceTintColor: Theme.of(context).cardColor,
                  iconColor: Colors.white,
                  initialValue: -1,
                  onSelected: (value) {
                    if (value == 0) {
                      CodeDisplayStore.instance.showEditDialog(context, label);
                    } else if (value == 1) {
                      CodeDisplayStore.instance
                          .showDeleteTagDialog(context, label);
                    }
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            const Icon(Icons.edit_outlined, size: 16),
                            const SizedBox(width: 12),
                            Text(context.l10n.edit),
                          ],
                        ),
                        value: 0,
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: colorScheme.deleteTagIconColor,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.delete,
                              style: TextStyle(
                                color: colorScheme.deleteTagTextColor,
                              ),
                            ),
                          ],
                        ),
                        value: 1,
                      ),
                    ];
                  },
                ),
              ),
            ] else ...[
              const SizedBox(width: 16),
            ],
          ],
        ),
      ),
    );
  }
}
