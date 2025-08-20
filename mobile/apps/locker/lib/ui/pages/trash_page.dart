import 'package:ente_ui/components/buttons/button_widget.dart';
import 'package:ente_ui/components/buttons/models/button_type.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_file.dart';
import 'package:locker/services/trash/trash_service.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/utils/snack_bar_utils.dart';

class TrashPage extends StatefulWidget {
  final List<TrashFile> trashFiles;

  const TrashPage({
    super.key,
    required this.trashFiles,
  });

  @override
  State<TrashPage> createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  List<TrashFile> _sortedTrashFiles = [];
  List<TrashFile> _allTrashFiles = [];

  @override
  void initState() {
    super.initState();
    _allTrashFiles = List.from(widget.trashFiles);
    _sortedTrashFiles = List.from(widget.trashFiles);
  }

  List<OverflowMenuAction> _getFileOverflowActions() {
    return [
      OverflowMenuAction(
        id: 'restore',
        label: context.l10n.restore,
        icon: Icons.restore,
        onTap: (context, file, collection) {
          _restoreFile(context, file!);
        },
      ),
      OverflowMenuAction(
        id: 'delete',
        label: context.l10n.delete,
        icon: Icons.delete_forever,
        onTap: (context, file, collection) {
          _deleteFilePermanently(context, file!);
        },
      ),
    ];
  }

  void _restoreFile(BuildContext context, EnteFile file) async {
    final collections = await CollectionService.instance.getCollections();

    final availableCollections = collections
        .where((c) => !c.isDeleted && c.type != CollectionType.uncategorized)
        .toList();

    if (availableCollections.isEmpty) {
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.noCollectionsAvailableForRestore,
      );
      return;
    }

    final selectedCollection = await _showCollectionPickerDialog(
      context,
      availableCollections,
      file.displayName,
    );

    if (selectedCollection != null) {
      await _performRestore(context, file, selectedCollection);
    }
  }

  void _deleteFilePermanently(BuildContext context, EnteFile file) {
    TrashService.instance.deleteFromTrash([file]).then((_) {
      setState(() {
        _sortedTrashFiles.remove(file);
        _allTrashFiles.remove(file);
      });
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.deletedPermanently(file.displayName),
      );
    }).catchError((error) {
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToDeleteFile(error.toString()),
      );
    });
  }

  Future<Collection?> _showCollectionPickerDialog(
    BuildContext context,
    List<Collection> collections,
    String fileName,
  ) async {
    return showDialog<Collection>(
      context: context,
      barrierColor: getEnteColorScheme(context).backdropBase,
      builder: (context) => _CollectionPickerDialog(
        collections: collections,
        fileName: fileName,
      ),
    );
  }

  Future<void> _performRestore(
    BuildContext context,
    EnteFile file,
    Collection targetCollection,
  ) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.restoring,
      isDismissible: false,
    );

    try {
      await dialog.show();

      await TrashService.instance.restore([file], targetCollection);

      setState(() {
        _sortedTrashFiles.remove(file);
        _allTrashFiles.remove(file);
      });

      await dialog.hide();

      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.restoredFileToCollection(
          file.displayName,
          targetCollection.name ?? 'Unnamed Collection',
        ),
      );
    } catch (error) {
      await dialog.hide();

      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToRestoreFile(file.displayName, error.toString()),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final result = await showChoiceDialog(
      context,
      title: context.l10n.emptyTrash,
      body: context.l10n.emptyTrashConfirmation,
      firstButtonLabel: context.l10n.emptyTrash,
      secondButtonLabel: context.l10n.cancel,
      firstButtonType: ButtonType.critical,
      isCritical: true,
    );

    if (result?.action == ButtonAction.first && context.mounted) {
      await _performEmptyTrash();
    }
  }

  Future<void> _performEmptyTrash() async {
    final dialog = createProgressDialog(
      context,
      context.l10n.clearingTrash,
      isDismissible: false,
    );
    await dialog.show();
    try {
      await TrashService.instance.emptyTrash();
      setState(() {
        _sortedTrashFiles.clear();
        _allTrashFiles.clear();
      });
      SnackBarUtils.showInfoSnackBar(
        context,
        context.l10n.trashClearedSuccessfully,
      );
      Navigator.of(context).pop();
    } catch (error) {
      SnackBarUtils.showWarningSnackBar(
        context,
        context.l10n.failedToClearTrash(error.toString()),
      );
    } finally {
      await dialog.hide();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.trash),
        centerTitle: false,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _emptyTrash,
            tooltip: context.l10n.emptyTrashTooltip,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_sortedTrashFiles.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.delete_outline,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.trashIsEmpty,
                style: getEnteTextTheme(context).large.copyWith(
                      color: Colors.grey,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ItemListView(
        files: _sortedTrashFiles.cast<EnteFile>(),
        enableSorting: true,
        fileOverflowActions: _getFileOverflowActions(),
      ),
    );
  }
}

class _CollectionPickerDialog extends StatefulWidget {
  final List<Collection> collections;
  final String fileName;

  const _CollectionPickerDialog({
    required this.collections,
    required this.fileName,
  });

  @override
  State<_CollectionPickerDialog> createState() =>
      _CollectionPickerDialogState();
}

class _CollectionPickerDialogState extends State<_CollectionPickerDialog> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Dialog(
      backgroundColor: colorScheme.backgroundElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.restore,
                  color: Colors.green,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.restoreFile(widget.fileName),
                    style: textTheme.largeBold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.strokeFaint),
                ),
                child: widget.collections.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Text(
                            context.l10n.noCollectionsAvailable,
                            style: textTheme.body.copyWith(
                              color: colorScheme.textMuted,
                            ),
                          ),
                        ),
                      )
                    : Scrollbar(
                        thumbVisibility: true,
                        thickness: 6,
                        radius: const Radius.circular(3),
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 3.5,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                          padding: const EdgeInsets.all(6),
                          itemCount: widget.collections.length,
                          itemBuilder: (context, index) {
                            final collection = widget.collections[index];
                            final collectionName =
                                collection.name ?? 'Unnamed Collection';

                            return InkWell(
                              onTap: () =>
                                  Navigator.of(context).pop(collection),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.fillFaint,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: colorScheme.strokeFaint,
                                    width: 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    collectionName,
                                    style: textTheme.small.copyWith(
                                      color: colorScheme.textBase,
                                      fontWeight: FontWeight.normal,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ButtonWidget(
                    buttonType: ButtonType.secondary,
                    labelText: context.l10n.cancel,
                    onTap: () async => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
