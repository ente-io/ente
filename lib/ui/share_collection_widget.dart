import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:fluttercontactpicker/fluttercontactpicker.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/common_elements.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/subscription_page.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class SharingDialog extends StatefulWidget {
  final Collection collection;

  SharingDialog(this.collection, {Key key}) : super(key: key);

  @override
  _SharingDialogState createState() => _SharingDialogState();
}

class _SharingDialogState extends State<SharingDialog> {
  bool _showEntryField = false;
  List<User> _sharees;
  String _email;

  @override
  Widget build(BuildContext context) {
    _sharees = widget.collection.sharees;
    final children = List<Widget>();
    if (!_showEntryField && _sharees.length == 0) {
      _showEntryField = true;
    } else {
      for (final user in _sharees) {
        children.add(EmailItemWidget(widget.collection, user.email));
      }
    }
    if (_showEntryField) {
      children.add(_getEmailField());
    }
    children.add(Padding(
      padding: EdgeInsets.all(16),
    ));
    if (!_showEntryField) {
      children.add(SizedBox(
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
      children.add(
        SizedBox(
          width: 240,
          height: 50,
          child: button(
            "add",
            onPressed: () {
              _addEmailToCollection(_email.trim());
            },
          ),
        ),
      );
    }

    return AlertDialog(
      title: Text("sharing"),
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
    return Row(
      children: [
        Expanded(
          child: TypeAheadField(
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
                child: Text(
                  suggestion.email,
                  overflow: TextOverflow.clip,
                ),
              );
            },
            onSuggestionSelected: (PublicKey suggestion) {
              _addEmailToCollection(suggestion.email,
                  publicKey: suggestion.publicKey);
            },
          ),
        ),
        Padding(padding: EdgeInsets.all(8)),
        IconButton(
          icon: Icon(
            Icons.contact_mail_outlined,
            color: Theme.of(context).buttonColor.withOpacity(0.8),
          ),
          onPressed: () async {
            final emailContact = await FlutterContactPicker.pickEmailContact(
                askForPermission: true);
            _addEmailToCollection(emailContact.email.email);
          },
        ),
      ],
    );
  }

  Future<void> _addEmailToCollection(
    String email, {
    String publicKey,
  }) async {
    if (!isValidEmail(email)) {
      showErrorDialog(context, "invalid email address",
          "please enter a valid email address.");
      return;
    } else if (email == Configuration.instance.getEmail()) {
      showErrorDialog(context, "oops", "you cannot share with yourself");
      return;
    } else if (widget.collection.sharees.any((user) => user.email == email)) {
      showErrorDialog(
          context, "oops", "you're already sharing this with " + email);
      return;
    }
    if (publicKey == null) {
      final dialog = createProgressDialog(context, "searching for user...");
      await dialog.show();

      publicKey = await UserService.instance.getPublicKey(email);
      await dialog.hide();
    }
    if (publicKey == null) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      final dialog = AlertDialog(
        title: Text("invite to ente?"),
        content: Text(
          "looks like " +
              email +
              " hasn't signed up for ente yet. would you like to invite them?",
          style: TextStyle(
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "invite",
              style: TextStyle(
                color: Theme.of(context).buttonColor,
              ),
            ),
            onPressed: () {
              shareText(
                  "Hey, I have some photos to share. Please install https://ente.io so that I can share them privately.");
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
      final dialog = createProgressDialog(context, "sharing...");
      await dialog.show();
      final collection = widget.collection;
      if (collection.type == CollectionType.folder) {
        final path =
            CollectionsService.instance.decryptCollectionPath(collection);
        if (!Configuration.instance.getPathsToBackUp().contains(path)) {
          await Configuration.instance.addPathToFoldersToBeBackedUp(path);
        }
      }
      try {
        await CollectionsService.instance
            .share(widget.collection.id, email, publicKey);
        await dialog.hide();
        showToast("shared successfully!");
        setState(() {
          _sharees.add(User(email: email));
          _showEntryField = false;
        });
      } catch (e) {
        await dialog.hide();
        if (e is SharingNotPermittedForFreeAccountsError) {
          AlertDialog alert = AlertDialog(
            title: Text("sorry"),
            content: Text(
                "sharing is not permitted for free accounts, please subscribe"),
            actions: [
              FlatButton(
                child: Text("subscribe"),
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return SubscriptionPage();
                      },
                    ),
                  );
                },
              ),
              FlatButton(
                child: Text("ok"),
                onPressed: () {
                  Navigator.of(context, rootNavigator: true).pop();
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
        } else {
          showGenericErrorDialog(context);
        }
      }
    }
  }
}

class EmailItemWidget extends StatelessWidget {
  final Collection collection;
  final String email;

  const EmailItemWidget(
    this.collection,
    this.email, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          child: Text(
            email,
            style: TextStyle(fontSize: 16),
          ),
        ),
        Expanded(child: SizedBox()),
        IconButton(
          icon: Icon(Icons.delete_forever),
          color: Colors.redAccent,
          onPressed: () async {
            final dialog = createProgressDialog(context, "please wait...");
            await dialog.show();
            try {
              await CollectionsService.instance.unshare(collection.id, email);
              collection.sharees.removeWhere((user) => user.email == email);
              await dialog.hide();
              showToast("stopped sharing with " + email + ".");
              Navigator.of(context).pop();
            } catch (e, s) {
              Logger("EmailItemWidget").severe(e, s);
              await dialog.hide();
              showGenericErrorDialog(context);
            }
          },
        ),
      ],
    );
  }
}
