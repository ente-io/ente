import "package:email_validator/email_validator.dart";
import "package:ente_configuration/base_configuration.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/buttons/models/button_type.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_description_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";

class AddContactPage extends StatefulWidget {
  final EmergencyInfo emergencyInfo;
  final BaseConfiguration config;

  const AddContactPage(
    this.emergencyInfo, {
    super.key,
    required this.config,
  });

  @override
  State<StatefulWidget> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  String selectedEmail = '';
  String _email = '';
  bool isEmailListEmpty = false;
  bool _emailIsValid = false;
  bool isKeypadOpen = false;
  late final Logger _logger = Logger('AddContactPage');

  // Focus nodes are necessary
  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void initState() {
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
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();
    isEmailListEmpty = suggestedUsers.isEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: isKeypadOpen,
      appBar: AppBar(
        title: Text(
          context.strings.addTrustedContact,
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
              context.strings.addANewEmail,
              style: textTheme.small.copyWith(color: colorScheme.textMuted),
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
                            title: context.strings.orPickAnExistingOne,
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
                                content: context.strings.whyAddTrustContact,
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
                                leadingIconWidget: CircleAvatar(
                                  radius: 12,
                                  child: Text(
                                    currentUser.email
                                        .substring(0, 1)
                                        .toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                menuItemColor: colorScheme.fillFaint,
                                pressedColor: colorScheme.fillFaint,
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
                                  setState(() {});
                                },
                                isTopBorderRadiusRemoved: index > 0,
                                isBottomBorderRadiusRemoved:
                                    index < (suggestedUsers.length - 1),
                              ),
                              (index == (suggestedUsers.length - 1))
                                  ? const SizedBox.shrink()
                                  : DividerWidget(
                                      dividerType: DividerType.menu,
                                      bgColor: colorScheme.fillFaint,
                                    ),
                            ],
                          );
                        },
                        itemCount: suggestedUsers.length + 1,
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
                              title: context.strings.warning,
                              body: context.strings.confirmAddingTrustedContact(
                                emailToAdd,
                                30,
                              ),
                              firstButtonLabel: context.strings.proceed,
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
                                  context.strings.error,
                                  context.strings.somethingWentWrong,
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
                          context.strings.invalidEmailAddress,
                          context.strings.enterValidEmail,
                        );
                        return;
                      }
                      final emailToAdd =
                          selectedEmail == '' ? _email : selectedEmail;
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return VerifyIdentityDialog(
                            self: false,
                            email: emailToAdd,
                            config: widget.config,
                          );
                        },
                      );
                    },
                    child: Text(
                      context.strings.verifyIDLabel,
                      textAlign: TextAlign.center,
                      style: textTheme.smallMuted.copyWith(
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
    setState(() {});
  }

  Widget _getEmailField() {
    final colorScheme = getEnteColorScheme(context);
    return TextFormField(
      controller: _textController,
      focusNode: textFieldFocusNode,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: const BorderRadius.all(Radius.circular(4.0)),
          borderSide: BorderSide(color: colorScheme.strokeMuted),
        ),
        fillColor: colorScheme.fillFaint,
        filled: true,
        hintText: context.strings.enterEmail,
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
          color: colorScheme.strokeMuted,
        ),
        suffixIcon: _email == ''
            ? null
            : IconButton(
                onPressed: clearFocus,
                icon: Icon(
                  Icons.cancel,
                  color: colorScheme.strokeMuted,
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
      textInputAction: TextInputAction.next,
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    // For now, return an empty list since we don't have access to CollectionsService
    // In a real implementation, this would fetch users from shared collections

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
