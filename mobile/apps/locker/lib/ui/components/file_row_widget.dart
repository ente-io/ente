import "dart:io";

import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/files/download/file_downloader.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/button/copy_button.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/item_list_view.dart";
import "package:locker/utils/data_util.dart";
import "package:locker/utils/date_time_util.dart";
import "package:locker/utils/file_icon_utils.dart";
import "package:locker/utils/snack_bar_utils.dart";
import "package:open_file/open_file.dart";

class FileRowWidget extends StatelessWidget {
  final EnteFile file;
  final List<Collection> collections;
  final List<OverflowMenuAction>? overflowActions;
  final bool isLastItem;

  const FileRowWidget({
    super.key,
    required this.file,
    required this.collections,
    this.overflowActions,
    this.isLastItem = false,
  });

  @override
  Widget build(BuildContext context) {
    final updateTime = file.updationTime != null
        ? DateTime.fromMicrosecondsSinceEpoch(file.updationTime!)
        : (file.modificationTime != null
            ? DateTime.fromMillisecondsSinceEpoch(file.modificationTime!)
            : (file.creationTime != null
                ? DateTime.fromMillisecondsSinceEpoch(file.creationTime!)
                : DateTime.now()));

    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    final fileRowWidget = Flexible(
      flex: 6,
      child: Row(
        children: [
          SizedBox(
            height: 60,
            width: 48,
            child: Icon(
              FileIconUtils.getFileIcon(file.displayName),
              color: FileIconUtils.getFileIconColor(file.displayName),
              size: 22,
            ),
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
                Row(
                  children: [
                    Text(
                      formatDate(context, updateTime),
                      style: textTheme.small.copyWith(
                        color: colorScheme.textMuted,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    FutureBuilder<int>(
                      future: CollectionService.instance.getFileSize(file),
                      builder: (context, snapshot) {
                        final size = snapshot.data ?? 0;
                        return Text(
                          ' • ' + formatBytes(size),
                          style: getEnteTextTheme(context).small.copyWith(
                                color: colorScheme.textMuted,
                              ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return GestureDetector(
      onTap: () => _openFile(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: colorScheme.strokeFaint,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(6)),
        ),
        child: Row(
          children: [
            fileRowWidget,
            Flexible(
              child: PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, value),
                icon: const Icon(
                  Icons.more_vert,
                  size: 20,
                ),
                itemBuilder: (BuildContext context) {
                  return _buildPopupMenuItems(context);
                },
              ),
            ),
          ],
        ),
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
                  Icon(action.icon, size: 16),
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
              const Icon(Icons.edit, size: 16),
              const SizedBox(width: 8),
              Text(context.l10n.edit),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'share_link',
          child: Row(
            children: [
              const Icon(Icons.share, size: 16),
              const SizedBox(width: 8),
              Text(context.l10n.share),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              const Icon(Icons.delete, size: 16),
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
        await _showShareLinkDialog(
          context,
          shareableLink.fullURL!,
          shareableLink.linkID,
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

  Future<void> _showShareLinkDialog(
    BuildContext context,
    String url,
    String linkID,
  ) async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    // Capture the root context (with Scaffold) before showing dialog
    final rootContext = context;

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                dialogContext.l10n.share,
                style: textTheme.largeBold,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dialogContext.l10n.shareThisLink,
                    style: textTheme.body,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.fillFaint,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.strokeFaint),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            url,
                            style: textTheme.small,
                          ),
                        ),
                        const SizedBox(width: 8),
                        CopyButton(url: url),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await _deleteShareLink(rootContext, file.uploadedFileID!);
                  },
                  child: Text(
                    dialogContext.l10n.deleteLink,
                    style:
                        textTheme.body.copyWith(color: colorScheme.warning500),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    // Use system share sheet to share the URL
                    await shareText(
                      url,
                      context: rootContext,
                    );
                  },
                  child: Text(
                    dialogContext.l10n.shareLink,
                    style:
                        textTheme.body.copyWith(color: colorScheme.primary500),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteShareLink(BuildContext context, int fileID) async {
    final result = await showChoiceDialog(
      context,
      title: context.l10n.deleteShareLinkDialogTitle,
      body: context.l10n.deleteShareLinkConfirmation,
      firstButtonLabel: context.l10n.delete,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );
    if (result?.action == ButtonAction.first && context.mounted) {
      final dialog = createProgressDialog(
        context,
        context.l10n.deletingShareLink,
        isDismissible: false,
      );

      try {
        await dialog.show();
        await LinksService.instance.deleteLink(fileID);
        await dialog.hide();

        if (context.mounted) {
          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.shareLinkDeletedSuccessfully,
          );
        }
      } catch (e) {
        await dialog.hide();

        if (context.mounted) {
          SnackBarUtils.showWarningSnackBar(
            context,
            '${context.l10n.failedToDeleteShareLink}: ${e.toString()}',
          );
        }
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

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.fileDeletedSuccessfully,
      );
    } catch (e) {
      await dialog.hide();

      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToDeleteFile(e.toString()),
      );
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

  Future<void> _openFile(BuildContext context) async {
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
