import "package:email_validator/email_validator.dart";
import "package:ente_configuration/base_configuration.dart";
import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/buttons/button_widget.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";

/// Shows the add contact bottom sheet and returns true if a contact was added
Future<bool?> showAddContactBottomSheet(
  BuildContext context, {
  required EmergencyInfo emergencyInfo,
  required BaseConfiguration config,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => AddContactBottomSheet(
      emergencyInfo: emergencyInfo,
      config: config,
    ),
  );
}

class AddContactBottomSheet extends StatefulWidget {
  final EmergencyInfo emergencyInfo;
  final BaseConfiguration config;

  const AddContactBottomSheet({
    required this.emergencyInfo,
    required this.config,
    super.key,
  });

  @override
  State<StatefulWidget> createState() => _AddContactBottomSheetState();
}

class _AddContactBottomSheetState extends State<AddContactBottomSheet> {
  String selectedEmail = "";
  String _email = "";
  bool _emailIsValid = false;
  int _selectedRecoveryDays = 14;
  late final Logger _logger = Logger("AddContactBottomSheet");

  final textFieldFocusNode = FocusNode();
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(colorScheme, textTheme),
                const SizedBox(height: 12),
                _buildEmailInputRow(colorScheme),
                if (suggestedUsers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildExistingContactsSection(
                    suggestedUsers,
                    colorScheme,
                    textTheme,
                  ),
                ],
                const SizedBox(height: 20),
                _buildRecoveryTimeSection(colorScheme, textTheme),
                const SizedBox(height: 20),
                _buildAddContactButton(textTheme),
                const SizedBox(height: 20),
                _buildVerifyLink(textTheme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.strings.addTrustedContact,
          style: textTheme.largeBold,
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close,
              size: 20,
              color: colorScheme.textBase,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailInputRow(EnteColorScheme colorScheme) {
    return TextFormField(
      controller: _textController,
      focusNode: textFieldFocusNode,
      autofillHints: const [AutofillHints.email],
      decoration: InputDecoration(
        fillColor: colorScheme.fillFaint,
        filled: true,
        hintText: context.strings.enterEmail,
        hintStyle: TextStyle(color: colorScheme.textMuted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.strokeMuted),
        ),
      ),
      onChanged: (value) {
        if (selectedEmail != "") {
          selectedEmail = "";
        }
        _email = value.trim();
        _emailIsValid = EmailValidator.validate(_email);
        setState(() {});
      },
      autocorrect: false,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
    );
  }

  Widget _buildExistingContactsSection(
    List<User> suggestedUsers,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.chooseFromAnExistingContact,
          style: textTheme.bodyMuted,
        ),
        const SizedBox(height: 12),
        Container(
          constraints: const BoxConstraints(maxHeight: 150),
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.zero,
            itemCount: suggestedUsers.length,
            separatorBuilder: (context, index) => DividerWidget(
              dividerType: DividerType.menu,
              bgColor: colorScheme.fillFaint,
            ),
            itemBuilder: (context, index) {
              final user = suggestedUsers[index];
              return MenuItemWidget(
                captionedTextWidget: CaptionedTextWidget(
                  title: user.email,
                ),
                leadingIconSize: 24.0,
                leadingIconWidget: UserAvatarWidget(
                  user,
                  type: AvatarType.mini,
                  currentUserID: widget.config.getUserID()!,
                  config: widget.config,
                  thumbnailView: false,
                ),
                menuItemColor: Colors.transparent,
                pressedColor: colorScheme.fillFaintPressed,
                trailingIcon:
                    (selectedEmail == user.email) ? Icons.check : null,
                onTap: () async {
                  textFieldFocusNode.unfocus();
                  if (selectedEmail == user.email) {
                    selectedEmail = "";
                  } else {
                    selectedEmail = user.email;
                  }
                  setState(() {});
                },
                isTopBorderRadiusRemoved: index > 0,
                isBottomBorderRadiusRemoved:
                    index < (suggestedUsers.length - 1),
                singleBorderRadius: 8,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecoveryTimeSection(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.chooseARecoveryTime,
          style: textTheme.bodyMuted,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildRecoveryChip(7, colorScheme, textTheme),
            const SizedBox(width: 12),
            _buildRecoveryChip(14, colorScheme, textTheme),
            const SizedBox(width: 12),
            _buildRecoveryChip(30, colorScheme, textTheme),
          ],
        ),
      ],
    );
  }

  Widget _buildRecoveryChip(
    int days,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final isSelected = _selectedRecoveryDays == days;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRecoveryDays = days;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 16.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          context.strings.nDays(days),
          style: textTheme.body.copyWith(
            color: isSelected ? Colors.white : colorScheme.primary700,
          ),
        ),
      ),
    );
  }

  Widget _buildAddContactButton(EnteTextTheme textTheme) {
    final bool canAdd = selectedEmail.isNotEmpty || _emailIsValid;
    return GradientButton(
      text: context.strings.addTrustedContact,
      onTap: canAdd ? _onAddContactTap : null,
    );
  }

  Future<void> _onAddContactTap() async {
    final emailToAdd = selectedEmail.isNotEmpty ? selectedEmail : _email;
    final choiceResult = await showChoiceActionSheet(
      context,
      title: context.strings.warning,
      body: context.strings.confirmAddingTrustedContact(
        emailToAdd,
        _selectedRecoveryDays,
      ),
      firstButtonLabel: context.strings.proceed,
      isCritical: true,
    );
    if (choiceResult != null && choiceResult.action == ButtonAction.first) {
      try {
        final r = await EmergencyContactService.instance.addContact(
          context,
          emailToAdd,
        );
        if (r && mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        _logger.severe("Failed to add contact", e);
        if (mounted) {
          await showErrorDialog(
            context,
            context.strings.error,
            context.strings.somethingWentWrong,
          );
        }
      }
    }
  }

  Widget _buildVerifyLink(EnteTextTheme textTheme) {
    final bool canAdd = selectedEmail.isNotEmpty || _emailIsValid;

    return Center(
      child: GestureDetector(
        onTap: _onVerifyTap,
        child: Text(
          context.strings.verifyIDLabel,
          textAlign: TextAlign.center,
          style: textTheme.body.copyWith(
            color: canAdd
                ? getEnteColorScheme(context).primary700
                : getEnteColorScheme(context).textMuted,
            decoration: TextDecoration.underline,
            decorationColor: canAdd
                ? getEnteColorScheme(context).primary700
                : getEnteColorScheme(context).textMuted,
          ),
        ),
      ),
    );
  }

  Future<void> _onVerifyTap() async {
    if (selectedEmail.isEmpty && !_emailIsValid) {
      await showErrorDialog(
        context,
        context.strings.invalidEmailAddress,
        context.strings.enterValidEmail,
      );
      return;
    }
    final emailToAdd = selectedEmail.isNotEmpty ? selectedEmail : _email;
    await showVerifyIdentitySheet(
      context,
      self: false,
      email: emailToAdd,
      config: widget.config,
    );
  }

  List<User> _getSuggestedUser() {
    final List<User> suggestedUsers = [];
    // Get suggested users from emergencyInfo if available
    // For now, return contacts that are already trusted by others
    for (final contact in widget.emergencyInfo.othersEmergencyContact) {
      if (!suggestedUsers.any((u) => u.email == contact.user.email)) {
        suggestedUsers.add(contact.user);
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
