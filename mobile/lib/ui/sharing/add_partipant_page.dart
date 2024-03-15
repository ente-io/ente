import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/user_service.dart";
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import "package:photos/utils/dialog_util.dart";

class AddParticipantPage extends StatefulWidget {
  final Collection collection;
  final bool isAddingViewer;

  const AddParticipantPage(this.collection, this.isAddingViewer, {super.key});

  @override
  State<StatefulWidget> createState() => _AddParticipantPage();
}

class _AddParticipantPage extends State<AddParticipantPage> {
  final _selectedEmails = <String>[];
  String selectedEmail = '';
  String _email = '';
  bool isEmailListEmpty = false;
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
    isKeypadOpen = MediaQuery.viewInsetsOf(context).bottom > 100;
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);
    isEmailListEmpty = _suggestedUsers.isEmpty;
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          widget.isAddingViewer
              ? S.of(context).addViewer
              : S.of(context).addCollaborator,
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
              S.of(context).addANewEmail,
              style: enteTextTheme.small
                  .copyWith(color: enteColorScheme.textMuted),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _enterEmailField(),
          ),
          (isEmailListEmpty && widget.isAddingViewer)
              ? const Expanded(child: SizedBox.shrink())
              : Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: [
                        !isEmailListEmpty
                            ? MenuSectionTitle(
                                title: S.of(context).orPickAnExistingOne,
                              )
                            : const SizedBox.shrink(),
                        Expanded(
                          child: ListView.builder(
                            physics: const BouncingScrollPhysics(),
                            itemBuilder: (context, index) {
                              if (index >= _suggestedUsers.length) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: MenuSectionDescriptionWidget(
                                    content: S
                                        .of(context)
                                        .collaboratorsCanAddPhotosAndVideosToTheSharedAlbum,
                                  ),
                                );
                              }
                              final currentUser = _suggestedUsers[index];
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
                                    trailingIcon: (_selectedEmails
                                            .contains(currentUser.email))
                                        ? Icons.check
                                        : null,
                                    onTap: () async {
                                      textFieldFocusNode.unfocus();
                                      if (_selectedEmails
                                          .contains(currentUser.email)) {
                                        _selectedEmails
                                            .remove(currentUser.email);
                                      } else {
                                        _selectedEmails.add(currentUser.email);
                                      }

                                      setState(() => {});
                                      // showShortToast(context, "yet to implement");
                                    },
                                    isTopBorderRadiusRemoved: index > 0,
                                    isBottomBorderRadiusRemoved:
                                        index < (_suggestedUsers.length - 1),
                                  ),
                                  (index == (_suggestedUsers.length - 1))
                                      ? const SizedBox.shrink()
                                      : DividerWidget(
                                          dividerType: DividerType.menu,
                                          bgColor: getEnteColorScheme(context)
                                              .fillFaint,
                                        ),
                                ],
                              );
                            },
                            itemCount: _suggestedUsers.length +
                                (widget.isAddingViewer ? 0 : 1),
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
                    labelText: widget.isAddingViewer
                        ? S.of(context).addViewer
                        : S.of(context).addCollaborator,
                    isDisabled: (selectedEmail == '' && !_emailIsValid),
                    onTap: (selectedEmail == '' && !_emailIsValid)
                        ? null
                        : () async {
                            final emailToAdd =
                                selectedEmail == '' ? _email : selectedEmail;
                            final result =
                                await collectionActions.addEmailToCollection(
                              context,
                              widget.collection,
                              emailToAdd,
                              widget.isAddingViewer
                                  ? CollectionParticipantRole.viewer
                                  : CollectionParticipantRole.collaborator,
                            );
                            if (result && mounted) {
                              Navigator.of(context).pop(true);
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      if ((selectedEmail == '' && !_emailIsValid)) {
                        await showErrorDialog(
                          context,
                          S.of(context).invalidEmailAddress,
                          S.of(context).enterValidEmail,
                        );
                        return;
                      }
                      final emailToAdd =
                          selectedEmail == '' ? _email : selectedEmail;
                      // ignore: unawaited_futures
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return VerifyIdentifyDialog(
                            self: false,
                            email: emailToAdd,
                          );
                        },
                      );
                    },
                    child: Text(
                      S.of(context).verifyIDLabel,
                      textAlign: TextAlign.center,
                      style: enteTextTheme.smallMuted.copyWith(
                        decoration: TextDecoration.underline,
                      ),
                    ),
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

  void clearFocus() {
    _textController.clear();
    _email = _textController.text;
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
              hintText: S.of(context).enterEmail,
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
              suffixIcon: _email == ''
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
              if (selectedEmail != '') {
                selectedEmail = '';
              }
              _email = value.trim();
              _emailIsValid = EmailValidator.validate(_email);
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
          labelText: "Add",
          isDisabled: !_emailIsValid,
          onTap: () async {
            if (_emailIsValid) {
              final result = await collectionActions.doesEmailHaveAccount(
                context,
                _email,
              );
              if (result && mounted) {
                setState(() {
                  for (var suggestedUser in _suggestedUsers) {
                    if (suggestedUser.email == _email) {
                      _selectedEmails.add(suggestedUser.email);
                      return;
                    }
                  }
                  _suggestedUsers.insert(0, User(email: _email));
                  _selectedEmails.add(_email);
                });
              }
            }
          },
        ),
      ],
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    final Set<String> existingEmails = {};
    final int ownerID = Configuration.instance.getUserID()!;
    existingEmails.add(Configuration.instance.getEmail()!);
    for (final User? u in widget.collection.sharees ?? []) {
      if (u != null && u.id != null && u.email.isNotEmpty) {
        existingEmails.add(u.email);
      }
    }
    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner?.id == ownerID) {
        for (final User? u in c.sharees ?? []) {
          if (u != null &&
              u.id != null &&
              u.email.isNotEmpty &&
              !existingEmails.contains(u.email)) {
            existingEmails.add(u.email);
            suggestedUsers.add(u);
          }
        }
      } else if (c.owner != null &&
          c.owner!.id != null &&
          c.owner!.email.isNotEmpty &&
          !existingEmails.contains(c.owner!.email)) {
        existingEmails.add(c.owner!.email);
        suggestedUsers.add(c.owner!);
      }
    }
    final cachedUserDetails = UserService.instance.getCachedUserDetails();
    if (cachedUserDetails != null &&
        (cachedUserDetails.familyData?.members?.isNotEmpty ?? false)) {
      for (final member in cachedUserDetails.familyData!.members!) {
        if (!existingEmails.contains(member.email)) {
          existingEmails.add(member.email);
          suggestedUsers.add(User(email: member.email));
        }
      }
    }
    if (_textController.text.trim().isNotEmpty) {
      suggestedUsers.removeWhere(
        (element) => !element.email
            .toLowerCase()
            .contains(_textController.text.trim().toLowerCase()),
      );
    }
    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));

    return suggestedUsers;
  }
}
