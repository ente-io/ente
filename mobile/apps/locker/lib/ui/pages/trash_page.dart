import 'package:ente_ui/components/buttons/button_widget.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import 'package:ente_ui/utils/dialog_util.dart';
import 'package:ente_ui/utils/toast_util.dart';
import 'package:flutter/material.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/models/trash_file.dart';
import 'package:locker/services/trash/trash_service.dart';
import "package:locker/ui/components/delete_confirmation_sheet.dart";
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/file_restore_dialog.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/utils/collection_list_util.dart';

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

  void _restoreFile(BuildContext context, EnteFile file) async {
    final collections = await CollectionService.instance.getCollectionsForUI();

    final availableCollections = uniqueCollectionsById(collections);

    if (availableCollections.isEmpty) {
      showToast(
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
      showToast(
        context,
        context.l10n.deletedPermanently(file.displayName),
      );
    }).catchError((error) {
      showToast(
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

      showToast(
        context,
        context.l10n.restoredFileToCollection(
          file.displayName,
          targetCollection.name ?? 'Unnamed Collection',
        ),
      );
    } catch (error) {
      await dialog.hide();

      showToast(
        context,
        context.l10n.failedToRestoreFile(file.displayName, error.toString()),
      );
    }
  }

  Future<void> _emptyTrash() async {
    final result = await showDeleteConfirmationSheet(
      context,
      title: context.l10n.emptyTrash,
      body: context.l10n.emptyTrashConfirmation,
      deleteButtonLabel: context.l10n.emptyTrash,
      assetPath: "assets/collection_delete_icon.png",
    );

    if (result?.buttonResult.action == ButtonAction.first && context.mounted) {
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
      showToast(
        context,
        context.l10n.trashClearedSuccessfully,
      );
      Navigator.of(context).pop();
    } catch (error) {
      showToast(
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
      body: _buildBody(context, colorScheme, textTheme),
    );
  }

  Widget _buildBody(
    BuildContext context,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
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
                  height: 44,
                  width: 44,
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
          _sortedTrashFiles.isEmpty
              ? EmptyStateWidget(
                  assetPath: 'assets/empty_state.png',
                  title: context.l10n.yourTrashIsEmpty,
                  showBorder: false,
                )
              : Expanded(
                  child: ItemListView(
                    files: _sortedTrashFiles.cast<EnteFile>(),
                    physics: const BouncingScrollPhysics(),
                  ),
                ),
        ],
      ),
    );
  }
}
