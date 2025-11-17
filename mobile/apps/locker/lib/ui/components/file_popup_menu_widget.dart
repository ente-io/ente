import "package:ente_events/event_bus.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/components/popup_menu_item_widget.dart";
import "package:locker/utils/file_actions.dart";
import "package:locker/utils/file_util.dart";

class FilePopupMenuWidget extends StatelessWidget {
  final EnteFile file;
  final List<OverflowMenuAction>? overflowActions;
  final Widget? child;
  const FilePopupMenuWidget({
    super.key,
    required this.file,
    this.overflowActions,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    return PopupMenuButton<String>(
      onSelected: (value) => _handleMenuAction(context, value),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.strokeFaint),
      ),
      offset: const Offset(-24, 24),
      color: colorScheme.backdropBase,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      elevation: 15,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      child: child ??
          HugeIcon(
            icon: HugeIcons.strokeRoundedMoreVertical,
            color: colorScheme.textBase,
          ),
      itemBuilder: (BuildContext context) {
        return _buildPopupMenuItems(context);
      },
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final items = <PopupMenuItem<String>>[];
      for (int i = 0; i < overflowActions!.length; i++) {
        final action = overflowActions![i];
        items.add(
          PopupMenuItem<String>(
            value: action.id,
            padding: EdgeInsets.zero,
            height: 0,
            child: PopupMenuItemWidget(
              icon: action.icon,
              label: action.label,
              isFirst: i == 0,
              isLast: i == overflowActions!.length - 1,
              isWarning: action.isWarning,
            ),
          ),
        );
      }
      return items;
    }

    return [
      PopupMenuItem<String>(
        value: 'edit',
        padding: EdgeInsets.zero,
        height: 0,
        child: PopupMenuItemWidget(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedPencilEdit02,
            color: colorScheme.textBase,
            size: 20,
          ),
          label: context.l10n.edit,
          isFirst: true,
          isLast: false,
        ),
      ),
      PopupMenuItem<String>(
        value: 'download',
        padding: EdgeInsets.zero,
        height: 0,
        child: PopupMenuItemWidget(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedDownload01,
            color: colorScheme.textBase,
            size: 20,
          ),
          label: "Save",
          isFirst: false,
          isLast: false,
        ),
      ),
      PopupMenuItem<String>(
        value: 'share_link',
        padding: EdgeInsets.zero,
        height: 0,
        child: PopupMenuItemWidget(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedShare08,
            color: colorScheme.textBase,
            size: 20,
          ),
          label: context.l10n.share,
          isFirst: false,
          isLast: false,
        ),
      ),
      PopupMenuItem<String>(
        value: 'delete',
        padding: EdgeInsets.zero,
        height: 0,
        child: PopupMenuItemWidget(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedDelete02,
            color: colorScheme.warning500,
            size: 20,
          ),
          label: context.l10n.delete,
          isFirst: false,
          isLast: true,
          isWarning: true,
        ),
      ),
    ];
  }

  void _handleMenuAction(BuildContext context, String action) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final customAction = overflowActions!.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, file, null);
      return;
    }

    switch (action) {
      case 'edit':
        _editFile(context);
        break;
      case 'download':
        _downloadFile(context);
        break;
      case 'share_link':
        _shareFileLink(context);
        break;
      case 'delete':
        _deleteFile(context);
        break;
    }
  }

  Future<void> _shareFileLink(BuildContext context) async {
    await FileActions.shareFileLink(context, file);
  }

  Future<void> _downloadFile(BuildContext context) async {
    await FileUtil.downloadFile(context, file);
  }

  Future<void> _deleteFile(BuildContext context) async {
    await FileActions.deleteFile(
      context,
      file,
      onSuccess: () {
        Bus.instance.fire(CollectionsUpdatedEvent('file_deleted'));
      },
    );
  }

  Future<void> _editFile(BuildContext context) async {
    await FileActions.editFile(context, file);
  }
}
