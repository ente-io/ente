import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/emergency/emergency_service.dart";
import "package:photos/emergency/model.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
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
import 'package:photos/ui/sharing/user_avator_widget.dart';
import "package:photos/ui/sharing/verify_identity_dialog.dart";
import "package:photos/utils/dialog_util.dart";

class AddContactPage extends StatefulWidget {
  final EmergencyInfo emergencyInfo;

  const AddContactPage(this.emergencyInfo, {super.key});

  @override
  State<StatefulWidget> createState() => _AddContactPage();
}

class _AddContactPage extends State<AddContactPage> {
  String selectedEmail = '';
  String _email = '';
  bool isEmailListEmpty = false;
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late CollectionActions collectionActions;
  late final Logger _logger = Logger('AddContactPage');

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
    collectionActions = CollectionActions(CollectionsService.instance);
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    isKeypadOpen = MediaQuery.of(context).viewInsets.bottom > 100;
    final enteTextTheme = getEnteTextTheme(context);
    final enteColorScheme = getEnteColorScheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();
    isEmailListEmpty = suggestedUsers.isEmpty;
    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context).addTrustedContact,
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
            child: _getEmailField(),
          ),
          if (isEmailListEmpty)
            const Expanded(child: SizedBox.shrink())
          else
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    !isEmailListEmpty
                        ? MenuSectionTitle(
                            title: AppLocalizations.of(context)
                                .orPickAnExistingOne,
                          )
                        : const SizedBox.shrink(),
                    Expanded(
                      child: ListView.builder(
                        itemBuilder: (context, index) {
                          if (index >= suggestedUsers.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: MenuSectionDescriptionWidget(
                                content: AppLocalizations.of(context)
                                    .whyAddTrustContact,
                              ),
                            );
                          }
                          final currentUser = suggestedUsers[index];
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
                                    (selectedEmail == currentUser.email)
                                        ? Icons.check
                                        : null,
                                onTap: () async {
                                  textFieldFocusNode.unfocus();
                                  if (selectedEmail == currentUser.email) {
                                    selectedEmail = '';
                                  } else {
                                    selectedEmail = currentUser.email;
                                  }
                                  setState(() => {});
                                },
                                isTopBorderRadiusRemoved: index > 0,
                                isBottomBorderRadiusRemoved:
                                    index < (suggestedUsers.length - 1),
                              ),
                              (index == (suggestedUsers.length - 1))
                                  ? const SizedBox.shrink()
                                  : DividerWidget(
                                      dividerType: DividerType.menu,
                                      bgColor:
                                          getEnteColorScheme(context).fillFaint,
                                    ),
                            ],
                          );
                        },
                        itemCount: suggestedUsers.length + 1,
                        // physics: const ClampingScrollPhysics(),
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
                    labelText: "Add",
                    isDisabled: (selectedEmail == '' && !_emailIsValid),
                    onTap: (selectedEmail == '' && !_emailIsValid)
                        ? null
                        : () async {
                            final emailToAdd =
                                selectedEmail == '' ? _email : selectedEmail;
                            final choiceResult = await showChoiceActionSheet(
                              context,
                              title: AppLocalizations.of(context).warning,
                              body: AppLocalizations.of(context)
                                  .confirmAddingTrustedContact(
                                email: emailToAdd,
                                numOfDays: 30,
                              ),
                              firstButtonLabel:
                                  AppLocalizations.of(context).proceed,
                              isCritical: true,
                            );
                            if (choiceResult != null &&
                                choiceResult.action == ButtonAction.first) {
                              try {
                                final r = await EmergencyContactService.instance
                                    .addContact(context, emailToAdd);
                                if (r && mounted) {
                                  Navigator.of(context).pop(true);
                                }
                              } catch (e) {
                                _logger.severe('Failed to add contact', e);
                                await showErrorDialog(
                                  context,
                                  AppLocalizations.of(context).error,
                                  AppLocalizations.of(context)
                                      .somethingWentWrong,
                                );
                              }
                            }
                          },
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      if ((selectedEmail == '' && !_emailIsValid)) {
                        await showErrorDialog(
                          context,
                          AppLocalizations.of(context).invalidEmailAddress,
                          AppLocalizations.of(context).enterValidEmail,
                        );
                        return;
                      }
                      final emailToAdd =
                          selectedEmail == '' ? _email : selectedEmail;
                      await showDialog(
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
                      AppLocalizations.of(context).verifyIDLabel,
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

  Widget _getEmailField() {
    return TextFormField(
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
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    final Set<String> existingEmails = {};
    final int ownerID = Configuration.instance.getUserID()!;
    existingEmails.add(Configuration.instance.getEmail()!);
    for (final c in CollectionsService.instance.getActiveCollections()) {
      if (c.owner.id == ownerID) {
        for (final User u in c.sharees) {
          if (u.id != null &&
              u.email.isNotEmpty &&
              !existingEmails.contains(u.email)) {
            existingEmails.add(u.email);
            suggestedUsers.add(u);
          }
        }
      } else if (c.owner.id != null &&
          c.owner.email.isNotEmpty &&
          !existingEmails.contains(c.owner.email)) {
        existingEmails.add(c.owner.email);
        suggestedUsers.add(c.owner);
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
