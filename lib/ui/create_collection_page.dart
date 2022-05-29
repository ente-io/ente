import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/remote_sync_service.dart';
import 'package:photos/ui/collection_page.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/thumbnail_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum CollectionActionType { addFiles, moveFiles, restoreFiles }

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
  }
  return text + titleSuffix;
}

class CreateCollectionPage extends StatefulWidget {
  final SelectedFiles selectedFiles;
  final List<SharedMediaFile> sharedFiles;
  final CollectionActionType actionType;

  const CreateCollectionPage(this.selectedFiles, this.sharedFiles,
      {Key key, this.actionType = CollectionActionType.addFiles})
      : super(key: key);

  @override
  _CreateCollectionPageState createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final _logger = Logger("CreateCollectionPage");
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
                      top: 30, bottom: 12, left: 40, right: 40),
                  child: OutlinedButton.icon(
                    style: ButtonStyle(
                      padding: MaterialStateProperty.all<EdgeInsets>(
                        EdgeInsets.all(20),
                      ),
                    ),
                    icon: Icon(
                      Icons.create_new_folder_outlined,
                      color: Theme.of(context).buttonColor,
                    ),
                    label: Text(
                      "to a new album",
                      style: Theme.of(context).textTheme.bodyText1,
                    ),
                    onPressed: () {
                      _showNameAlbumDialog();
                    },
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 24, 40, 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "to an existing album",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColorLight.withOpacity(0.8),
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
            physics: NeverScrollableScrollPhysics(),
          );
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _buildCollectionItem(CollectionWithThumbnail item) {
    return Container(
      padding: EdgeInsets.only(left: 24, bottom: 16),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(2.0),
              child: SizedBox(
                child: ThumbnailWidget(item.thumbnail),
                height: 64,
                width: 64,
                key: Key("collection_item:" + item.thumbnail.tag()),
              ),
            ),
            Padding(padding: EdgeInsets.all(8)),
            Expanded(
              child: Text(
                item.collection.name,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        onTap: () async {
          if (await _runCollectionAction(item.collection.id)) {
            showToast(widget.actionType == CollectionActionType.addFiles
                ? "added successfully to " + item.collection.name
                : "moved successfully to " + item.collection.name);
            _navigateToCollection(item.collection);
          }
        },
      ),
    );
  }

  Future<List<CollectionWithThumbnail>> _getCollectionsWithThumbnail() async {
    final List<CollectionWithThumbnail> collectionsWithThumbnail = [];
    final latestCollectionFiles =
        await CollectionsService.instance.getLatestCollectionFiles();
    for (final file in latestCollectionFiles) {
      final c =
          CollectionsService.instance.getCollectionByID(file.collectionID);
      if (c.owner.id == Configuration.instance.getUserID()) {
        collectionsWithThumbnail.add(CollectionWithThumbnail(c, file));
      }
    }
    collectionsWithThumbnail.sort((first, second) {
      return second.collection.updationTime
          .compareTo(first.collection.updationTime);
    });
    return collectionsWithThumbnail;
  }

  void _showNameAlbumDialog() async {
    AlertDialog alert = AlertDialog(
      title: Text("album title"),
      content: TextFormField(
        decoration: InputDecoration(
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
            "ok",
            style: TextStyle(
              color: Theme.of(context).buttonColor,
            ),
          ),
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            final collection = await _createAlbum(_albumName);
            if (collection != null) {
              if (await _runCollectionAction(collection.id)) {
                if (widget.actionType == CollectionActionType.restoreFiles) {
                  showToast('restored files to album ' + _albumName);
                } else {
                  showToast("album '" + _albumName + "' created.");
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
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.bottomToTop,
            child: CollectionPage(
              CollectionWithThumbnail(collection, null),
            )));
  }

  Future<bool> _runCollectionAction(int collectionID) async {
    switch (widget.actionType) {
      case CollectionActionType.addFiles:
        return _addToCollection(collectionID);
      case CollectionActionType.moveFiles:
        return _moveFilesToCollection(collectionID);
      case CollectionActionType.restoreFiles:
        return _restoreFilesToCollection(collectionID);
    }
    throw AssertionError("unexpected actionType ${widget.actionType}");
  }

  Future<bool> _moveFilesToCollection(int toCollectionID) async {
    final dialog = createProgressDialog(context, "moving files to album...");
    await dialog.show();
    try {
      int fromCollectionID = widget.selectedFiles.files?.first?.collectionID;
      await CollectionsService.instance.move(toCollectionID, fromCollectionID,
          widget.selectedFiles.files?.toList());
      RemoteSyncService.instance.sync(silently: true);
      widget.selectedFiles?.clearAll();
      await dialog.hide();
      return true;
    } on AssertionError catch (e, s) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
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
    } on AssertionError catch (e, s) {
      await dialog.hide();
      showErrorDialog(context, "Oops", e.message);
      return false;
    } catch (e, s) {
      _logger.severe("Could not move to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
      return false;
    }
  }

  Future<bool> _addToCollection(int collectionID) async {
    final dialog = createProgressDialog(context, "uploading files to album...");
    await dialog.show();
    try {
      final List<File> files = [];
      final List<File> filesPendingUpload = [];
      if (widget.sharedFiles != null) {
        filesPendingUpload.addAll(await convertIncomingSharedMediaToFile(
            widget.sharedFiles, collectionID));
      } else {
        final List<File> filesPendingUpload = [];
        for (final file in widget.selectedFiles.files) {
          final currentFile = await FilesDB.instance.getFile(file.generatedID);
          if (currentFile.uploadedFileID == null) {
            currentFile.collectionID = collectionID;
            filesPendingUpload.add(currentFile);
          } else {
            files.add(currentFile);
          }
        }
        await FilesDB.instance.insertMultiple(filesPendingUpload);
        await CollectionsService.instance.addToCollection(collectionID, files);
      }
      RemoteSyncService.instance.sync(silently: true);
      await dialog.hide();
      widget.selectedFiles?.clearAll();
      return true;
    } catch (e, s) {
      _logger.severe("Could not add to album", e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
    return false;
  }

  Future<Collection> _createAlbum(String albumName) async {
    Collection collection;
    final dialog = createProgressDialog(context, "creating album...");
    await dialog.show();
    try {
      collection = await CollectionsService.instance.createAlbum(albumName);
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    } finally {
      await dialog.hide();
    }
    return collection;
  }
}
