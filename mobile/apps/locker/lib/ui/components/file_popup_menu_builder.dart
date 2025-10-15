import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/item_list_view.dart";

class FilePopupMenuBuilder {
  static List<PopupMenuItem<String>> buildPopupMenuItems(
    BuildContext context,
    List<OverflowMenuAction>? overflowActions,
  ) {
    if (overflowActions != null && overflowActions.isNotEmpty) {
      return overflowActions
          .map(
            (action) => PopupMenuItem<String>(
              value: action.id,
              child: Row(
                children: [
                  Icon(
                    action.icon,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList();
    }

    return [
      PopupMenuItem<String>(
        value: 'edit',
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedEdit02,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(context.l10n.edit),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'share_link',
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedShare03,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(context.l10n.share),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        child: Row(
          children: [
            const HugeIcon(
              icon: HugeIcons.strokeRoundedDelete01,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(context.l10n.delete),
          ],
        ),
      ),
    ];
  }

  static void handleMenuAction(
    BuildContext context,
    String action,
    EnteFile file,
    List<OverflowMenuAction>? overflowActions, {
    VoidCallback? onEditCallback,
    VoidCallback? onShareLinkCallback,
    VoidCallback? onDeleteCallback,
  }) {
    if (overflowActions != null && overflowActions.isNotEmpty) {
      final customAction = overflowActions.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, file, null);
      return;
    }

    switch (action) {
      case 'edit':
        if (onEditCallback != null) {
          onEditCallback();
        }
        break;
      case 'share_link':
        if (onShareLinkCallback != null) {
          onShareLinkCallback();
        }
        break;
      case 'delete':
        if (onDeleteCallback != null) {
          onDeleteCallback();
        }
        break;
    }
  }
}
