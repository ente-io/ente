import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import "package:photos/services/account/user_service.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/notification/toast.dart";
import 'package:photos/ui/sharing/user_avator_widget.dart';
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import "package:photos/utils/separators_util.dart";

enum ActionTypesToShow {
  addViewer,
  addCollaborator,
}

class AddParticipantPage extends StatefulWidget {
  /// Cannot be empty
  final List<ActionTypesToShow> actionTypesToShow;
  final List<Collection> collections;

  AddParticipantPage(
    this.collections,
    this.actionTypesToShow, {
    super.key,
  }) : assert(
          actionTypesToShow.isNotEmpty,
          'actionTypesToShow cannot be empty',
        );

  @override
  State<StatefulWidget> createState() => _AddParticipantPage();
}

class _AddParticipantPage extends State<AddParticipantPage> {
  final _selectedEmails = <String>{};
  String _newEmail = '';
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late CollectionActions collectionActions;
  late List<User> _suggestedUsers;

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    collectionActions = CollectionActions(CollectionsService.instance);
    _suggestedUsers = _getSuggestedUser();
  }

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filterSuggestedUsers = _suggestedUsers
        .where(
          (element) =>
              (element.displayName ?? element.email).toLowerCase().contains(
                    _textController.text.trim().toLowerCase(),
                  ),
        )
        .toList();
    isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          _getTitle(),
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              AppLocalizations.of(context).addANewEmail,
              style: enteTextTheme.small
                  .copyWith(color: enteColorScheme.textMuted),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _enterEmailField(),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  filterSuggestedUsers.isNotEmpty
                      ? MenuSectionTitle(
                          title:
                              AppLocalizations.of(context).orPickAnExistingOne,
                        )
                      : const SizedBox.shrink(),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (index >= filterSuggestedUsers.length) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 8.0,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                filterSuggestedUsers.isNotEmpty
                                    ? MenuSectionDescriptionWidget(
                                        content: AppLocalizations.of(context)
                                            .longPressAnEmailToVerifyEndToEndEncryption,
                                      )
                                    : const SizedBox.shrink(),
                                widget.actionTypesToShow.contains(
                                  ActionTypesToShow.addCollaborator,
                                )
                                    ? MenuSectionDescriptionWidget(
                                        content: AppLocalizations.of(context)
                                            .collaboratorsCanAddPhotosAndVideosToTheSharedAlbum,
                                      )
                                    : const SizedBox.shrink(),
                              ],
                            ),
                          );
                        }
                        final currentUser = filterSuggestedUsers[index];
                        return Column(
                          children: [
                            MenuItemWidget(
                              key: ValueKey(
                                currentUser.displayName ?? currentUser.email,
                              ),
                              captionedTextWidget: CaptionedTextWidget(
                                title: currentUser.displayName ??
                                    currentUser.email,
                              ),
                              leadingIconSize: 24.0,
                              leadingIconWidget: UserAvatarWidget(
                                currentUser,
                                type: AvatarType.mini,
                              ),
                              menuItemColor:
                                  getEnteColorScheme(context).fillFaint,
                              pressedColor:
                                  getEnteColorScheme(context).fillFaint,
                              trailingIcon:
                                  (_selectedEmails.contains(currentUser.email))
                                      ? Icons.check
                                      : null,
                              onTap: () async {
                                textFieldFocusNode.unfocus();
                                if (_selectedEmails
                                    .contains(currentUser.email)) {
                                  _selectedEmails.remove(currentUser.email);
                                } else {
                                  _selectedEmails.add(currentUser.email);
                                }

                                setState(() => {});
                                // showShortToast(context, "yet to implement");
                              },
                              onLongPress: () {
                                showDialog(
                                  useRootNavigator: false,
                                  context: context,
                                  builder: (BuildContext context) {
                                    return VerifyIdentifyDialog(
                                      self: false,
                                      email: currentUser.email,
                                    );
                                  },
                                );
                              },
                              isTopBorderRadiusRemoved: index > 0,
                              isBottomBorderRadiusRemoved:
                                  index < (filterSuggestedUsers.length - 1),
                            ),
                            (index == (filterSuggestedUsers.length - 1))
                                ? const SizedBox.shrink()
                                : DividerWidget(
                                    dividerType: DividerType.menu,
                                    bgColor:
                                        getEnteColorScheme(context).fillFaint,
                                  ),
                          ],
                        );
                      },
                      itemCount: filterSuggestedUsers.length + 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  ..._actionButtons(),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _actionButtons() {
    final widgets = <Widget>[];
    if (widget.actionTypesToShow.contains(ActionTypesToShow.addViewer)) {
      widgets.add(
        ButtonWidget(
          buttonType: ButtonType.primary,
          buttonSize: ButtonSize.large,
          labelText: AppLocalizations.of(context)
              .addViewers(count: _selectedEmails.length),
          isDisabled: _selectedEmails.isEmpty,
          onTap: () async {
            final results = <bool>[];
            final collections = widget.collections;

            for (String email in _selectedEmails) {
              bool result = false;
              for (Collection collection in collections) {
                result = await collectionActions.addEmailToCollection(
                  context,
                  collection,
                  email,
                  CollectionParticipantRole.viewer,
                );
              }
              results.add(result);
            }

            final noOfSuccessfullAdds = results.where((e) => e).length;
            showToast(
              context,
              AppLocalizations.of(context)
                  .viewersSuccessfullyAdded(count: noOfSuccessfullAdds),
            );

            if (!results.any((e) => e == false) && mounted) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      );
    }
    if (widget.actionTypesToShow.contains(
      ActionTypesToShow.addCollaborator,
    )) {
      widgets.add(
        ButtonWidget(
          buttonType:
              widget.actionTypesToShow.contains(ActionTypesToShow.addViewer)
                  ? ButtonType.neutral
                  : ButtonType.primary,
          buttonSize: ButtonSize.large,
          labelText: AppLocalizations.of(context)
              .addCollaborators(count: _selectedEmails.length),
          isDisabled: _selectedEmails.isEmpty,
          onTap: () async {
            // TODO: This is not currently designed for best UX for action on
            // multiple collections and emails, especially if some operations
            // fail. Can be improved by using a different 'addEmailToCollection'
            // that accepts list of emails and list of collections.
            final results = <bool>[];
            final collections = widget.collections;

            for (String email in _selectedEmails) {
              bool result = false;
              for (Collection collection in collections) {
                result = await collectionActions.addEmailToCollection(
                  context,
                  collection,
                  email,
                  CollectionParticipantRole.collaborator,
                );
              }
              results.add(result);
            }

            final noOfSuccessfullAdds = results.where((e) => e).length;
            showToast(
              context,
              AppLocalizations.of(context)
                  .collaboratorsSuccessfullyAdded(count: noOfSuccessfullAdds),
            );

            if (!results.any((e) => e == false) && mounted) {
              Navigator.of(context).pop(true);
            }
          },
        ),
      );
    }
    final widgetsWithSpaceBetween = addSeparators(
      widgets,
      const SizedBox(
        height: 8,
      ),
    );
    return widgetsWithSpaceBetween;
  }

  void clearFocus() {
    _textController.clear();
    _newEmail = _textController.text;
    _emailIsValid = false;
    textFieldFocusNode.unfocus();
    setState(() => {});
  }

  Widget _enterEmailField() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _textController,
            focusNode: textFieldFocusNode,
            style: getEnteTextTheme(context).body,
            autofillHints: const [AutofillHints.email],
            decoration: InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(4.0)),
                borderSide:
                    BorderSide(color: getEnteColorScheme(context).strokeMuted),
              ),
              fillColor: getEnteColorScheme(context).fillFaint,
              filled: true,
              hintText: AppLocalizations.of(context).enterEmail,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: UnderlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(4),
              ),
              prefixIcon: Icon(
                Icons.email_outlined,
                color: getEnteColorScheme(context).strokeMuted,
              ),
              suffixIcon: _newEmail == ''
                  ? null
                  : IconButton(
                      onPressed: clearFocus,
                      icon: Icon(
                        Icons.cancel,
                        color: getEnteColorScheme(context).strokeMuted,
                      ),
                    ),
            ),
            onChanged: (value) {
              _newEmail = value.trim();
              _emailIsValid = EmailValidator.validate(_newEmail);
              setState(() {});
            },
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            //initialValue: _email,
            textInputAction: TextInputAction.next,
          ),
        ),
        const SizedBox(width: 8),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.small,
          labelText: AppLocalizations.of(context).add,
          isDisabled: !_emailIsValid,
          onTap: () async {
            if (_emailIsValid) {
              final result = await collectionActions.doesEmailHaveAccount(
                context,
                _newEmail,
              );
              if (result && mounted) {
                setState(() {
                  for (var suggestedUser in _suggestedUsers) {
                    if (suggestedUser.email == _newEmail) {
                      _selectedEmails.add(suggestedUser.email);
                      clearFocus();

                      return;
                    }
                  }
                  _suggestedUsers.insert(0, User(email: _newEmail));
                  _selectedEmails.add(_newEmail);
                  clearFocus();
                });
              }
            }
          },
        ),
      ],
    );
  }

  List<User> _getSuggestedUser() {
    final Set<String> existingEmails = {};
    final collections = widget.collections;
    if (collections.isEmpty) {
      return [];
    }

    for (final Collection collection in collections) {
      for (final User u in collection.sharees) {
        if (u.id != null && u.email.isNotEmpty) {
          existingEmails.add(u.email);
        }
      }
    }

    final List<User> suggestedUsers = UserService.instance.getRelevantContacts()
      ..removeWhere(
        (element) => existingEmails.contains(element.email),
      );

    if (_textController.text.trim().isNotEmpty) {
      suggestedUsers.removeWhere(
        (element) => !(element.displayName ?? element.email)
            .toLowerCase()
            .contains(_textController.text.trim().toLowerCase()),
      );
    }
    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));

    return suggestedUsers;
  }

  String _getTitle() {
    if (widget.actionTypesToShow.length > 1) {
      return AppLocalizations.of(context).addParticipants;
    } else if (widget.actionTypesToShow.first == ActionTypesToShow.addViewer) {
      return AppLocalizations.of(context).addViewer;
    } else {
      return AppLocalizations.of(context).addCollaborator;
    }
  }
}
