import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/folder_service.dart';
import 'package:photos/models/folder.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

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
    return FutureBuilder<Map<int, bool>>(
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

  Widget _getSharingDialog(Map<int, bool> sharingStatus) {
    return AlertDialog(
      title: Text('Sharing'),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            // SharingCheckboxWidget(sharingStatus),
            SharingWidget(["vishnu@ente.io", "shanthy@ente.io"]),
          ],
        ),
      ),
      // actions: <Widget>[
      //   FlatButton(
      //     child: Text("Save"),
      //     onPressed: () async {
      //       var sharedWith = Set<int>();
      //       for (var user in sharingStatus.keys) {
      //         if (sharingStatus[user]) {
      //           sharedWith.add(user);
      //         }
      //       }
      //       _folder.sharedWith.clear();
      //       _folder.sharedWith.addAll(sharedWith);
      //       await FolderSharingService.instance.updateFolder(_folder);
      //       showToast("Sharing configuration updated successfully.");
      //       Navigator.of(context).pop();
      //     },
      //   ),
      // ],
    );
  }
}

class SharingWidget extends StatefulWidget {
  final List<String> emails;
  SharingWidget(this.emails, {Key key}) : super(key: key);

  @override
  _SharingWidgetState createState() => _SharingWidgetState();
}

class _SharingWidgetState extends State<SharingWidget> {
  bool _showEntryField = false;
  List<String> _emails;

  @override
  void initState() {
    _emails = widget.emails;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>();
    for (final email in _emails) {
      children.add(EmailItemWidget(email));
    }
    if (_showEntryField) {
      children.add(TextField(
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        onSubmitted: (s) {
          final progressDialog = createProgressDialog(context, "Sharing...");
          progressDialog.show();
          Future.delayed(Duration(milliseconds: 1000), () {
            progressDialog.hide();
            showToast("Shared with " + s + ".");
            setState(() {
              _emails.add(s);
              _showEntryField = false;
            });
          });
        },
      ));
    }
    children.add(Padding(
      padding: EdgeInsets.all(8),
    ));
    children.add(Container(
      width: 220,
      child: OutlineButton(
        child: Icon(
          Icons.add,
        ),
        onPressed: () {
          setState(() {
            _showEntryField = true;
          });
        },
      ),
    ));
    var column = Column(
      children: children,
    );
    return column;
  }
}

class EmailItemWidget extends StatelessWidget {
  final String email;
  const EmailItemWidget(
    this.email, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            email,
            style: TextStyle(fontSize: 14),
          ),
          Icon(
            Icons.remove_circle_outline,
            color: Colors.redAccent,
          ),
        ],
      ),
    );
  }
}

class SharingCheckboxWidget extends StatefulWidget {
  final Map<int, bool> sharingStatus;

  const SharingCheckboxWidget(
    this.sharingStatus, {
    Key key,
  }) : super(key: key);

  @override
  _SharingCheckboxWidgetState createState() => _SharingCheckboxWidgetState();
}

class _SharingCheckboxWidgetState extends State<SharingCheckboxWidget> {
  Map<int, bool> _sharingStatus;

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
          Text(user.toString()),
        ],
      ));
    }
    return Column(children: checkboxes);
  }
}
