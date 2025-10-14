import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
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
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedFile02,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList();
    } else {
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
  }
}
