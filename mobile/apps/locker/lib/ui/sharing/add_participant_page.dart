import 'package:email_validator/email_validator.dart';
import 'package:ente_contacts/contacts.dart';
import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_ui/components/buttons/button_widget_v2.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_description_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/components/separators.dart";
import "package:ente_ui/components/text_input_widget_v2.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import 'package:flutter/material.dart';
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/utils/collection_actions.dart";

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
  late List<User> _suggestedUsers;

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  late CollectionActions collectionActions;

  @override
  void initState() {
    super.initState();
    _suggestedUsers = _getSuggestedUser();
    collectionActions = CollectionActions();
  }

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ContactsDisplayService.instance.changes,
      builder: (context, __, ___) {
        final filterSuggestedUsers = _suggestedUsers
            .where(
              (element) =>
                  element.matchesResolvedNameOrEmail(_textController.text),
            )
            .toList()
          ..sort(
            (a, b) => a.resolvedDisplayName.toLowerCase().compareTo(
                  b.resolvedDisplayName.toLowerCase(),
                ),
          );
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
                  context.l10n.addANewEmail,
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
                              title: context.l10n.orPickAnExistingOne,
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
                                            content: context.l10n
                                                .longPressAnEmailToVerifyEndToEndEncryption,
                                          )
                                        : const SizedBox.shrink(),
                                    widget.actionTypesToShow.contains(
                                      ActionTypesToShow.addCollaborator,
                                    )
                                        ? MenuSectionDescriptionWidget(
                                            content: context.l10n
                                                .collaboratorsCanAddFilesToTheSharedCollection,
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
                                    '${currentUser.id ?? currentUser.email}:${currentUser.resolvedDisplayName}',
                                  ),
                                  captionedTextWidget: CaptionedTextWidget(
                                    title: currentUser.resolvedDisplayName,
                                  ),
                                  leadingIconSize: 24.0,
                                  leadingIconWidget: UserAvatarWidget(
                                    currentUser,
                                    type: AvatarType.mini,
                                    config: Configuration.instance,
                                  ),
                                  menuItemColor:
                                      getEnteColorScheme(context).fillFaint,
                                  pressedColor:
                                      getEnteColorScheme(context).fillFaint,
                                  trailingIcon: (_selectedEmails
                                          .contains(currentUser.email))
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
                                  },
                                  onLongPress: () {
                                    showVerifyIdentitySheet(
                                      context,
                                      self: false,
                                      email: currentUser.email,
                                      config: Configuration.instance,
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
                                        bgColor: getEnteColorScheme(context)
                                            .fillFaint,
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
      },
    );
  }

  List<Widget> _actionButtons() {
    final widgets = <Widget>[];
    if (widget.actionTypesToShow.contains(ActionTypesToShow.addViewer)) {
      widgets.add(
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.primary,
          buttonSize: ButtonSizeV2.large,
          labelText: context.l10n.addViewers(_selectedEmails.length),
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
              context.l10n.viewersSuccessfullyAdded(noOfSuccessfullAdds),
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
        ButtonWidgetV2(
          buttonType:
              widget.actionTypesToShow.contains(ActionTypesToShow.addViewer)
                  ? ButtonTypeV2.neutral
                  : ButtonTypeV2.primary,
          buttonSize: ButtonSizeV2.large,
          labelText: context.l10n.addCollaborators(_selectedEmails.length),
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
              context.l10n.collaboratorsSuccessfullyAdded(noOfSuccessfullAdds),
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
          child: TextInputWidgetV2(
            textEditingController: _textController,
            focusNode: textFieldFocusNode,
            hintText: context.l10n.enterEmail,
            leadingWidget: const Icon(Icons.email_outlined),
            isClearable: true,
            shouldUnfocusOnClearOrSubmit: true,
            keyboardType: TextInputType.emailAddress,
            autoCorrect: false,
            onChange: (value) {
              _newEmail = value.trim();
              _emailIsValid = EmailValidator.validate(_newEmail);
              setState(() {});
            },
          ),
        ),
        const SizedBox(width: 8),
        ButtonWidgetV2(
          buttonType: ButtonTypeV2.secondary,
          buttonSize: ButtonSizeV2.small,
          labelText: context.l10n.add,
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

    final List<User> suggestedUsers =
        CollectionService.instance.getRelevantContacts();

    suggestedUsers.sort(
      (a, b) => a.resolvedDisplayName.toLowerCase().compareTo(
            b.resolvedDisplayName.toLowerCase(),
          ),
    );

    return suggestedUsers;
  }

  String _getTitle() {
    if (widget.actionTypesToShow.length > 1) {
      return context.l10n.addParticipants;
    } else if (widget.actionTypesToShow.first == ActionTypesToShow.addViewer) {
      return context.l10n.addViewer;
    } else {
      return context.l10n.addCollaborator;
    }
  }
}
