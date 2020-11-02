import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class SharingDialog extends StatefulWidget {
  final Collection collection;
  final List<User> sharees;

  SharingDialog(this.collection, this.sharees, {Key key}) : super(key: key);

  @override
  _SharingDialogState createState() => _SharingDialogState();
}

class _SharingDialogState extends State<SharingDialog> {
  bool _showEntryField = false;
  List<User> _sharees;
  String _email;

  @override
  Widget build(BuildContext context) {
    _sharees = widget.sharees;
    final children = List<Widget>();
    if (!_showEntryField &&
        (widget.collection == null || _sharees.length == 0)) {
      children.add(Text("Click the + button to share this " +
          Collection.typeToString(widget.collection.type) +
          "."));
    } else {
      for (final user in _sharees) {
        children.add(EmailItemWidget(widget.collection.id, user.email));
      }
    }
    if (_showEntryField) {
      children.add(_getEmailField());
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
            _addEmailToCollection(_email, null);
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

  Widget _getEmailField() {
    return TypeAheadField(
      textFieldConfiguration: TextFieldConfiguration(
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: "email@your-friend.com",
        ),
      ),
      hideOnEmpty: true,
      loadingBuilder: (context) {
        return loadWidget;
      },
      suggestionsCallback: (pattern) async {
        _email = pattern;
        return PublicKeysDB.instance.searchByEmail(_email);
      },
      itemBuilder: (context, suggestion) {
        return Container(
          padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Container(
            child: Text(
              suggestion.email,
              overflow: TextOverflow.clip,
            ),
          ),
        );
      },
      onSuggestionSelected: (PublicKey suggestion) {
        _addEmailToCollection(suggestion.email, suggestion.publicKey);
      },
    );
  }

  Future<void> _addEmailToCollection(String email, String publicKey) async {
    if (!isValidEmail(email)) {
      showErrorDialog(context, "Invalid email address",
          "Please enter a valid email address.");
      return;
    } else if (email == Configuration.instance.getEmail()) {
      showErrorDialog(context, "Oops", "You cannot share with yourself.");
      return;
    }
    if (publicKey == null) {
      final dialog = createProgressDialog(context, "Searching for user...");
      await dialog.show();

      publicKey = await UserService.instance.getPublicKey(email);
      await dialog.hide();
    }
    if (publicKey == null) {
      Navigator.of(context).pop();
      final dialog = AlertDialog(
        title: Text("Invite to ente?"),
        content: Text("Looks like " +
            email +
            " hasn't signed up for ente yet. Would you like to invite them?"),
        actions: [
          FlatButton(
            child: Text("Invite"),
            onPressed: () {
              shareText(
                  "Hey, I have some really nice photos to share. Please install ente.io so that I can share them privately.");
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
      final collection = widget.collection;
      if (collection.type == CollectionType.folder) {
        final path =
            CollectionsService.instance.decryptCollectionPath(collection);
        if (!Configuration.instance.getPathsToBackUp().contains(path)) {
          await Configuration.instance.addPathToFoldersToBeBackedUp(path);
          SyncService.instance.sync();
        }
      }
      try {
        await CollectionsService.instance
            .share(widget.collection.id, email, publicKey);
        await dialog.hide();
        showToast("Shared successfully!");
        setState(() {
          _sharees.add(User(email: email));
          _showEntryField = false;
        });
      } catch (e) {
        await dialog.hide();
        showGenericErrorDialog(context);
      }
    }
  }
}

class EmailItemWidget extends StatelessWidget {
  final int collectionID;
  final String email;

  const EmailItemWidget(
    this.collectionID,
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
            IconButton(
              icon: Icon(Icons.delete_forever),
              color: Colors.redAccent,
              onPressed: () async {
                final dialog = createProgressDialog(context, "Please wait...");
                await dialog.show();
                try {
                  await CollectionsService.instance
                      .unshare(collectionID, email);
                  await dialog.hide();
                  showToast("Stopped sharing with " + email + ".");
                  Navigator.of(context).pop();
                } catch (e, s) {
                  Logger("EmailItemWidget").severe(e, s);
                  await dialog.hide();
                  showGenericErrorDialog(context);
                }
              },
            ),
          ],
        ));
  }
}
