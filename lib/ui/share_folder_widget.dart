import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/ui/loading_widget.dart';

class ShareFolderWidget extends StatefulWidget {
  final String title;
  final String path;

  const ShareFolderWidget(
    this.title,
    this.path, {
    Key key,
  }) : super(key: key);

  @override
  _ShareFolderWidgetState createState() => _ShareFolderWidgetState();
}

class _ShareFolderWidgetState extends State<ShareFolderWidget> {
  Folder _folder;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, bool>>(
      future:
          FolderSharingService.instance.getFolder(widget.path).then((folder) {
        _folder = folder;
        return FolderSharingService.instance.getSharingStatus(folder);
      }),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return _getSharingDialog(snapshot.data);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return loadWidget;
        }
      },
    );
  }

  Widget _getSharingDialog(Map<String, bool> sharingStatus) {
    return AlertDialog(
      title: Text('Share "' + widget.title + '" with'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            SharingCheckboxWidget(sharingStatus),
          ],
        ),
      ),
      actions: <Widget>[
        FlatButton(
          child: Text("Share"),
          onPressed: () async {
            var sharedWith = Set<String>();
            for (var user in sharingStatus.keys) {
              if (sharingStatus[user]) {
                sharedWith.add(user);
              }
            }
            _folder.sharedWith.clear();
            _folder.sharedWith.addAll(sharedWith);
            await FolderSharingService.instance.updateFolder(_folder);
            Fluttertoast.showToast(
                msg: "Sharing configuration updated successfully.",
                toastLength: Toast.LENGTH_SHORT,
                gravity: ToastGravity.BOTTOM,
                timeInSecForIosWeb: 1,
                backgroundColor: Colors.grey[600],
                textColor: Colors.white,
                fontSize: 16.0);
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}

class SharingCheckboxWidget extends StatefulWidget {
  final Map<String, bool> sharingStatus;

  const SharingCheckboxWidget(
    this.sharingStatus, {
    Key key,
  }) : super(key: key);

  @override
  _SharingCheckboxWidgetState createState() => _SharingCheckboxWidgetState();
}

class _SharingCheckboxWidgetState extends State<SharingCheckboxWidget> {
  Map<String, bool> _sharingStatus;

  @override
  void initState() {
    _sharingStatus = widget.sharingStatus;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final checkboxes = List<Widget>();
    for (final user in _sharingStatus.keys) {
      checkboxes.add(Row(
        children: <Widget>[
          Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.padded,
              value: _sharingStatus[user],
              onChanged: (value) {
                setState(() {
                  _sharingStatus[user] = value;
                });
              }),
          Text(user),
        ],
      ));
    }
    return Column(children: checkboxes);
  }
}
