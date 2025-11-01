import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/favorites_service.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/add_to_collection_dialog.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/selection_action_button_widget.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/utils/file_util.dart";
import "package:locker/utils/snack_bar_utils.dart";
import "package:logging/logging.dart";

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
  static final Logger _logger = Logger("FileSelectionOverlayBar");
  bool _isImportant = false;

  @override
  void initState() {
    super.initState();
    widget.selectedFiles.addListener(_onSelectionChanged);
    _checkIfImportant();
  }

  Future<void> _checkIfImportant() async {
    if (widget.selectedFiles.files.length == 1) {
      final file = widget.selectedFiles.files.first;

      try {
        final isFav = await FavoritesService.instance.isFavorite(file);

        if (mounted) {
          setState(() {
            _isImportant = isFav;
          });
        }
      } catch (e) {
        _logger.severe("Error checking favorite status: $e");
      }
    }
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (mounted) {
      setState(() {});
      _checkIfImportant();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final hasSelection = widget.selectedFiles.files.isNotEmpty;

    return IgnorePointer(
      ignoring: !hasSelection,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          offset: hasSelection ? Offset.zero : const Offset(0, 1),
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 250),
            opacity: hasSelection ? 1.0 : 0.0,
            curve: Curves.easeInOut,
            child: hasSelection
                ? GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragUpdate: (_) {},
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.backdropBase,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        border: Border(
                          top: BorderSide(color: colorScheme.strokeFaint),
                        ),
                      ),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding:
                            EdgeInsets.fromLTRB(16, 16, 16, 28 + bottomPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                ListenableBuilder(
                                  listenable: widget.selectedFiles,
                                  builder: (context, child) {
                                    final isAllSelected =
                                        widget.selectedFiles.count ==
                                            widget.files.length;
                                    final buttonText = isAllSelected
                                        ? context.l10n.deselectAll
                                        : context.l10n.selectAll;
                                    final iconData = isAllSelected
                                        ? Icons.remove_circle_outline
                                        : Icons.check_circle_outline_outlined;

                                    return InkWell(
                                      onTap: () {
                                        if (isAllSelected) {
                                          widget.selectedFiles.clearAll();
                                        } else {
                                          widget.selectedFiles
                                              .selectAll(widget.files.toSet());
                                        }
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              colorScheme.backgroundElevated2,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 14.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              buttonText,
                                              style: textTheme.body,
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              iconData,
                                              color: getEnteColorScheme(context)
                                                  .textBase,
                                              size: 20,
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
                                    final countText = count == 1
                                        ? '1 selected'
                                        : '$count selected';

                                    return InkWell(
                                      onTap: () {
                                        widget.selectedFiles.clearAll();
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color:
                                              colorScheme.backgroundElevated2,
                                          borderRadius:
                                              BorderRadius.circular(50),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16.0,
                                          vertical: 14.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              countText,
                                              style: textTheme.body,
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.close,
                                              color: getEnteColorScheme(context)
                                                  .textBase,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildActionButtons(),
                          ],
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final selectedFiles = widget.selectedFiles.files;
    if (selectedFiles.isEmpty) {
      return const SizedBox.shrink();
    }

    final isSingleSelection = selectedFiles.length == 1;
    final file = isSingleSelection ? selectedFiles.first : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildPrimaryActionRow(selectedFiles.toList()),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeInOut,
          switchOutCurve: Curves.easeInOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                child: child,
              ),
            );
          },
          child: isSingleSelection
              ? _buildSingleSelectionSecondaryRow(file!)
              : _buildMultiSelectionSecondaryRow(selectedFiles.toList()),
        ),
      ],
    );
  }

  Widget _buildPrimaryActionRow(List<EnteFile> files) {
    final isSingle = files.length == 1;
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: SelectionActionButton(
                icon: Icons.download_outlined,
                label: "Download",
                onTap: () => isSingle
                    ? _downloadFile(context, files.first)
                    : _downloadMultipleFiles(context, files),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionActionButton(
                icon: Icons.share_outlined,
                label: context.l10n.share,
                onTap: () => isSingle
                    ? _shareLink(context, files.first)
                    : _shareMultipleFiles(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionActionButton(
                icon: Icons.delete_outline,
                label: context.l10n.delete,
                onTap: () => isSingle
                    ? _deleteFile(context, files.first)
                    : _deleteMultipleFile(context, files),
                isDestructive: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleSelectionSecondaryRow(EnteFile file) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      key: const ValueKey('single_selection_secondary'),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: SelectionActionButton(
                icon: Icons.edit_outlined,
                label: context.l10n.edit,
                onTap: () => _showEditDialog(context, file),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionActionButton(
                icon: _isImportant ? Icons.star : Icons.star_outline,
                label: _isImportant ? "Unmark" : "Important",
                onTap: () => _toggleImportant(context, file),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionActionButton(
                icon: Icons.start_rounded,
                label: "Add to",
                onTap: () => _showAddToDialog(context, [file]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultiSelectionSecondaryRow(List<EnteFile> files) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      key: const ValueKey('multi_selection_secondary'),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: SelectionActionButton(
                icon: Icons.star_outline,
                label: "Important",
                onTap: () => _markMultipleAsImportant(context, files),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SelectionActionButton(
                icon: Icons.start_rounded,
                label: "Add to",
                onTap: () => _showAddToDialog(context, files),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadMultipleFiles(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    try {
      final success = await FileUtil.downloadFilesToDownloads(context, files);
      if (success) {
        widget.selectedFiles.clearAll();
      }
    } catch (e, stackTrace) {
      _logger.severe("Failed to download files: $e", e, stackTrace);
      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    }
  }

  void _shareMultipleFiles(BuildContext context) {
    SnackBarUtils.showWarningSnackBar(
      context,
      "Sharing multiple files is coming soon",
    );
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

  Future<void> _showAddToDialog(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }

    final allCollections = await CollectionService.instance.getCollections();

    final result = await showAddToCollectionDialog(
      context,
      collections: allCollections,
    );

    if (result != null && context.mounted) {
      final dialog = createProgressDialog(
        context,
        context.l10n.pleaseWait,
        isDismissible: false,
      );

      await dialog.show();

      try {
        final addFutures = <Future<void>>[];

        for (final file in files) {
          List<Collection> currentCollections;
          try {
            currentCollections =
                await CollectionService.instance.getCollectionsForFile(file);
          } catch (_) {
            currentCollections = <Collection>[];
          }

          final currentCollectionIds =
              currentCollections.map((collection) => collection.id).toSet();

          final collectionsToAdd = result.selectedCollections.where(
            (collection) => !currentCollectionIds.contains(collection.id),
          );

          for (final collection in collectionsToAdd) {
            addFutures.add(
              CollectionService.instance.addToCollection(
                collection,
                file,
                runSync: false,
              ),
            );
          }
        }

        if (addFutures.isEmpty) {
          await dialog.hide();
          SnackBarUtils.showInfoSnackBar(
            context,
            context.l10n.noChangesWereMade,
          );
          return;
        }

        await Future.wait(addFutures);
        await CollectionService.instance.sync();

        await dialog.hide();

        widget.selectedFiles.clearAll();

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

  Future<void> _downloadFile(BuildContext context, EnteFile file) async {
    try {
      final success =
          await FileUtil.downloadFilesToDownloads(context, [file]);
      if (success) {
        widget.selectedFiles.clearAll();
      }
    } catch (e, stackTrace) {
      _logger.severe("Failed to download file: $e", e, stackTrace);
      if (context.mounted) {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    }
  }

  Future<void> _toggleImportant(BuildContext context, EnteFile file) async {
    final dialog = createProgressDialog(
      context,
      _isImportant ? "Removing from Important..." : "Adding to Important...",
      isDismissible: false,
    );

    try {
      await dialog.show();

      if (_isImportant) {
        await FavoritesService.instance.removeFromFavorites(context, file);
      } else {
        await FavoritesService.instance.addToFavorites(context, file);
      }

      await dialog.hide();
      widget.selectedFiles.clearAll();

      setState(() {
        _isImportant = !_isImportant;
      });

      if (context.mounted) {
        final message = _isImportant
            ? "File marked as important"
            : "File removed from important";
        SnackBarUtils.showInfoSnackBar(context, message);
      }
    } catch (e, stackTrace) {
      _logger.severe("Failed to toggle important status: $e", e, stackTrace);
      await dialog.hide();

      if (context.mounted) {
        final errorMessage =
            'Failed to update important status: ${e.toString()}';
        SnackBarUtils.showWarningSnackBar(context, errorMessage);
      }
    }
  }

  Future<void> _markMultipleAsImportant(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final dialog = createProgressDialog(
      context,
      "Marking as Important...",
      isDismissible: false,
    );

    try {
      await dialog.show();

      final List<EnteFile> filesToMark = [];
      for (final file in files) {
        final isFav = await FavoritesService.instance.isFavorite(file);
        if (!isFav) {
          filesToMark.add(file);
        }
      }

      if (filesToMark.isEmpty) {
        await dialog.hide();
        if (context.mounted) {
          SnackBarUtils.showInfoSnackBar(
            context,
            "All files are already marked as important",
          );
        }
        return;
      }

      await FavoritesService.instance.updateFavorites(
        context,
        filesToMark,
        true,
      );

      await dialog.hide();

      widget.selectedFiles.clearAll();

      if (context.mounted) {
        final message = filesToMark.length == 1
            ? "1 file marked as important"
            : "${filesToMark.length} files marked as important";
        SnackBarUtils.showInfoSnackBar(context, message);
      }
    } catch (e, stackTrace) {
      _logger.severe(
        "Failed to mark multiple files as important: $e",
        e,
        stackTrace,
      );
      await dialog.hide();

      if (context.mounted) {
        final errorMessage =
            'Failed to mark files as important: ${e.toString()}';
        SnackBarUtils.showWarningSnackBar(context, errorMessage);
      }
    }
  }
}
