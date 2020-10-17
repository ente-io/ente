import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
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
  final Collection collection;

  const ShareFolderWidget(
    this.title,
    this.path, {
    this.collection,
    Key key,
  }) : super(key: key);

  @override
  _ShareFolderWidgetState createState() => _ShareFolderWidgetState();
}

class _ShareFolderWidgetState extends State<ShareFolderWidget> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: widget.collection == null
          ? Future.value(List<String>())
          : CollectionsService.instance.getSharees(widget.collection.id),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SharingDialog(widget.collection, snapshot.data, widget.path);
        } else if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        } else {
          return loadWidget;
        }
      },
    );
  }
}

class SharingDialog extends StatefulWidget {
  final Collection collection;
  final List<String> sharees;
  final String path;

  SharingDialog(this.collection, this.sharees, this.path, {Key key})
      : super(key: key);

  @override
  _SharingDialogState createState() => _SharingDialogState();
}

class _SharingDialogState extends State<SharingDialog> {
  bool _showEntryField = false;
  List<String> _sharees;
  String _email;

  @override
  Widget build(BuildContext context) {
    _sharees = widget.sharees;
    final children = List<Widget>();
    if (!_showEntryField &&
        (widget.collection == null || _sharees.length == 0)) {
      children.add(Text("Click the + button to share this folder."));
    } else {
      for (final email in _sharees) {
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
          onPressed: () {
            _addEmailToCollection(context);
          },
        ),
      ));
    }

    return AlertDialog(
      title: Text("Sharing"),
      content: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  children: children,
                )),
          ],
        ),
      ),
    );
  }

  Future<void> _addEmailToCollection(BuildContext context) async {
    if (!isValidEmail(_email)) {
      showErrorDialog(context, "Invalid email address",
          "Please enter a valid email address.");
      return;
    } else if (_email == Configuration.instance.getEmail()) {
      showErrorDialog(
          context, "Oops", "You cannot share the album with yourself.");
      return;
    }
    final dialog = createProgressDialog(context, "Searching for user...");
    await dialog.show();
    final publicKey = await UserService.instance.getPublicKey(_email);
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
      final dialog = createProgressDialog(context, "Sharing...");
      await dialog.show();
      var collectionID;
      if (widget.collection != null) {
        collectionID = widget.collection.id;
      } else {
        collectionID =
            (await CollectionsService.instance.getOrCreateForPath(widget.path))
                .id;
        await Configuration.instance.addPathToFoldersToBeBackedUp(widget.path);
        SyncService.instance.sync();
      }
      return CollectionsService.instance
          .share(collectionID, _email, publicKey)
          .then((value) async {
        await dialog.hide();
        setState(() {
          _sharees.add(_email);
          _showEntryField = false;
        });
      });
    }
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
