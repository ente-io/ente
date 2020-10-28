import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/file_uploader.dart';
import 'package:photos/utils/toast_util.dart';

class CreateCollectionPage extends StatefulWidget {
  final List<File> files;
  const CreateCollectionPage(this.files, {Key key}) : super(key: key);

  @override
  _CreateCollectionPageState createState() => _CreateCollectionPageState();
}

class _CreateCollectionPageState extends State<CreateCollectionPage> {
  final _logger = Logger("CreateCollectionPage");
  String _albumName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create album"),
      ),
      body: _getBody(context),
    );
  }

  Widget _getBody(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: OutlineButton(
              child: Text(
                "Create a new album",
                style: Theme.of(context).textTheme.bodyText1,
              ),
              onPressed: () {
                _showNameAlbumDialog();
              },
            ),
          ),
        ),
      ],
    );
  }

  void _showNameAlbumDialog() async {
    AlertDialog alert = AlertDialog(
      title: Text("Album title"),
      content: TextFormField(
        decoration: InputDecoration(
          hintText: "Christmas 21 / Dinner at Bob's",
          contentPadding: EdgeInsets.all(8),
        ),
        onChanged: (value) {
          setState(() {
            _albumName = value;
          });
        },
        autofocus: true,
        keyboardType: TextInputType.text,
      ),
      actions: [
        FlatButton(
          child: Text("OK"),
          onPressed: () async {
            final collection = await _createAlbum(_albumName);
            if (collection != null) {
              await _addToCollection(collection.id);
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

  Future<void> _addToCollection(int collectionID) async {
    final dialog = createProgressDialog(context, "Uploading files to album...");
    await dialog.show();
    final files = List<File>();
    for (final file in widget.files) {
      if (file.uploadedFileID == null) {
        file.collectionID = collectionID;
        final uploadedFile =
            (await FileUploader.instance.encryptAndUploadFile(file));
        await FilesDB.instance.update(uploadedFile);
        files.add(uploadedFile);
      } else {
        files.add(file);
      }
    }
    try {
      await CollectionsService.instance.addToCollection(collectionID, files);
      Navigator.pop(context);
      Navigator.pop(context);
      showToast("Album '" + _albumName + "' created.");
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    } finally {
      await dialog.hide();
    }
  }

  Future<Collection> _createAlbum(String albumName) async {
    var collection;
    final dialog = createProgressDialog(context, "Creating album...");
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
