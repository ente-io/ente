import "dart:io";

import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/icon_button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/info/info_item.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/files/download/file_downloader.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/info_file_service.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/ui/pages/account_credentials_page.dart";
import "package:locker/ui/pages/base_info_page.dart";
import "package:locker/ui/pages/emergency_contact_page.dart";
import "package:locker/ui/pages/personal_note_page.dart";
import "package:locker/ui/pages/physical_records_page.dart";
import "package:locker/utils/file_icon_utils.dart";
import "package:locker/utils/info_item_utils.dart";
import "package:locker/utils/snack_bar_utils.dart";
import "package:open_file/open_file.dart";

class FileListWidget extends StatelessWidget {
  final EnteFile file;
  final List<Collection> collections;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;
  final SelectedFiles? selectedFiles;
  final void Function(EnteFile)? onTapCallback;
  final void Function(EnteFile)? onLongPressCallback;

  const FileListWidget({
    super.key,
    required this.file,
    required this.collections,
    this.overflowActions,
    this.isLastItem = false,
    this.selectedFiles,
    this.onTapCallback,
    this.onLongPressCallback,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);

    final fileRowWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 60,
            child: _buildFileIcon(),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  file.displayName,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () {
        if (onTapCallback != null) {
          onTapCallback!(file);
        } else {
          _openFile(context);
        }
      },
      onLongPress: () {
        if (onLongPressCallback != null) {
          onLongPressCallback!(file);
        } else {
          _openFile(context);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: ListenableBuilder(
        listenable: selectedFiles ?? ValueNotifier(false),
        builder: (context, _) {
          final bool isSelected = selectedFiles?.isFileSelected(file) ?? false;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary700
                    : colorScheme.backdropBase,
                width: 1.5,
              ),
              color: colorScheme.backdropBase,
              borderRadius: const BorderRadius.all(Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                fileRowWidget,
                Flexible(
                  flex: 1,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    child: isSelected
                        ? IconButtonWidget(
                            key: const ValueKey("selected"),
                            icon: Icons.check_circle_rounded,
                            iconButtonType: IconButtonType.secondary,
                            iconColor: colorScheme.primary700,
                          )
                        : PopupMenuButton<String>(
                            onSelected: (value) =>
                                _handleMenuAction(context, value),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: HugeIcon(
                                icon: HugeIcons.strokeRoundedMoreVertical,
                                color: getEnteColorScheme(context).iconColor,
                              ),
                            ),
                            itemBuilder: (BuildContext context) {
                              return _buildPopupMenuItems(context);
                            },
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      return overflowActions!
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

  void _handleMenuAction(BuildContext context, String action) {
    if (overflowActions != null && overflowActions!.isNotEmpty) {
      final customAction = overflowActions!.firstWhere(
        (a) => a.id == action,
        orElse: () => throw StateError('Action not found'),
      );
      customAction.onTap(context, file, null);
    } else {
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
  }

  Future<void> _shareLink(BuildContext context) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.creatingShareLink,
      isDismissible: false,
    );

    try {
      await dialog.show();

      // Get or create the share link
      final shareableLink = await LinksService.instance.getOrCreateLink(file);

      await dialog.hide();

      // Show the link dialog with copy and delete options
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
    final result = await showChoiceDialog(
      context,
      title: context.l10n.deleteFile,
      body: context.l10n.deleteFileConfirmation(file.displayName),
      firstButtonLabel: context.l10n.delete,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );

    if (result?.action == ButtonAction.first && context.mounted) {
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
    allCollections.removeWhere(
      (c) => c.type == CollectionType.uncategorized,
    );

    final result = await showFileEditDialog(
      context,
      file: file,
      collections: allCollections,
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

      final newCollectionsSet = result.selectedCollections.toSet();

      final collectionsToAdd =
          newCollectionsSet.difference(currentCollectionsSet).toList();

      final collectionsToRemove =
          currentCollectionsSet.difference(newCollectionsSet).toList();

      final currentTitle = file.displayName;
      final currentCaption = file.caption ?? '';
      final hasMetadataChanged =
          result.title != currentTitle || result.caption != currentCaption;

      if (hasMetadataChanged || currentCollectionsSet != newCollectionsSet) {
        final dialog = createProgressDialog(
          context,
          context.l10n.pleaseWait,
          isDismissible: false,
        );
        await dialog.show();

        try {
          final List<Future<void>> apiCalls = [];
          for (final collection in collectionsToAdd) {
            apiCalls.add(
              CollectionService.instance.addToCollection(collection, file),
            );
          }
          await Future.wait(apiCalls);
          apiCalls.clear();

          for (final collection in collectionsToRemove) {
            apiCalls.add(
              CollectionService.instance
                  .move(file, collection, newCollectionsSet.first),
            );
          }
          if (hasMetadataChanged) {
            apiCalls.add(
              MetadataUpdaterService.instance
                  .editFileNameAndCaption(file, result.title, result.caption),
            );
          }
          await Future.wait(apiCalls);

          await dialog.hide();

          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.fileUpdatedSuccessfully,
          );
        } catch (e) {
          await dialog.hide();

          SnackBarUtils.showWarningSnackBar(
            context,
            context.l10n.failedToUpdateFile(e.toString()),
          );
        }
      } else {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.noChangesWereMade,
        );
      }
    }
  }

  Widget _buildFileIcon() {
    // Check if this is an info file
    if (InfoFileService.instance.isInfoFile(file)) {
      try {
        final infoItem = InfoFileService.instance.extractInfoFromFile(file);
        if (infoItem != null) {
          return InfoItemUtils.getInfoIcon(infoItem.type);
        }
      } catch (e) {
        // Fallback to default icon if extraction fails
      }
    }

    // For non-info files or if extraction fails, use the original logic
    return FileIconUtils.getFileIcon(file.displayName, showBackground: true);
  }

  Future<void> _openFile(BuildContext context) async {
    // Check if this is an info file
    if (InfoFileService.instance.isInfoFile(file)) {
      return _openInfoFile(context);
    }

    if (file.localPath != null) {
      final localFile = File(file.localPath!);
      if (await localFile.exists()) {
        await _launchFile(context, localFile, file.displayName);
        return;
      }
    }

    final String cachedFilePath =
        "${Configuration.instance.getCacheDirectory()}${file.displayName}";
    final File cachedFile = File(cachedFilePath);
    if (await cachedFile.exists()) {
      await _launchFile(context, cachedFile, file.displayName);
      return;
    }

    final dialog = createProgressDialog(
      context,
      context.l10n.downloading,
      isDismissible: false,
    );

    try {
      await dialog.show();
      final fileKey = await CollectionService.instance.getFileKey(file);
      final decryptedFile = await downloadAndDecrypt(
        file,
        fileKey,
        progressCallback: (downloaded, total) {
          if (total > 0 && downloaded >= 0) {
            final percentage =
                ((downloaded / total) * 100).clamp(0, 100).round();
            dialog.update(
              message: context.l10n.downloadingProgress(percentage),
            );
          } else {
            dialog.update(message: context.l10n.downloading);
          }
        },
        shouldUseCache: true,
      );

      await dialog.hide();

      if (decryptedFile != null) {
        await _launchFile(context, decryptedFile, file.displayName);
      } else {
        await showErrorDialog(
          context,
          context.l10n.downloadFailed,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    } catch (e) {
      await dialog.hide();
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.errorOpeningFileMessage(e.toString()),
      );
    }
  }

  Future<void> _openInfoFile(BuildContext context) async {
    try {
      final infoItem = InfoFileService.instance.extractInfoFromFile(file);
      if (infoItem == null) {
        await showErrorDialog(
          context,
          context.l10n.errorOpeningFile,
          'Unable to extract information from this file',
        );
        return;
      }

      // Navigate to the appropriate page based on info type in view mode
      Widget page;
      switch (infoItem.type) {
        case InfoType.note:
          page = PersonalNotePage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.accountCredential:
          page = AccountCredentialsPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.physicalRecord:
          page = PhysicalRecordsPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.emergencyContact:
          page = EmergencyContactPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        'Failed to open info file: ${e.toString()}',
      );
    }
  }

  Future<void> _launchFile(
    BuildContext context,
    File file,
    String fileName,
  ) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.couldNotOpenFile(e.toString()),
      );
    }
  }
}
