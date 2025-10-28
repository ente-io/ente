import 'package:ente_ui/components/buttons/button_widget.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_file.dart';
import 'package:locker/services/trash/trash_service.dart';
import "package:locker/ui/components/delete_confirmation_dialog.dart";
import 'package:locker/ui/components/file_restore_dialog.dart';
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
    final colorScheme = getEnteColorScheme(context);
    return [
      OverflowMenuAction(
        id: 'restore',
        label: context.l10n.restore,
        icon: Icon(
          Icons.restore,
          color: colorScheme.textBase,
          size: 20,
        ),
        onTap: (context, file, collection) {
          _restoreFile(context, file!);
        },
      ),
      OverflowMenuAction(
        id: 'delete',
        label: context.l10n.delete,
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedDelete01,
          color: colorScheme.warning500,
          size: 20,
        ),
        onTap: (context, file, collection) {
          _deleteFilePermanently(context, file!);
        },
        isWarning: true,
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

    final dialogResult = await showFileRestoreDialog(
      context,
      file: file,
      collections: availableCollections,
    );

    if (dialogResult != null && dialogResult.selectedCollections.isNotEmpty) {
      await _performRestore(
        context,
        file,
        dialogResult.selectedCollections.first,
      );
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
    final result = await showDeleteConfirmationDialog(
      context,
      title: context.l10n.emptyTrash,
      body: context.l10n.emptyTrashConfirmation,
      deleteButtonLabel: context.l10n.emptyTrash,
      assetPath: "assets/collection_delete_icon.png",
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      appBar: AppBar(
        backgroundColor: colorScheme.backgroundBase,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
      ),
      body: _buildBody(colorScheme, textTheme),
    );
  }

  Widget _buildBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
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
                style: textTheme.large.copyWith(
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
      child: Column(
        children: [
          TitleBarTitleWidget(
            title: context.l10n.trash,
            trailingWidgets: [
              GestureDetector(
                onTap: () async {
                  await _emptyTrash();
                },
                child: Container(
                  height: 48,
                  width: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: colorScheme.backdropBase,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.delete_outline,
                    color: colorScheme.textBase,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.zero,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: ItemListView(
                      files: _sortedTrashFiles.cast<EnteFile>(),
                      fileOverflowActions: _getFileOverflowActions(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
