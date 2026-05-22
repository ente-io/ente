import "package:ente_auth/l10n/l10n.dart";
import "package:ente_auth/onboarding/model/tag_enums.dart";
import "package:ente_auth/store/code_display_store.dart";
import "package:ente_auth/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class TagChip extends StatefulWidget {
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
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip> {
  bool _hasFocus = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isSelected = widget.state == TagChipState.selected;
    final textColor = isSelected ? Colors.white : colorScheme.textBase;
    final focusBorderColor = isSelected ? Colors.white : colorScheme.primary700;

    return FocusableActionDetector(
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
        SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
      },
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      onShowFocusHighlight: (value) {
        if (_hasFocus != value) {
          setState(() => _hasFocus = value);
        }
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: Semantics(
          button: widget.onTap != null,
          selected: isSelected,
          child: Container(
            constraints: const BoxConstraints(minHeight: 40),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary700
                  : colorScheme.fillFaint,
              borderRadius: const BorderRadius.all(Radius.circular(24.0)),
              border: Border.all(
                color: _hasFocus ? focusBorderColor : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: const TextScaler.linear(1)),
                  child: Row(
                    children: [
                      if (widget.iconData != null)
                        Icon(
                          widget.iconData,
                          size: widget.label.isNotEmpty ? 16 : 20,
                          color: textColor,
                        ),
                      if (widget.iconData != null && widget.label.isNotEmpty)
                        const SizedBox(width: 8),
                      if (widget.label.isNotEmpty)
                        Text(
                          widget.label,
                          style: textTheme.small.copyWith(color: textColor),
                        ),
                    ],
                  ),
                ),
                if (isSelected && widget.action == TagChipAction.check) ...[
                  const SizedBox(width: 16),
                  const Icon(Icons.check, size: 16, color: Colors.white),
                  const SizedBox(width: 16),
                ] else if (isSelected &&
                    widget.action == TagChipAction.menu) ...[
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
                          CodeDisplayStore.instance.showEditDialog(
                            context,
                            widget.label,
                          );
                        } else if (value == 1) {
                          CodeDisplayStore.instance.showDeleteTagDialog(
                            context,
                            widget.label,
                          );
                        }
                      },
                      itemBuilder: (BuildContext context) {
                        return [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                const Icon(Icons.edit_outlined, size: 16),
                                const SizedBox(width: 12),
                                Text(context.l10n.edit),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 1,
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
        ),
      ),
    );
  }
}
