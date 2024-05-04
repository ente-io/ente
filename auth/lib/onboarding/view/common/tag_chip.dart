import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/onboarding/model/tag_enums.dart";
import "package:ente_auth/store/code_display_store.dart";
import "package:flutter/material.dart";
import "package:gradient_borders/box_borders/gradient_box_border.dart";

class TagChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final TagChipState state;
  final TagChipAction action;

  const TagChip({
    super.key,
    required this.label,
    this.state = TagChipState.unselected,
    this.action = TagChipAction.none,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: state == TagChipState.selected
              ? const Color(0xFF722ED1)
              : Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1C0F22)
                  : const Color(0xFFFCF5FF),
          borderRadius: BorderRadius.circular(100),
          border: GradientBoxBorder(
            gradient: LinearGradient(
              colors: state == TagChipState.selected
                  ? [
                      const Color(0xFFB37FEB),
                      const Color(0xFFAE40E3).withOpacity(
                        Theme.of(context).brightness == Brightness.dark
                            ? .53
                            : 1,
                      ),
                    ]
                  : [
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFAD00FF)
                          : const Color(0xFFAD00FF).withOpacity(0.2),
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFFA269BD).withOpacity(0.53)
                          : const Color(0xFF8609C2).withOpacity(0.2),
                    ],
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
            Text(
              label,
              style: TextStyle(
                color: state == TagChipState.selected ||
                        Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : const Color(0xFF8232E1),
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
                            const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFFF53434),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              context.l10n.delete,
                              style: const TextStyle(
                                color: Color(0xFFF53434),
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
