// @dart=2.9

import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/db/public_keys_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/public_key.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/payment/subscription.dart';
import 'package:photos/ui/sharing/manage_album_participant.dart';
import 'package:photos/ui/sharing/manage_links_widget.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/email_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class ShareCollectionPage extends StatefulWidget {
  final Collection collection;

  const ShareCollectionPage(this.collection, {Key key}) : super(key: key);

  @override
  State<ShareCollectionPage> createState() => _ShareCollectionPageState();
}

class _ShareCollectionPageState extends State<ShareCollectionPage> {
  bool _showEntryField = false;
  List<User> _sharees;
  String _email;
  final Logger _logger = Logger("SharingDialogState");
  final CollectionSharingActions sharingActions =
      CollectionSharingActions(CollectionsService.instance);

  @override
  Widget build(BuildContext context) {
    _sharees = widget.collection.sharees;
    final children = <Widget>[];
    children.add(
      MenuSectionTitle(
        title: _sharees.isEmpty
            ? "Share with specific people"
            : "Shared with ${_sharees.length} people",
        iconData: Icons.workspaces,
      ),
    );
    if (!_showEntryField && _sharees.isEmpty) {
      _showEntryField = true;
    } else {
      for (final user in _sharees) {
        children.add(
          EmailItemWidget(
            widget.collection,
            user.email,
            user,
          ),
        );
      }
    }
    if (_showEntryField) {
      children.add(_getEmailField());
    }
    children.add(
      const Padding(
        padding: EdgeInsets.all(8),
      ),
    );
    if (!_showEntryField) {
      children.add(
        SizedBox(
          width: 220,
          child: GradientButton(
            onTap: () async {
              setState(() {
                _showEntryField = true;
              });
            },
            iconData: Icons.add,
          ),
        ),
      );
    } else {
      children.add(
        SizedBox(
          width: 240,
          height: 50,
          child: OutlinedButton(
            child: const Text("Add"),
            onPressed: () {
              _addEmailToCollection(_email?.trim() ?? '');
            },
          ),
        ),
      );
    }

    final bool hasUrl = widget.collection.publicURLs?.isNotEmpty ?? false;
    children.addAll([
      const SizedBox(
        height: 24,
      ),
      MenuSectionTitle(
        title: hasUrl ? "Public link enabled" : "Share a public link",
        iconData: Icons.public,
      ),
    ]);
    if (hasUrl) {
      final String collectionKey = Base58Encode(
        CollectionsService.instance.getCollectionKey(widget.collection.id),
      );
      final String url =
          "${widget.collection.publicURLs.first.url}#$collectionKey";
      children.addAll(
        [
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Copy link",
              makeTextBold: true,
            ),
            leadingIcon: Icons.copy,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            pressedColor: getEnteColorScheme(context).fillFaint,
            onTap: () async {
              await Clipboard.setData(ClipboardData(text: url));
              showToast(context, "Link copied to clipboard");
            },
            isBottomBorderRadiusRemoved: true,
          ),
          DividerWidget(
            dividerType: DividerType.menu,
            bgColor: getEnteColorScheme(context).blurStrokeFaint,
          ),
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Send link",
              makeTextBold: true,
            ),
            leadingIcon: Icons.adaptive.share,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            pressedColor: getEnteColorScheme(context).fillFaint,
            onTap: () async {
              shareText(url);
            },
            isTopBorderRadiusRemoved: true,
          ),
          DividerWidget(
            dividerType: DividerType.menu,
            bgColor: getEnteColorScheme(context).blurStrokeFaint,
          ),
          MenuItemWidget(
            captionedTextWidget: const CaptionedTextWidget(
              title: "Manage link",
              makeTextBold: true,
            ),
            leadingIcon: Icons.link,
            trailingIcon: Icons.navigate_next,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            pressedColor: getEnteColorScheme(context).fillFaint,
            trailingIconIsMuted: true,
            onTap: () async {
              routeToPage(
                context,
                ManageSharedLinkWidget(collection: widget.collection),
              ).then(
                (value) => {
                  if (mounted) {setState(() => {})}
                },
              );
            },
            isTopBorderRadiusRemoved: true,
          ),
        ],
      );
    } else {
      children.add(
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Create public link",
          ),
          leadingIcon: Icons.link,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          pressedColor: getEnteColorScheme(context).fillFaint,
          onTap: () async {
            final bool result = await sharingActions.publicLinkToggle(
              context,
              widget.collection,
              true,
            );
            if (result && mounted) {
              setState(() => {});
            }
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Sharing")),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
              child: Column(
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getEmailField() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
      child: Row(
        children: [
          Expanded(
            child: TypeAheadField(
              textFieldConfiguration: const TextFieldConfiguration(
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: "email@your-friend.com",
                ),
              ),
              hideOnEmpty: true,
              loadingBuilder: (context) {
                return const EnteLoadingWidget();
              },
              suggestionsCallback: (pattern) async {
                _email = pattern;
                return PublicKeysDB.instance.searchByEmail(_email);
              },
              itemBuilder: (context, suggestion) {
                return Container(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Text(
                    suggestion.email,
                    overflow: TextOverflow.clip,
                  ),
                );
              },
              onSuggestionSelected: (PublicKey suggestion) {
                _addEmailToCollection(
                  suggestion.email,
                  publicKey: suggestion.publicKey,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addEmailToCollection(
    String email, {
    String publicKey,
  }) async {
    if (!isValidEmail(email)) {
      showErrorDialog(
        context,
        "Invalid email address",
        "Please enter a valid email address.",
      );
      return;
    } else if (email == Configuration.instance.getEmail()) {
      showErrorDialog(context, "Oops", "You cannot share with yourself");
      return;
    } else if (widget.collection.sharees.any((user) => user.email == email)) {
      showErrorDialog(
        context,
        "Oops",
        "You're already sharing this with " + email,
      );
      return;
    }
    if (publicKey == null) {
      final dialog = createProgressDialog(context, "Searching for user...");
      await dialog.show();

      publicKey = await UserService.instance.getPublicKey(email);
      await dialog.hide();
    }
    if (publicKey == null) {
      Navigator.of(context, rootNavigator: true).pop('dialog');
      final dialog = AlertDialog(
        title: const Text("Invite to ente?"),
        content: Text(
          "Looks like " +
              email +
              " hasn't signed up for ente yet. would you like to invite them?",
          style: const TextStyle(
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            child: Text(
              "Invite",
              style: TextStyle(
                color: Theme.of(context).colorScheme.greenAlternative,
              ),
            ),
            onPressed: () {
              shareText(
                "Hey, I have some photos to share. Please install https://ente.io so that I can share them privately.",
              );
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
      try {
        await CollectionsService.instance
            .share(widget.collection.id, email, publicKey);
        await dialog.hide();
        showShortToast(context, "Shared successfully!");
        setState(() {
          _sharees.add(User(email: email));
          _showEntryField = false;
        });
      } catch (e) {
        await dialog.hide();
        if (e is SharingNotPermittedForFreeAccountsError) {
          _showUnSupportedAlert();
        } else {
          _logger.severe("failed to share collection", e);
          showGenericErrorDialog(context);
        }
      }
    }
  }

  void _showUnSupportedAlert() {
    final AlertDialog alert = AlertDialog(
      title: const Text("Sorry"),
      content: const Text(
        "Sharing is not permitted for free accounts, please subscribe",
      ),
      actions: [
        TextButton(
          child: Text(
            "Subscribe",
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (BuildContext context) {
                  return getSubscriptionPage();
                },
              ),
            );
          },
        ),
        TextButton(
          child: Text(
            "Ok",
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
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
  }
}

class EmailItemWidget extends StatelessWidget {
  final Collection collection;
  final String email;
  final User user;

  const EmailItemWidget(
    this.collection,
    this.email,
    this.user, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
          child: GestureDetector(
            onTap: () async {
              await routeToPage(
                context,
                ManageIndividualParticipant(collection: collection, user: user),
              );
            },
            child: Text(
              email,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        const Expanded(child: SizedBox()),
        IconButton(
          icon: const Icon(Icons.delete_forever),
          color: Colors.redAccent,
          onPressed: () async {
            final dialog = createProgressDialog(context, "Please wait...");
            await dialog.show();
            try {
              await CollectionsService.instance.unshare(collection.id, email);
              collection.sharees.removeWhere((user) => user.email == email);
              await dialog.hide();
              showToast(context, "Stopped sharing with " + email + ".");
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
