import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/share_util.dart';
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
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Collection>(
      future: CollectionsService.instance.getFolder(widget.path),
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

  Widget _getSharingDialog(Collection collection) {
    return AlertDialog(
      title: Text("Sharing"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            SharingWidget(collection),
          ],
        ),
      ),
    );
  }
}

class SharingWidget extends StatefulWidget {
  final Collection collection;
  SharingWidget(this.collection, {Key key}) : super(key: key);

  @override
  _SharingWidgetState createState() => _SharingWidgetState();
}

class _SharingWidgetState extends State<SharingWidget> {
  bool _showEntryField = false;
  String _email;
  List<String> _emails;

  @override
  void initState() {
    _emails = widget.collection.sharees;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final children = List<Widget>();
    if (!_showEntryField && _emails.length == 0) {
      children.add(Text("Click the + button to share this folder."));
    } else {
      for (final email in _emails) {
        children.add(EmailItemWidget(email));
      }
    }
    if (_showEntryField) {
      children.add(TextField(
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "email@your-friend.com",
        ),
        autofocus: true,
        onChanged: (s) {
          setState(() {
            _email = s;
          });
        },
        onSubmitted: (s) {
          _addEmailToCollection(context);
        },
      ));
    }
    children.add(Padding(
      padding: EdgeInsets.all(8),
    ));
    if (!_showEntryField) {
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
    } else {
      children.add(Container(
        width: 220,
        child: button(
          "Add",
          onPressed: () async {
            await _addEmailToCollection(context);
          },
        ),
      ));
    }
    return Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: children,
        ));
  }

  Future<void> _addEmailToCollection(BuildContext context) async {
    if (!isValidEmail(_email)) {
      showErrorDialog(context, "Invalid email address",
          "Please enter a valid email address");
      return;
    }
    final dialog = createProgressDialog(context, "Searching for user...");
    await dialog.show();
    final publicKey = await UserService.instance.getPublicKey(email: _email);
    await dialog.hide();
    if (publicKey == null) {
      Navigator.of(context).pop();
      final dialog = AlertDialog(
        title: Text("Invite to ente?"),
        content: Text("Looks like " +
            _email +
            " hasn't signed up for ente yet. Would you like to invite them?"),
        actions: [
          FlatButton(
            child: Text("Invite"),
            onPressed: () {
              shareText(
                  "Hey, I've got some really nice photos to share. Please install ente.io so that I can share them privately.");
            },
          ),
        ],
      );
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return dialog;
        },
      );
    } else {
      _shareCollection(_email, publicKey);
    }
  }

  void _shareCollection(String email, String publicKey) {
    if (widget.collection.id == null) {
      // TODO: Create collection
      // TODO: Add files to collection
    }
    // TODO: Add email to collection
    setState(() {
      _emails.add(email);
      _showEntryField = false;
    });
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
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                email,
                style: TextStyle(fontSize: 16),
              ),
            ),
            Icon(
              Icons.delete_forever,
              color: Colors.redAccent,
            ),
          ],
        ));
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
