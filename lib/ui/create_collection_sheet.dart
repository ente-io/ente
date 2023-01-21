import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/album_list_item_widget.dart';
import 'package:photos/ui/components/bottom_of_title_bar_widget.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum CollectionActionType { addFiles, moveFiles, restoreFiles, unHide }

String _actionName(CollectionActionType type, bool plural) {
  final titleSuffix = (plural ? "s" : "");
  String text = "";
  switch (type) {
    case CollectionActionType.addFiles:
      text = "Add item";
      break;
    case CollectionActionType.moveFiles:
      text = "Move item";
      break;
    case CollectionActionType.restoreFiles:
      text = "Restore item";
      break;
    case CollectionActionType.unHide:
      text = "Unhide item";
      break;
  }
  return text + titleSuffix;
}

void createCollectionSheet(
  SelectedFiles? selectedFiles,
  List<SharedMediaFile>? sharedFiles,
  BuildContext context, {
  CollectionActionType actionType = CollectionActionType.addFiles,
}) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return CreateCollectionSheet(
        selectedFiles: selectedFiles,
        sharedFiles: sharedFiles,
        actionType: actionType,
      );
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
    enableDrag: false,
  );
}

class CreateCollectionSheet extends StatefulWidget {
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final CollectionActionType actionType;
  const CreateCollectionSheet({
    required this.selectedFiles,
    required this.sharedFiles,
    required this.actionType,
    super.key,
  });

  @override
  State<CreateCollectionSheet> createState() => _CreateCollectionSheetState();
}

class _CreateCollectionSheetState extends State<CreateCollectionSheet> {
  final _logger = Logger((_CreateCollectionSheetState).toString());

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.sharedFiles != null
        ? widget.sharedFiles!.length
        : widget.selectedFiles!.files.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: min(428, MediaQuery.of(context).size.width),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BottomOfTitleBarWidget(
                  title: TitleBarTitleWidget(
                    title: _actionName(widget.actionType, filesCount > 1),
                  ),
                  caption: "Create or select album",
                ),
                Flexible(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 24, 4, 0),
                          child: Scrollbar(
                            radius: const Radius.circular(2),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: FutureBuilder(
                                future: _getCollectionsWithThumbnail(),
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    //Need to show an error on the UI here
                                    return const SizedBox.shrink();
                                  } else if (snapshot.hasData) {
                                    final collectionsWithThumbnail = snapshot
                                        .data as List<CollectionWithThumbnail>;
                                    return ListView.separated(
                                      itemBuilder: (context, index) {
                                        final item =
                                            collectionsWithThumbnail[index];
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () =>
                                              _albumListItemOnTap(item),
                                          child: AlbumListItemWidget(
                                            item: item,
                                          ),
                                        );
                                        // return _buildCollectionItem(
                                        //   collectionsWithThumbnail[index],
                                        // );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: 8,
                                      ),
                                      itemCount:
                                          collectionsWithThumbnail.length,
                                      shrinkWrap: true,
                                      physics: const BouncingScrollPhysics(),
                                    );
                                  } else {
                                    return const EnteLoadingWidget();
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: ButtonWidget(
                          buttonType: ButtonType.secondary,
                          buttonAction: ButtonAction.cancel,
                          isInAlert: true,
                          labelText: "Cancel",
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _albumListItemOnTap(CollectionWithThumbnail item) async {
    if (await _runCollectionAction(
      item.collection.id,
    )) {
      showShortToast(
        context,
        widget.actionType == CollectionActionType.addFiles
            ? "Added successfully to " + item.collection.name!
            : "Moved successfully to " + item.collection.name!,
      );
      _navigateToCollection(
        context,
        item.collection,
      );
    }
  }

  Widget _buildCollectionItem(CollectionWithThumbnail item) {
    return Container(
      padding: const EdgeInsets.only(left: 24, bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: SizedBox(
                height: 64,
                width: 64,
                key: Key("collection_item:" + (item.thumbnail?.tag ?? "")),
                child: item.thumbnail != null
                    ? ThumbnailWidget(
                        item.thumbnail,
                        showFavForAlbumOnly: true,
                      )
                    : const NoThumbnailWidget(),
              ),
            ),
            const Padding(padding: EdgeInsets.all(8)),
            Expanded(
              child: Text(
                item.collection.name!,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (await _runCollectionAction(item.collection.id)) {
            showShortToast(
              context,
              widget.actionType == CollectionActionType.addFiles
                  ? "Added successfully to " + item.collection.name!
                  : "Moved successfully to " + item.collection.name!,
            );
            _navigateToCollection(context, item.collection);
          }
        },
      ),
    );
  }

  Future<List<CollectionWithThumbnail>> _getCollectionsWithThumbnail() async {
    final List<CollectionWithThumbnail> collectionsWithThumbnail =
        await CollectionsService.instance.getCollectionsWithThumbnails(
      // in collections where user is a collaborator, only addTo and remove
      // action can to be performed
      includeCollabCollections:
          widget.actionType == CollectionActionType.addFiles,
    );
    collectionsWithThumbnail.removeWhere(
      (element) => (element.collection.type == CollectionType.favorites ||
          element.collection.type == CollectionType.uncategorized ||
          element.collection.isSharedFilesCollection()),
    );
    collectionsWithThumbnail.sort((first, second) {
      return compareAsciiLowerCaseNatural(
        first.collection.name ?? "",
        second.collection.name ?? "",
      );
    });
    return collectionsWithThumbnail;
  }

  void _navigateToCollection(BuildContext context, Collection collection) {
    Navigator.pop(context);
    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(collection, null),
      ),
    );
  }

  Future<bool> _runCollectionAction(int collectionID) async {
    switch (widget.actionType) {
      case CollectionActionType.addFiles:
        return _addToCollection(collectionID);
      case CollectionActionType.moveFiles:
        return _moveFilesToCollection(collectionID);
      case CollectionActionType.unHide:
        return _moveFilesToCollection(collectionID);
      case CollectionActionType.restoreFiles:
        return _restoreFilesToCollection(collectionID);
    }
  }

  Future<bool> _addToCollection(int collectionID) async {
    final dialog = createProgressDialog(context, "Uploading files to album...");
    await dialog.show();
    try {
      final List<File> files = [];
      final List<File> filesPendingUpload = [];
      if (widget.sharedFiles != null) {
        filesPendingUpload.addAll(
          await convertIncomingSharedMediaToFile(
            widget.sharedFiles!,
            collectionID,
          ),
        );
      } else {
        for (final file in widget.selectedFiles!.files) {
          final File? currentFile =
              await (FilesDB.instance.getFile(file.generatedID!));
          if (currentFile == null) {
            _logger.severe("Failed to find fileBy genID");
            continue;
          }
          if (currentFile.uploadedFileID == null) {
            currentFile.collectionID = collectionID;
            filesPendingUpload.add(currentFile);
          } else {
            files.add(currentFile);
          }
        }
      }
      if (filesPendingUpload.isNotEmpty) {
        // filesPendingUpload might be getting ignored during auto-upload
        // because the user deleted these files from ente in the past.
        await IgnoredFilesService.instance
            .removeIgnoredMappings(filesPendingUpload);
        await FilesDB.instance.insertMultiple(filesPendingUpload);
      }
      if (files.isNotEmpty) {
        await CollectionsService.instance.addToCollection(collectionID, files);
      }
      RemoteSyncService.instance.sync(silently: true);
      await dialog.hide();
      widget.selectedFiles?.clearAll();
      return true;
    } catch (e, s) {
      _logger.severe("Could not add to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
    }
    return false;
  }

  Future<bool> _moveFilesToCollection(int toCollectionID) async {
    final String message = widget.actionType == CollectionActionType.moveFiles
        ? "Moving files to album..."
        : "Unhiding files to album";
    final dialog = createProgressDialog(context, message);
    await dialog.show();
    try {
      final int fromCollectionID =
          widget.selectedFiles!.files.first.collectionID!;
      await CollectionsService.instance.move(
        toCollectionID,
        fromCollectionID,
        widget.selectedFiles!.files.toList(),
      );
      await dialog.hide();
      RemoteSyncService.instance.sync(silently: true);
      widget.selectedFiles?.clearAll();

      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
    }
  }

  Future<bool> _restoreFilesToCollection(int toCollectionID) async {
    final dialog = createProgressDialog(context, "Restoring files...");
    await dialog.show();
    try {
      await CollectionsService.instance
          .restore(toCollectionID, widget.selectedFiles!.files.toList());
      RemoteSyncService.instance.sync(silently: true);
      widget.selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message as String?);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
    }
  }
}
