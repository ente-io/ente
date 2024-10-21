import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import "package:photos/db/files_db.dart";
import 'package:photos/events/collection_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/remote_sync_service.dart";
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';

class DeleteEmptyAlbums extends StatefulWidget {
  final List<Collection> collections;
  const DeleteEmptyAlbums(this.collections, {Key? key}) : super(key: key);

  @override
  State<DeleteEmptyAlbums> createState() => _DeleteEmptyAlbumsState();
}

class _DeleteEmptyAlbumsState extends State<DeleteEmptyAlbums> {
  final ValueNotifier<String> _deleteProgress = ValueNotifier("");
  bool _isCancelled = false;

  @override
  void dispose() {
    _deleteProgress.dispose();
    super.dispose();
  }

  Future<bool> _showDeleteButton() async {
    if (!RemoteSyncService.instance.isFirstRemoteSyncDone()) {
      return Future.value(false);
    }
    final Map<int, int> collectionIDToLatestTimeCount =
        await CollectionsService.instance.getCollectionIDToNewestFileTime();
    final emptyAlbumCount = widget.collections
        .where((collection) {
          final latestTimeCount = collectionIDToLatestTimeCount[collection.id];
          return latestTimeCount == null;
        })
        .toList()
        .length;
    return emptyAlbumCount > 2;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _showDeleteButton(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!) {
          return _buildDeleteButton();
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDeleteButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8.5, 4, 8, 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ButtonWidget(
          buttonSize: ButtonSize.small,
          buttonType: ButtonType.secondary,
          labelText: S.of(context).deleteEmptyAlbums,
          icon: Icons.delete_sweep_outlined,
          shouldSurfaceExecutionStates: false,
          onTap: () async {
            await showActionSheet(
              context: context,
              isDismissible: true,
              buttons: [
                ButtonWidget(
                  labelText: S.of(context).yes,
                  buttonType: ButtonType.neutral,
                  buttonSize: ButtonSize.large,
                  shouldStickToDarkTheme: true,
                  shouldSurfaceExecutionStates: true,
                  progressStatus: _deleteProgress,
                  onTap: () async {
                    await _deleteEmptyAlbums();
                    if (!_isCancelled) {
                      Navigator.of(context).pop();
                    }
                    Bus.instance.fire(
                      CollectionUpdatedEvent(
                        0,
                        <EnteFile>[],
                        "empty_albums_deleted",
                      ),
                    );
                    CollectionsService.instance.sync().ignore();
                    _isCancelled = false;
                  },
                ),
                ButtonWidget(
                  labelText: S.of(context).cancel,
                  buttonType: ButtonType.secondary,
                  buttonSize: ButtonSize.large,
                  shouldStickToDarkTheme: true,
                  onTap: () async {
                    _isCancelled = true;
                    Navigator.of(context).pop();
                  },
                ),
              ],
              title: S.of(context).deleteEmptyAlbumsWithQuestionMark,
              body: S.of(context).deleteAlbumsDialogBody,
              actionSheetType: ActionSheetType.defaultActionSheet,
            );
          },
        ),
      ),
    );
  }

  Future<void> _deleteEmptyAlbums() async {
    final collections = CollectionsService.instance.getCollectionsForUI();
    final idToFileTimeStamp =
        await FilesDB.instance.getCollectionIDToMaxCreationTime();

    // remove collections which are not empty or can't be deleted
    collections.removeWhere(
      (c) => !c.type.canDelete || idToFileTimeStamp.containsKey(c.id),
    );
    int failedCount = 0;
    for (int i = 0; i < collections.length; i++) {
      if (mounted && !_isCancelled) {
        final String currentlyDeleting = (i + 1)
            .toString()
            .padLeft(collections.length.toString().length, '0');
        _deleteProgress.value =
            S.of(context).deleteProgress(currentlyDeleting, collections.length);
        try {
          await CollectionsService.instance.trashEmptyCollection(
            collections[i],
            isBulkDelete: true,
          );
        } catch (_) {
          failedCount++;
        }
      }
    }
    if (failedCount > 0) {
      debugPrint("Delete ops failed for $failedCount collections");
    }
  }
}
