import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:photos/core/configuration.dart';
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
import 'package:photos/ui/components/new_album_list_widget.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum CollectionActionType { addFiles, moveFiles, restoreFiles, unHide }

String _actionName(CollectionActionType type, bool plural) {
  bool addTitleSuffix = false;
  final titleSuffix = (plural ? "s" : "");
  String text = "";
  switch (type) {
    case CollectionActionType.addFiles:
      text = "Add item";
      addTitleSuffix = true;
      break;
    case CollectionActionType.moveFiles:
      text = "Move item";
      addTitleSuffix = true;
      break;
    case CollectionActionType.restoreFiles:
      text = "Restore to album";
      break;
    case CollectionActionType.unHide:
      text = "Unhide to album";
      break;
  }
  return addTitleSuffix ? text + titleSuffix : text;
}

void createCollectionSheet(
  SelectedFiles? selectedFiles,
  List<SharedMediaFile>? sharedFiles,
  BuildContext context, {
  CollectionActionType actionType = CollectionActionType.addFiles,
  bool showOptionToCreateNewAlbum = true,
}) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return CreateCollectionSheet(
        selectedFiles: selectedFiles,
        sharedFiles: sharedFiles,
        actionType: actionType,
        showOptionToCreateNewAlbum: showOptionToCreateNewAlbum,
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
  final bool showOptionToCreateNewAlbum;
  const CreateCollectionSheet({
    required this.selectedFiles,
    required this.sharedFiles,
    required this.actionType,
    required this.showOptionToCreateNewAlbum,
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
            padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
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
                                        if (index == 0 &&
                                            widget.showOptionToCreateNewAlbum) {
                                          return GestureDetector(
                                            onTap: () async {
                                              final result =
                                                  await showTextInputDialog(
                                                context,
                                                title: "Album title",
                                                submitButtonLabel: "OK",
                                                hintText: "Enter album name",
                                                onSubmit: _nameAlbum,
                                                showOnlyLoadingState: true,
                                                textCapitalization:
                                                    TextCapitalization.words,
                                              );
                                              if (result is Exception) {
                                                showGenericErrorDialog(
                                                  context: context,
                                                );
                                                _logger.severe(
                                                  "Failed to name album",
                                                  result,
                                                );
                                              }
                                            },
                                            behavior: HitTestBehavior.opaque,
                                            child:
                                                const NewAlbumListItemWidget(),
                                          );
                                        }
                                        final item = collectionsWithThumbnail[
                                            index -
                                                (widget.showOptionToCreateNewAlbum
                                                    ? 1
                                                    : 0)];
                                        return GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () =>
                                              _albumListItemOnTap(item),
                                          child: AlbumListItemWidget(
                                            item,
                                          ),
                                        );
                                      },
                                      separatorBuilder: (context, index) =>
                                          const SizedBox(
                                        height: 8,
                                      ),
                                      itemCount:
                                          collectionsWithThumbnail.length +
                                              (widget.showOptionToCreateNewAlbum
                                                  ? 1
                                                  : 0),
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
                      SafeArea(
                        child: Container(
                          //inner stroke of 1pt + 15 pts of top padding = 16 pts
                          padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: getEnteColorScheme(context).strokeFaint,
                              ),
                            ),
                          ),
                          child: const ButtonWidget(
                            buttonType: ButtonType.secondary,
                            buttonAction: ButtonAction.cancel,
                            isInAlert: true,
                            labelText: "Cancel",
                          ),
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

  Future<void> _nameAlbum(String albumName) async {
    if (albumName.isNotEmpty) {
      final collection = await _createAlbum(albumName);
      if (collection != null) {
        if (await _runCollectionAction(
          collectionID: collection.id,
          showProgressDialog: false,
        )) {
          if (widget.actionType == CollectionActionType.restoreFiles) {
            showShortToast(
              context,
              'Restored files to album ' + albumName,
            );
          } else {
            showShortToast(
              context,
              "Album '" + albumName + "' created.",
            );
          }
          _navigateToCollection(collection);
        }
      }
    }
  }

  Future<Collection?> _createAlbum(String albumName) async {
    Collection? collection;
    try {
      collection = await CollectionsService.instance.createAlbum(albumName);
    } catch (e, s) {
      _logger.severe("Failed to create album", e, s);
      rethrow;
    }
    return collection;
  }

  Future<void> _albumListItemOnTap(CollectionWithThumbnail item) async {
    if (await _runCollectionAction(collectionID: item.collection.id)) {
      showShortToast(
        context,
        widget.actionType == CollectionActionType.addFiles
            ? "Added successfully to " + item.collection.name!
            : "Moved successfully to " + item.collection.name!,
      );
      _navigateToCollection(
        item.collection,
      );
    }
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

  void _navigateToCollection(Collection collection) {
    Navigator.pop(context);
    routeToPage(
      context,
      CollectionPage(
        CollectionWithThumbnail(collection, null),
      ),
    );
  }

  Future<bool> _runCollectionAction({
    required int collectionID,
    bool showProgressDialog = true,
  }) async {
    switch (widget.actionType) {
      case CollectionActionType.addFiles:
        return _addToCollection(
          collectionID: collectionID,
          showProgressDialog: showProgressDialog,
        );
      case CollectionActionType.moveFiles:
        return _moveFilesToCollection(collectionID);
      case CollectionActionType.unHide:
        return _moveFilesToCollection(collectionID);
      case CollectionActionType.restoreFiles:
        return _restoreFilesToCollection(collectionID);
    }
  }

  Future<bool> _addToCollection({
    required int collectionID,
    required bool showProgressDialog,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(
            context,
            "Uploading files to album"
            "...",
            isDismissible: true,
          )
        : null;
    await dialog?.show();
    try {
      final List<File> files = [];
      final List<File> filesPendingUpload = [];
      final int currentUserID = Configuration.instance.getUserID()!;
      if (widget.sharedFiles != null) {
        filesPendingUpload.addAll(
          await convertIncomingSharedMediaToFile(
            widget.sharedFiles!,
            collectionID,
          ),
        );
      } else {
        for (final file in widget.selectedFiles!.files) {
          File? currentFile;
          if (file.uploadedFileID != null) {
            currentFile = file;
          } else if (file.generatedID != null) {
            // when file is not uploaded, refresh the state from the db to
            // ensure we have latest upload status for given file before
            // queueing it up as pending upload
            currentFile = await (FilesDB.instance.getFile(file.generatedID!));
          } else if (file.generatedID == null) {
            _logger.severe("generated id should not be null");
          }
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
        // Newly created collection might not be cached
        final Collection? c =
            CollectionsService.instance.getCollectionByID(collectionID);
        if (c != null && c.owner!.id != currentUserID) {
          showToast(context, "Can not upload to albums owned by others");
          await dialog?.hide();
          return false;
        } else {
          // filesPendingUpload might be getting ignored during auto-upload
          // because the user deleted these files from ente in the past.
          await IgnoredFilesService.instance
              .removeIgnoredMappings(filesPendingUpload);
          await FilesDB.instance.insertMultiple(filesPendingUpload);
        }
      }
      if (files.isNotEmpty) {
        await CollectionsService.instance.addToCollection(collectionID, files);
      }
      RemoteSyncService.instance.sync(silently: true);
      await dialog?.hide();
      widget.selectedFiles?.clearAll();
      return true;
    } catch (e, s) {
      _logger.severe("Failed to add to album", e, s);
      await dialog?.hide();
      showGenericErrorDialog(context: context);
      rethrow;
    }
  }

  Future<bool> _moveFilesToCollection(int toCollectionID) async {
    final String message = widget.actionType == CollectionActionType.moveFiles
        ? "Moving files to album..."
        : "Unhiding files to album";
    final dialog = createProgressDialog(context, message, isDismissible: true);
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
    final dialog = createProgressDialog(
      context,
      "Restoring files...",
      isDismissible: true,
    );
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
