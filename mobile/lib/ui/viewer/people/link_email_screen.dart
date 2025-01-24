import "dart:async";

import "package:email_validator/email_validator.dart";
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import "package:photos/models/ml/face/person.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/user_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import "package:photos/ui/components/dialog_widget.dart";
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/text_input_widget.dart";
import 'package:photos/ui/sharing/user_avator_widget.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/person_contact_linking_util.dart";
import "package:photos/utils/share_util.dart";

class LinkEmailScreen extends StatefulWidget {
  final String? personID;
  final bool isFromSaveOrEditPerson;
  const LinkEmailScreen(
    this.personID, {
    this.isFromSaveOrEditPerson = false,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _LinkEmailScreen();
}

class _LinkEmailScreen extends State<LinkEmailScreen> {
  String? _selectedEmail;
  String _newEmail = '';
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late List<User> _suggestedUsers;
  late List<User> _filteredUsers;
  final _logger = Logger('LinkEmailScreen');

  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _suggestedUsers = _getContacts();
    _filteredUsers = _suggestedUsers;
  }

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          S.of(context).linkEmail,
        ),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: MenuSectionTitle(
              title: S.of(context).addANewEmail,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextInputWidget(
              hintText: S.of(context).email,
              textEditingController: _textController,
              shouldSurfaceExecutionStates: false,
              onChange: (value) {
                _filteredUsers = _suggestedUsers
                    .where(
                      (element) => element.email.toLowerCase().contains(
                            _textController.text.trim().toLowerCase(),
                          ),
                    )
                    .toList();

                final filterdFilesHaveSelectedEmail =
                    _filteredUsers.any((user) => user.email == _selectedEmail);
                if (!filterdFilesHaveSelectedEmail) {
                  _selectedEmail = null;
                }

                _newEmail = value.trim();
                _emailIsValid = EmailValidator.validate(_newEmail);
                setState(() {});
              },
              focusNode: textFieldFocusNode,
              keyboardType: TextInputType.emailAddress,
              shouldUnfocusOnClearOrSubmit: true,
              autoCorrect: false,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _filteredUsers.isNotEmpty
                      ? const MenuSectionTitle(
                          title: "Or pick from your contacts",
                        )
                      : const SizedBox.shrink(),
                  Expanded(
                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final currentUser = _filteredUsers[index];
                        return Column(
                          children: [
                            MenuItemWidget(
                              captionedTextWidget: CaptionedTextWidget(
                                title: currentUser.email,
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
                                  (_selectedEmail == currentUser.email)
                                      ? Icons.check
                                      : null,
                              onTap: () async {
                                textFieldFocusNode.unfocus();
                                if (_selectedEmail == currentUser.email) {
                                  _selectedEmail = null;
                                } else {
                                  _selectedEmail = currentUser.email;
                                }
                                setState(() => {});
                              },
                              isTopBorderRadiusRemoved: index > 0,
                              isBottomBorderRadiusRemoved:
                                  index < (_filteredUsers.length - 1),
                            ),
                            (index == (_filteredUsers.length - 1))
                                ? const SizedBox.shrink()
                                : DividerWidget(
                                    dividerType: DividerType.menu,
                                    bgColor:
                                        getEnteColorScheme(context).fillFaint,
                                  ),
                          ],
                        );
                      },
                      itemCount: _filteredUsers.length,
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
                  ButtonWidget(
                    buttonType: ButtonType.primary,
                    buttonSize: ButtonSize.large,
                    labelText: S.of(context).link,
                    isDisabled:
                        !_emailIsValid && (_selectedEmail?.isEmpty ?? true),
                    onTap: _onLinkButtonTap,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onLinkButtonTap() async {
    final newEmail = _emailIsValid ? _newEmail : _selectedEmail!;
    if (widget.isFromSaveOrEditPerson) {
      await _emailHoldsEnteAccount(newEmail).then((value) {
        if (value) {
          Navigator.of(context).pop(newEmail);
        }
      });
    } else {
      try {
        final result = await linkEmailToPerson(
          newEmail,
          widget.personID!,
          context,
        );
        if (!result) {
          _textController.clear();
          return;
        }

        Navigator.of(context).pop(newEmail);
      } catch (e) {
        await showGenericErrorDialog(
          context: context,
          error: e,
        );
        _logger.severe("Failed to link email to person", e);
      }
    }
  }

  List<User> _getContacts() {
    final List<User> suggestedUsers = [];
    final int ownerID = Configuration.instance.getUserID()!;
    final cachedEmailToNameMap = PersonService.instance.emailToNameMapCache;

    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner?.id == ownerID) {
        for (final User? u in c.sharees ?? []) {
          if (u != null && u.id != null && u.email.isNotEmpty) {
            if (!suggestedUsers.any((user) => user.email == u.email) &&
                cachedEmailToNameMap[u.email] == null) {
              suggestedUsers.add(u);
            }
          }
        }
      } else if (c.owner?.id != null && c.owner!.email.isNotEmpty) {
        if (!suggestedUsers.any((user) => user.email == c.owner!.email) &&
            cachedEmailToNameMap[c.owner!.email] == null) {
          suggestedUsers.add(c.owner!);
        }
      }
    }
    final cachedUserDetails = UserService.instance.getCachedUserDetails();
    if (cachedUserDetails?.familyData?.members?.isNotEmpty ?? false) {
      for (final member in cachedUserDetails!.familyData!.members!) {
        if (!suggestedUsers.any((user) => user.email == member.email) &&
            cachedEmailToNameMap[member.email] == null) {
          suggestedUsers.add(User(email: member.email));
        }
      }
    }

    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));

    return suggestedUsers;
  }

  Future<bool> _emailHoldsEnteAccount(String email) async {
    String? publicKey;

    try {
      publicKey = await UserService.instance.getPublicKey(email);
    } catch (e) {
      _logger.severe("Failed to get public key", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    // getPublicKey can return null when no user is associated with given
    // email id
    if (publicKey == null || publicKey == '') {
      await showDialogWidget(
        context: context,
        title: S.of(context).noEnteAccountExclamation,
        body: "$email does not have an ente account.",
        icon: Icons.info_outline,
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            icon: Icons.adaptive.share,
            labelText: S.of(context).invite,
            isInAlert: true,
            onTap: () async {
              unawaited(
                shareText(
                  S.of(context).shareTextRecommendUsingEnte,
                ),
              );
            },
          ),
          ButtonWidget(
            buttonType: ButtonType.secondary,
            labelText: S.of(context).cancel,
            isInAlert: true,
          ),
        ],
      );
      return false;
    } else {
      return true;
    }
  }

  Future<bool> linkEmailToPerson(
    String email,
    String personID,
    BuildContext context,
  ) async {
    if (await checkIfEmailAlreadyAssignedToAPerson(email)) {
      throw Exception("Email already linked to a person");
    }

    String? publicKey;

    try {
      publicKey = await UserService.instance.getPublicKey(email);
    } catch (e) {
      _logger.severe("Failed to get public key", e);
      await showGenericErrorDialog(context: context, error: e);
      return false;
    }
    // getPublicKey can return null when no user is associated with given
    // email id
    if (publicKey == null || publicKey == '') {
      await showDialogWidget(
        context: context,
        title: "No Ente account!",
        icon: Icons.info_outline,
        body: S.of(context).emailNoEnteAccount(email),
        isDismissible: true,
        buttons: [
          ButtonWidget(
            buttonType: ButtonType.neutral,
            icon: Icons.adaptive.share,
            labelText: S.of(context).invite,
            isInAlert: true,
            onTap: () async {
              unawaited(
                shareText(
                  S.of(context).shareTextRecommendUsingEnte,
                ),
              );
            },
          ),
        ],
      );
      return false;
    } else {
      try {
        final personEntity = await PersonService.instance.getPerson(personID);
        late final PersonEntity updatedPerson;

        if (personEntity == null) {
          throw AssertionError(
            "Cannot link email to non-existent person. First save the person",
          );
        } else {
          updatedPerson = await PersonService.instance
              .updateAttributes(personID, email: email);
        }

        Bus.instance.fire(
          PeopleChangedEvent(
            type: PeopleEventType.saveOrEditPerson,
            source: "linkEmailToPerson",
            person: updatedPerson,
          ),
        );
        return true;
      } catch (e) {
        _logger.severe("Failed to link email to person", e);
        await showGenericErrorDialog(context: context, error: e);
        return false;
      }
    }
  }
}
