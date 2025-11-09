import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/favorites_service.dart";
import "package:locker/services/files/links/links_service.dart";
import "package:locker/services/files/sync/metadata_updater_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/add_to_collection_dialog.dart";
import "package:locker/ui/components/delete_confirmation_dialog.dart";
import "package:locker/ui/components/file_edit_dialog.dart";
import "package:locker/ui/components/selection_action_button_widget.dart";
import "package:locker/ui/components/share_link_dialog.dart";
import "package:locker/utils/collection_list_util.dart";
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
                            const SizedBox(height: 20),
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
    return ListenableBuilder(
      listenable: widget.selectedFiles,
      builder: (context, child) {
        final selectedFiles = widget.selectedFiles.files;
        if (selectedFiles.isEmpty) {
          return const SizedBox.shrink();
        }

        return AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPrimaryActionRow(selectedFiles),
              const SizedBox(height: 12),
              _buildSecondaryActionRow(selectedFiles),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrimaryActionRow(Set<EnteFile> selectedFiles) {
    final isSingleSelection = selectedFiles.length == 1;
    final files = selectedFiles.toList();
    final file = isSingleSelection ? files.first : null;
    final colorScheme = getEnteColorScheme(context);

    return Row(
      children: [
        Expanded(
          child: SelectionActionButton(
            hugeIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
            ),
            label: "Download",
            onTap: () => isSingleSelection
                ? _downloadFile(context, file!)
                : _downloadMultipleFiles(context, files),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectionActionButton(
            hugeIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedNavigation06,
            ),
            label: context.l10n.share,
            onTap: () => isSingleSelection
                ? _shareLink(context, file!)
                : _shareMultipleFiles(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectionActionButton(
            hugeIcon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: colorScheme.warning500,
            ),
            label: context.l10n.delete,
            onTap: () => isSingleSelection
                ? _deleteFile(context, file!)
                : _deleteMultipleFile(context, files),
            isDestructive: true,
          ),
        ),
      ],
    );
  }

  Widget _buildSecondaryActionRow(Set<EnteFile> selectedFiles) {
    final actions = _getSecondaryActionsForSelection(selectedFiles);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: Row(
          key: ValueKey('secondary_${selectedFiles.length}'),
          children: _buildActionRow(actions),
        ),
      ),
    );
  }

  List<Widget> _buildActionRow(List<Widget> actions) {
    final children = <Widget>[];
    for (var i = 0; i < actions.length; i++) {
      children.add(Expanded(child: actions[i]));
      if (i != actions.length - 1) {
        children.add(const SizedBox(width: 12));
      }
    }
    return children;
  }

  List<Widget> _getSecondaryActionsForSelection(Set<EnteFile> selectedFiles) {
    final isSingleSelection = selectedFiles.length == 1;
    final file = isSingleSelection ? selectedFiles.first : null;
    final files = selectedFiles.toList();
    final actions = <Widget>[];

    if (isSingleSelection) {
      actions.add(
        SelectionActionButton(
          hugeIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedPencilEdit02,
          ),
          label: context.l10n.edit,
          onTap: () => _showEditDialog(context, file!),
        ),
      );
      actions.add(
        SelectionActionButton(
          hugeIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
          ),
          label: _isImportant ? "Unmark" : "Important",
          onTap: () => _toggleImportant(context, file!),
        ),
      );
    } else {
      actions.add(
        SelectionActionButton(
          hugeIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedStar,
          ),
          label: "Important",
          onTap: () => _markMultipleAsImportant(context, files),
        ),
      );
    }

    actions.add(
      SelectionActionButton(
        hugeIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight03,
        ),
        label: "Add to",
        onTap: () => _showAddToDialog(context, files),
      ),
    );

    return actions;
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

    _logger.info(
      'Opening add-to dialog for ${files.length} file(s); fetching collections.',
    );
    final allCollections = await CollectionService.instance.getCollections();
    final dedupedCollections = uniqueCollectionsById(allCollections);
    _logger.info(
      'Presenting ${dedupedCollections.length} unique collection option(s) '
      'to add files to.',
    );

    final result = await showAddToCollectionDialog(
      context,
      collections: dedupedCollections,
      snackBarContext: context,
    );

    if (result != null && context.mounted) {
      _logger.info(
        'Add-to dialog submitted with '
        '${result.selectedCollections.length} selected collection(s).',
      );
      final dialog = createProgressDialog(
        context,
        context.l10n.pleaseWait,
        isDismissible: false,
      );

      await dialog.show();

      try {
        final addFutures = <Future<void>>[];

        for (final file in files) {
          _logger.fine(
            'Processing file ${file.uploadedFileID} (${file.displayName}) '
            'for add-to operation.',
          );
          List<Collection> currentCollections;
          try {
            currentCollections =
                await CollectionService.instance.getCollectionsForFile(file);
          } catch (_) {
            _logger.warning(
              'Failed to fetch existing collections for file ${file.uploadedFileID}',
            );
            currentCollections = <Collection>[];
          }

          final currentCollectionIds =
              currentCollections.map((collection) => collection.id).toSet();

          final collectionsToAdd = result.selectedCollections.where(
            (collection) => !currentCollectionIds.contains(collection.id),
          );

          for (final collection in collectionsToAdd) {
            _logger.fine(
              'Adding file ${file.uploadedFileID} to collection ${collection.id}.',
            );
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
        _logger.info(
          'Completed add-to operation for ${files.length} file(s).',
        );

        await dialog.hide();

        widget.selectedFiles.clearAll();

        SnackBarUtils.showInfoSnackBar(
          context,
          context.l10n.fileUpdatedSuccessfully,
        );
      } catch (e) {
        await dialog.hide();
        _logger.severe(
          'Failed add-to operation: $e',
        );

        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.failedToUpdateFile(e.toString()),
        );
      }
    }
  }

  Future<void> _deleteFile(BuildContext context, EnteFile file) async {
    final confirmation = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(1),
      deleteButtonLabel: context.l10n.yesDeleteFiles(1),
      assetPath: "assets/file_delete_icon.png",
    );

    if (confirmation?.buttonResult.action != ButtonAction.first) {
      return;
    }

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

      widget.selectedFiles.clearAll();

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.fileDeletedSuccessfully,
      );
    } catch (e, stackTrace) {
      await dialog.hide();

      _logger.severe(
        'Failed to delete file ${file.uploadedFileID}: $e',
        e,
        stackTrace,
      );
      if (!context.mounted) {
        return;
      }
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _deleteMultipleFile(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    if (files.isEmpty) {
      return;
    }

    final confirmation = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(files.length),
      deleteButtonLabel: context.l10n.yesDeleteFiles(files.length),
      assetPath: "assets/file_delete_icon.png",
    );

    if (confirmation?.buttonResult.action != ButtonAction.first) {
      return;
    }

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

      widget.selectedFiles.clearAll();

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.fileDeletedSuccessfully,
      );
    } catch (e, stackTrace) {
      await dialog.hide();

      _logger.severe(
        'Failed to delete files via selection bar: $e',
        e,
        stackTrace,
      );
      if (!context.mounted) {
        return;
      }
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<void> _downloadFile(BuildContext context, EnteFile file) async {
    try {
      final success = await FileUtil.downloadFilesToDownloads(context, [file]);
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
