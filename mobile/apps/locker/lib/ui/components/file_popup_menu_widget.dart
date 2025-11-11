import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/delete_confirmation_dialog.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/components/popup_menu_item_widget.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/utils/collection_list_util.dart";
import "package:locker/utils/snack_bar_utils.dart";

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
        _showEditDialog(context);
        break;
      case 'share_link':
        _shareLink(context);
        break;
      case 'delete':
        _showDeleteConfirmationDialog(context);
        break;
    }
  }

  Future<void> _shareLink(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.creatingShareLink,
      isDismissible: false,
    );

    try {
      await dialog.show();

      final shareableLink = await LinksService.instance.getOrCreateLink(file);

      await dialog.hide();

      if (context.mounted) {
        await showShareLinkDialog(
          context,
          shareableLink.fullURL!,
          shareableLink.linkID,
          file,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          '${context.l10n.failedToCreateShareLink}: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(1),
      deleteButtonLabel: context.l10n.yesDeleteFiles(1),
      assetPath: "assets/file_delete_icon.png",
    );

    if (result?.buttonResult.action == ButtonAction.first && context.mounted) {
      await _deleteFile(context);
    }
  }

  Future<void> _deleteFile(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.deletingFile,
      isDismissible: false,
    );

    try {
      await dialog.show();

      final collections =
          await CollectionService.instance.getCollectionsForFile(file);
      if (collections.isNotEmpty) {
        await CollectionService.instance.trashFile(file, collections.first);
      }

      await dialog.hide();
      if (context.mounted) {
        SnackBarUtils.showInfoSnackBar(
          context,
          context.l10n.fileDeletedSuccessfully,
        );
      }
    } catch (e) {
      await dialog.hide();

      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.failedToDeleteFile(e.toString()),
        );
      }
    }
  }

  Future<void> _showEditDialog(BuildContext context) async {
    final allCollections = await CollectionService.instance.getCollections();
    final dedupedCollections = uniqueCollectionsById(allCollections);

    final result = await showFileEditDialog(
      context,
      file: file,
      collections: dedupedCollections,
      snackBarContext: context,
    );

    if (result != null && context.mounted) {
      List<Collection> currentCollections;
      try {
        currentCollections =
            await CollectionService.instance.getCollectionsForFile(file);
      } catch (e) {
        currentCollections = <Collection>[];
      }

      final currentCollectionsSet = currentCollections.toSet();
      final selectedCollectionsSet = result.selectedCollections.toSet();
      final collectionsToAdd =
          selectedCollectionsSet.difference(currentCollectionsSet).toList();
      final hasCollectionAdds = collectionsToAdd.isNotEmpty;

      final currentTitle = file.displayName;
      final currentCaption = file.caption ?? '';
      final hasMetadataChanged =
          result.title != currentTitle || result.caption != currentCaption;

      if (hasMetadataChanged || hasCollectionAdds) {
        final dialog = createProgressDialog(
          context,
          context.l10n.pleaseWait,
          isDismissible: false,
        );
        await dialog.show();

        try {
          final addFutures = <Future<void>>[];
          for (final collection in collectionsToAdd) {
            addFutures.add(
              CollectionService.instance.addToCollection(
                collection,
                file,
                runSync: false,
              ),
            );
          }
          if (addFutures.isNotEmpty) {
            await Future.wait(addFutures);
          }

          final List<Future<void>> apiCalls = [];
          if (hasMetadataChanged) {
            apiCalls.add(
              MetadataUpdaterService.instance
                  .editFileNameAndCaption(file, result.title, result.caption),
            );
          }
          await Future.wait(apiCalls);

          await dialog.hide();

          if (!context.mounted) {
            return;
          }
          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.fileUpdatedSuccessfully,
          );
        } catch (e) {
          await dialog.hide();
          if (!context.mounted) {
            return;
          }

          SnackBarUtils.showWarningSnackBar(
            context,
            context.l10n.failedToUpdateFile(e.toString()),
          );
        }
      } else {
        if (!context.mounted) {
          return;
        }
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.noChangesWereMade,
        );
      }
    }
  }
}
