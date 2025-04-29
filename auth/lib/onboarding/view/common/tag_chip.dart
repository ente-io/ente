import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/onboarding/model/tag_enums.dart";
import "package:ente_auth/store/code_display_store.dart";
import "package:ente_auth/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:gradient_borders/box_borders/gradient_box_border.dart";

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
    final color = state == TagChipState.selected ||
            Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : colorScheme.tagTextUnselectedColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: state == TagChipState.selected
              ? colorScheme.tagChipSelectedColor
              : colorScheme.tagChipUnselectedColor,
          borderRadius: BorderRadius.circular(100),
          border: GradientBoxBorder(
            gradient: LinearGradient(
              colors: state == TagChipState.selected
                  ? colorScheme.tagChipSelectedGradient
                  : colorScheme.tagChipUnselectedGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16)
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
                      color: color,
                    ),
                  if (iconData != null && label.isNotEmpty)
                    const SizedBox(width: 8),
                  if (label.isNotEmpty)
                    Text(
                      label,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            if (state == TagChipState.selected &&
                action == TagChipAction.check) ...[
              const SizedBox(width: 16),
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 16),
            ] else if (state == TagChipState.selected &&
                action == TagChipAction.menu) ...[
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
