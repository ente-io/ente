import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/selection_action_button_widget.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/utils/snack_bar_utils.dart";

class FileSelectionOverlayBar extends StatefulWidget {
  final SelectedFiles selectedFiles;
  final List<EnteFile> files;
  const FileSelectionOverlayBar({
    required this.selectedFiles,
    required this.files,
    super.key,
  });

  @override
  State<FileSelectionOverlayBar> createState() =>
      _FileSelectionOverlayBarState();
}

class _FileSelectionOverlayBarState extends State<FileSelectionOverlayBar> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.4,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                ListenableBuilder(
                  listenable: widget.selectedFiles,
                  builder: (context, child) {
                    final isAllSelected =
                        widget.selectedFiles.count == widget.files.length;
                    final buttonText =
                        isAllSelected ? 'Deselect All' : 'Select All';
                    final iconData = isAllSelected
                        ? Icons.remove_circle_outline
                        : Icons.check_circle_outline_outlined;

                    return InkWell(
                      onTap: () {
                        if (isAllSelected) {
                          widget.selectedFiles.clearAll();
                        } else {
                          widget.selectedFiles.selectAll(widget.files.toSet());
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: isDarkMode
                              ? const Color.fromRGBO(27, 27, 27, 1)
                              : colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              buttonText,
                              style: getEnteTextTheme(context).bodyBold,
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              iconData,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const Spacer(),
                ListenableBuilder(
                  listenable: widget.selectedFiles,
                  builder: (context, child) {
                    final count = widget.selectedFiles.count;
                    final countText =
                        count == 1 ? '1 selected' : '$count selected';

                    return InkWell(
                      onTap: () {
                        widget.selectedFiles.clearAll();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.strokeMuted,
                            width: 0.5,
                          ),
                          borderRadius: BorderRadius.circular(50),
                          color: isDarkMode
                              ? const Color.fromRGBO(27, 27, 27, 1)
                              : colorScheme.backgroundElevated2,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              countText,
                              style: getEnteTextTheme(context).bodyBold,
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.close,
                              color: Colors.grey,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            elevation: 4,
            surfaceTintColor: isDarkMode
                ? const Color.fromRGBO(18, 18, 18, 1)
                : colorScheme.backgroundBase,
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.selectedFiles,
      builder: (context, child) {
        final selectedFiles = widget.selectedFiles.files;
        if (selectedFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        final actions = _getActionsForSelection(selectedFiles);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isDarkMode
                ? const Color.fromRGBO(255, 255, 255, 0.04)
                : getEnteColorScheme(context).backgroundElevated2,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: actions,
            ),
          ),
        );
      },
    );
  }

  List<Widget> _getActionsForSelection(Set<EnteFile> selectedFiles) {
    final isSingleSelection = selectedFiles.length == 1;
    final file = isSingleSelection ? selectedFiles.first : null;
    final actions = <Widget>[];

    if (isSingleSelection) {
      actions.addAll([
        SelectionActionButton(
          icon: Icons.share_outlined,
          label: context.l10n.share,
          onTap: () {
            _shareLink(context, file!);
          },
        ),
        SelectionActionButton(
          icon: Icons.edit_outlined,
          label: context.l10n.edit,
          onTap: () {
            _showEditDialog(context, file!);
          },
        ),
        SelectionActionButton(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          onTap: () {
            _deleteFile(context, file!);
          },
          isDestructive: true,
        ),
      ]);
    } else {
      actions.addAll([
        SelectionActionButton(
          icon: Icons.delete_outline,
          label: context.l10n.delete,
          onTap: () {
            _deleteMultipleFile(context, selectedFiles.toList());
          },
          isDestructive: true,
        ),
      ]);
    }
    return actions;
  }

  Future<void> _shareLink(BuildContext context, EnteFile file) async {
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

  Future<void> _showEditDialog(BuildContext context, EnteFile file) async {
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

  Future<void> _deleteFile(BuildContext context, EnteFile file) async {
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

  Future<void> _deleteMultipleFile(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.deletingFile,
      isDismissible: false,
    );

    try {
      await dialog.show();

      for (final file in files) {
        final collections =
            await CollectionService.instance.getCollectionsForFile(file);

        if (collections.isNotEmpty) {
          await CollectionService.instance.trashFile(file, collections.first);
        }
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
}
