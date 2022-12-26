// @dart=2.9

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
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
      text = "Add file";
      break;
    case CollectionActionType.moveFiles:
      text = "Move file";
      break;
    case CollectionActionType.restoreFiles:
      text = "Restore file";
      break;
    case CollectionActionType.unHide:
      text = "Unhide file";
      break;
  }
  return text + titleSuffix;
}

class CreateCollectionPage extends StatefulWidget {
  final SelectedFiles selectedFiles;
  final List<SharedMediaFile> sharedFiles;
  final CollectionActionType actionType;

  const CreateCollectionPage(
    this.selectedFiles,
    this.sharedFiles, {
    Key key,
    this.actionType = CollectionActionType.addFiles,
  }) : super(key: key);

  @override
  State<CreateCollectionPage> createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final _logger = Logger((_CreateCollectionPageState).toString());
  String _albumName;

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.sharedFiles != null
        ? widget.sharedFiles.length
        : widget.selectedFiles.files.length;
    return Scaffold(
      appBar: AppBar(
        title: Text(_actionName(widget.actionType, filesCount > 1)),
      ),
      body: _getBody(context),
    );
  }

  Widget _getBody(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(
                    top: 30,
                    bottom: 12,
                    left: 40,
                    right: 40,
                  ),
                  child: GradientButton(
                    onTap: () async {
                      _showNameAlbumDialog();
                    },
                    iconData: Icons.create_new_folder_outlined,
                    text: "To a new album",
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(40, 24, 40, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "To an existing album",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: _getExistingCollectionsWidget(),
          ),
        ],
      ),
    );
  }

  Widget _getExistingCollectionsWidget() {
    return FutureBuilder<List<CollectionWithThumbnail>>(
      future: _getCollectionsWithThumbnail(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemBuilder: (context, index) {
              return _buildCollectionItem(snapshot.data[index]);
            },
            itemCount: snapshot.data.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
          );
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
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
                item.collection.name,
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
                  ? "Added successfully to " + item.collection.name
                  : "Moved successfully to " + item.collection.name,
            );
            _navigateToCollection(item.collection);
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

  void _showNameAlbumDialog() async {
    final AlertDialog alert = AlertDialog(
      title: const Text("Album title"),
      content: TextFormField(
        decoration: const InputDecoration(
          hintText: "Christmas 2020 / Dinner at Alice's",
          contentPadding: EdgeInsets.all(8),
        ),
        onChanged: (value) {
          setState(() {
            _albumName = value;
          });
        },
        autofocus: true,
        keyboardType: TextInputType.text,
        textCapitalization: TextCapitalization.words,
      ),
      actions: [
        TextButton(
          child: Text(
            "Ok",
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            final collection = await _createAlbum(_albumName);
            if (collection != null) {
              if (await _runCollectionAction(collection.id)) {
                if (widget.actionType == CollectionActionType.restoreFiles) {
                  showShortToast(
                    context,
                    'Restored files to album ' + _albumName,
                  );
                } else {
                  showShortToast(
                    context,
                    "Album '" + _albumName + "' created.",
                  );
                }
                _navigateToCollection(collection);
              }
            }
          },
        ),
      ],
    );

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
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
    throw AssertionError("unexpected actionType ${widget.actionType}");
  }

  Future<bool> _moveFilesToCollection(int toCollectionID) async {
    final String message = widget.actionType == CollectionActionType.moveFiles
        ? "Moving files to album..."
        : "Unhiding files to album";
    final dialog = createProgressDialog(context, message);
    await dialog.show();
    try {
      final int fromCollectionID =
          widget.selectedFiles.files.first?.collectionID;
      await CollectionsService.instance.move(
        toCollectionID,
        fromCollectionID,
        widget.selectedFiles.files?.toList(),
      );
      await dialog.hide();
      RemoteSyncService.instance.sync(silently: true);
      widget.selectedFiles?.clearAll();

      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message);
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
          .restore(toCollectionID, widget.selectedFiles.files?.toList());
      RemoteSyncService.instance.sync(silently: true);
      widget.selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return false;
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
            widget.sharedFiles,
            collectionID,
          ),
        );
      } else {
        for (final file in widget.selectedFiles.files) {
          final currentFile = await FilesDB.instance.getFile(file.generatedID);
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

  Future<Collection> _createAlbum(String albumName) async {
    Collection collection;
    final dialog = createProgressDialog(context, "Creating album...");
    await dialog.show();
    try {
      collection = await CollectionsService.instance.createAlbum(albumName);
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      showGenericErrorDialog(context: context);
    } finally {
      await dialog.hide();
    }
    return collection;
  }
}
