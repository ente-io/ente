import "package:ente_events/event_bus.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/events/collections_updated_event.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/selected_files.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/favorites_service.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/ui/components/add_to_collection_dialog.dart";
import "package:locker/ui/components/delete_confirmation_sheet.dart";
import "package:locker/ui/components/selection_action_button_widget.dart";
import "package:locker/utils/collection_list_util.dart";
import "package:locker/utils/file_actions.dart";
import "package:locker/utils/file_util.dart";
import "package:logging/logging.dart";

class FileSelectionOverlayBar extends StatefulWidget {
  final SelectedFiles selectedFiles;
  final List<EnteFile> files;
  final CollectionViewType? collectionViewType;
  final ScrollController? scrollController;

  const FileSelectionOverlayBar({
    required this.selectedFiles,
    required this.files,
    this.collectionViewType,
    this.scrollController,
    super.key,
  });

  @override
  State<FileSelectionOverlayBar> createState() =>
      _FileSelectionOverlayBarState();
}

class _FileSelectionOverlayBarState extends State<FileSelectionOverlayBar> {
  static final Logger _logger = Logger("FileSelectionOverlayBar");

  static const double _scrollThreshold = 10.0;

  bool _isExpanded = true;
  double _lastScrollPosition = 0;
  int _previousSelectionCount = 0;

  bool get _hasSelection => widget.selectedFiles.files.isNotEmpty;

  List<EnteFile> _getOwnedFiles(List<EnteFile> files) {
    final currentUserID = Configuration.instance.getUserID();
    final ownedFiles =
        files.where((file) => file.ownerID == currentUserID).toList();

    final sharedCount = files.length - ownedFiles.length;
    if (sharedCount > 0 && mounted) {
      showToast(
        context,
        "Action is not supported for $sharedCount shared file${sharedCount > 1 ? 's' : ''}",
      );
    }

    return ownedFiles;
  }

  @override
  void initState() {
    super.initState();
    widget.selectedFiles.addListener(_onSelectionChanged);
    widget.scrollController?.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_onSelectionChanged);
    widget.scrollController?.removeListener(_onScroll);
    super.dispose();
  }

  void _onSelectionChanged() {
    if (!mounted) return;

    final currentCount = widget.selectedFiles.files.length;
    final isFirstSelection = _previousSelectionCount == 0 && currentCount > 0;

    if (isFirstSelection) {
      setState(() => _isExpanded = true);
    } else {
      setState(() {});
    }

    _previousSelectionCount = currentCount;
  }

  void _onScroll() {
    final controller = widget.scrollController;
    if (!mounted || controller == null || !_hasSelection) return;

    final position = controller.position;
    final current = position.pixels;

    if (current < 0 || current > position.maxScrollExtent) return;

    final delta = current - _lastScrollPosition;
    if (delta.abs() < _scrollThreshold) return;

    _lastScrollPosition = current;

    final shouldCollapse = delta > 0 && _isExpanded;
    final shouldExpand = delta < 0 && !_isExpanded;

    if (shouldCollapse || shouldExpand) {
      setState(() => _isExpanded = !_isExpanded);
    }
  }

  bool get showFileSelectionOverlayBar {
    final viewType = widget.collectionViewType;
    if (viewType == null) return true;

    return viewType != CollectionViewType.sharedCollectionViewer &&
        viewType != CollectionViewType.sharedCollectionCollaborator &&
        viewType != CollectionViewType.quickLink &&
        viewType != CollectionViewType.favorite;
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
                    onVerticalDragUpdate: (details) {
                      if (details.primaryDelta != null) {
                        if (details.primaryDelta! < -5 && !_isExpanded) {
                          setState(() => _isExpanded = true);
                        } else if (details.primaryDelta! > 5 && _isExpanded) {
                          setState(() => _isExpanded = false);
                        }
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.backdropBase.withValues(alpha: 1.0),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(color: colorScheme.strokeFaint),
                        ),
                      ),
                      margin: EdgeInsets.zero,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                ListenableBuilder(
                                  listenable: widget.selectedFiles,
                                  builder: (context, child) {
                                    final selectedSet =
                                        widget.selectedFiles.files;
                                    final isAllSelected =
                                        widget.files.isNotEmpty &&
                                            widget.files.every(
                                              (file) =>
                                                  selectedSet.contains(file),
                                            );
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
                                          horizontal: 12.0,
                                          vertical: 10.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              buttonText,
                                              style: textTheme.small,
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              iconData,
                                              color: colorScheme.textBase,
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
                                          horizontal: 12.0,
                                          vertical: 10.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              countText,
                                              style: textTheme.small,
                                            ),
                                            const SizedBox(width: 6),
                                            Icon(
                                              Icons.close,
                                              color: colorScheme.textBase,
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
                            const SizedBox(height: 12),
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
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 250),
                crossFadeState: _isExpanded
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Column(
                  children: [
                    const SizedBox(height: 12),
                    _buildSecondaryActionRow(selectedFiles),
                  ],
                ),
                secondChild: const SizedBox.shrink(),
              ),
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

    final isImportant =
        isSingleSelection && FavoritesService.instance.isFavoriteCache(file!);

    return Row(
      children: [
        Expanded(
          child: SelectionActionButton(
            hugeIcon: const HugeIcon(
              icon: HugeIcons.strokeRoundedDownload01,
            ),
            label: context.l10n.save,
            onTap: () => isSingleSelection
                ? _downloadFile(context, file!)
                : _downloadMultipleFiles(context, files),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SelectionActionButton(
            icon: isImportant ? Icons.star_rounded : Icons.star_border_rounded,
            label:
                isImportant ? context.l10n.unimportant : context.l10n.important,
            onTap: () => isSingleSelection
                ? _markImportant(context, file!)
                : _markMultipleImportant(context, files),
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
                : _deleteMultipleFiles(context, files),
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
      child: Row(
        children: _buildActionRow(actions),
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
          onTap: () => _editFile(context, file!),
        ),
      );
    }

    if (isSingleSelection) {
      actions.add(
        SelectionActionButton(
          hugeIcon: const HugeIcon(
            icon: HugeIcons.strokeRoundedNavigation06,
          ),
          label: context.l10n.share,
          onTap: () => _shareFileLink(context, file!),
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

  Future<void> _downloadFile(BuildContext context, EnteFile file) async {
    final currentUserID = Configuration.instance.getUserID();
    if (file.ownerID != currentUserID) {
      showToast(context, "Download is not supported for shared files");
      return;
    }
    try {
      final success = await FileUtil.downloadFile(context, file);
      if (success) {
        widget.selectedFiles.clearAll();
      }
    } catch (e, stackTrace) {
      _logger.severe("Failed to download file: $e", e, stackTrace);
      if (context.mounted) {
        showToast(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    }
  }

  Future<void> _downloadMultipleFiles(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final ownedFiles = _getOwnedFiles(files);
    if (ownedFiles.isEmpty) {
      return;
    }

    try {
      final success = await FileUtil.downloadFiles(context, ownedFiles);
      if (success) {
        widget.selectedFiles.clearAll();
      }
    } catch (e, stackTrace) {
      _logger.severe("Failed to download files: $e", e, stackTrace);
      if (context.mounted) {
        showToast(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    }
  }

  Future<void> _shareFileLink(BuildContext context, EnteFile file) async {
    final currentUserID = Configuration.instance.getUserID();
    if (file.ownerID != currentUserID) {
      showToast(context, "Share is not supported for shared files");
      return;
    }
    await FileActions.shareFileLink(context, file);
  }

  Future<void> _editFile(BuildContext context, EnteFile file) async {
    final currentUserID = Configuration.instance.getUserID();
    if (file.ownerID != currentUserID) {
      showToast(context, "Edit is not supported for shared files");
      return;
    }
    await FileActions.editFile(context, file);
    widget.selectedFiles.clearAll();
  }

  Future<void> _showAddToDialog(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final ownedFiles = _getOwnedFiles(files);
    if (ownedFiles.isEmpty) {
      return;
    }

    _logger.info(
      'Opening add-to dialog for ${ownedFiles.length} file(s); fetching collections.',
    );

    final allCollections =
        await CollectionService.instance.getCollectionsForUI();
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

        for (final file in ownedFiles) {
          _logger.fine(
            'Processing file ${file.uploadedFileID} for add-to operation',
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
          widget.selectedFiles.clearAll();
          showToast(
            context,
            context.l10n.noChangesWereMade,
          );
          return;
        }

        await Future.wait(addFutures);
        await CollectionService.instance.sync();
        _logger.info(
          'Completed add-to operation for ${ownedFiles.length} file(s).',
        );

        await dialog.hide();

        widget.selectedFiles.clearAll();

        showToast(
          context,
          context.l10n.fileUpdatedSuccessfully,
        );
      } catch (e) {
        await dialog.hide();
        _logger.severe(
          'Failed add-to operation: $e',
        );

        showToast(
          context,
          context.l10n.failedToUpdateFile(e.toString()),
        );
      }
    }
  }

  Future<void> _deleteFile(BuildContext context, EnteFile file) async {
    final currentUserID = Configuration.instance.getUserID();
    if (file.ownerID != currentUserID) {
      showToast(context, "Delete is not supported for shared files");
      return;
    }
    await FileActions.deleteFile(
      context,
      file,
      onSuccess: () {
        widget.selectedFiles.clearAll();
        Bus.instance.fire(CollectionsUpdatedEvent('file_deleted'));
      },
    );
  }

  Future<void> _deleteMultipleFiles(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final ownedFiles = _getOwnedFiles(files);
    if (ownedFiles.isEmpty) {
      return;
    }

    final confirmation = await showDeleteConfirmationSheet(
      context,
      title: context.l10n.areYouSure,
      body: context.l10n.deleteMultipleFilesDialogBody(ownedFiles.length),
      deleteButtonLabel: context.l10n.yesDeleteFiles(ownedFiles.length),
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

      for (final file in ownedFiles) {
        final collections =
            await CollectionService.instance.getCollectionsForFile(file);

        if (collections.isNotEmpty) {
          await CollectionService.instance.trashFile(file, collections.first);
        }
      }

      await dialog.hide();

      widget.selectedFiles.clearAll();

      showToast(
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

  Future<void> _markImportant(BuildContext context, EnteFile file) async {
    final currentUserID = Configuration.instance.getUserID();
    if (file.ownerID != currentUserID) {
      showToast(context, "Important is not supported for shared files");
      return;
    }
    await FileActions.markImportant(
      context,
      file,
      onSuccess: () {
        widget.selectedFiles.clearAll();
        Bus.instance.fire(CollectionsUpdatedEvent('file_important_toggled'));
      },
    );
  }

  Future<void> _markMultipleImportant(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    final ownedFiles = _getOwnedFiles(files);
    if (ownedFiles.isEmpty) {
      return;
    }

    await FileActions.markMultipleImportant(
      context,
      ownedFiles,
      onSuccess: () {
        widget.selectedFiles.clearAll();
        Bus.instance.fire(CollectionsUpdatedEvent('files_marked_important'));
      },
    );
  }
}
