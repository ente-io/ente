import "package:email_validator/email_validator.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_configuration/base_configuration.dart";
import "package:ente_legacy/components/alert_bottom_sheet.dart";
import "package:ente_legacy/components/gradient_button.dart";
import "package:ente_legacy/components/recovery_date_selector.dart";
import "package:ente_legacy/models/emergency_models.dart";
import "package:ente_legacy/services/emergency_service.dart";
import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
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
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    textFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final List<User> suggestedUsers = _getSuggestedUser();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                  _buildRecoveryTimeSection(textTheme),
                  const SizedBox(height: 20),
                  _buildAddContactButton(textTheme),
                  const SizedBox(height: 12),
                  _buildVerifyLink(textTheme),
                ],
              ),
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
    const double maxVisibleHeight = 121.0;
    final showScrollbar = suggestedUsers.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.chooseFromAnExistingContact,
          style: textTheme.bodyMuted,
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: maxVisibleHeight),
                child: ListView.separated(
                  controller: _scrollController,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: suggestedUsers.length,
                  separatorBuilder: (context, index) => DividerWidget(
                    dividerType: DividerType.menu,
                    bgColor: colorScheme.fillFaint,
                  ),
                  itemBuilder: (context, index) {
                    final user = suggestedUsers[index];
                    final isFirst = index == 0;
                    final isLast = index == suggestedUsers.length - 1;
                    return MenuItemWidgetV2(
                      captionedTextWidget: CaptionedTextWidgetV2(
                        title: user.email,
                        textStyle: textTheme.small.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      ),
                      leadingIconSize: 24.0,
                      leadingIconWidget: UserAvatarWidget(
                        user,
                        type: AvatarType.mini,
                        currentUserID: widget.config.getUserID()!,
                        config: widget.config,
                        thumbnailView: false,
                      ),
                      menuItemColor: colorScheme.fillFaint,
                      pressedColor: colorScheme.fillFaintPressed,
                      trailingIcon:
                          (selectedEmail == user.email) ? Icons.check : null,
                      trailingIconColor: colorScheme.primary500,
                      surfaceExecutionStates: false,
                      onTap: () async {
                        textFieldFocusNode.unfocus();
                        if (selectedEmail == user.email) {
                          selectedEmail = "";
                        } else {
                          selectedEmail = user.email;
                        }
                        setState(() {});
                      },
                      isTopBorderRadiusRemoved: !isFirst,
                      isBottomBorderRadiusRemoved: !isLast,
                      isFirstItem: isFirst,
                      isLastItem: isLast,
                      singleBorderRadius: 20,
                      multipleBorderRadius: 20,
                    );
                  },
                ),
              ),
            ),
            if (showScrollbar) ...[
              const SizedBox(width: 4),
              _buildCustomScrollbar(
                suggestedUsers.length,
                maxVisibleHeight,
                colorScheme,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildCustomScrollbar(
    int itemCount,
    double containerHeight,
    EnteColorScheme colorScheme,
  ) {
    const visibleItems = 2;
    final thumbHeightRatio = visibleItems / itemCount;
    final thumbHeight = containerHeight * thumbHeightRatio;

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        double thumbPosition = 0;
        if (_scrollController.hasClients) {
          final maxExtent = _scrollController.position.hasContentDimensions
              ? _scrollController.position.maxScrollExtent
              : 0.0;
          if (maxExtent > 0) {
            final scrollFraction = _scrollController.offset / maxExtent;
            thumbPosition = scrollFraction * (containerHeight - thumbHeight);
          }
        }

        return SizedBox(
          height: containerHeight,
          width: 5,
          child: Stack(
            children: [
              Container(
                width: 5,
                height: containerHeight,
                decoration: BoxDecoration(
                  color: colorScheme.strokeFaint,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              Positioned(
                top: thumbPosition,
                child: Container(
                  width: 5,
                  height: thumbHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.strokeMuted,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecoveryTimeSection(EnteTextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.strings.chooseARecoveryTime,
          style: textTheme.bodyMuted,
        ),
        const SizedBox(height: 12),
        RecoveryDateSelector(
          selectedDays: _selectedRecoveryDays,
          onDaysChanged: (days) {
            setState(() {
              _selectedRecoveryDays = days;
            });
          },
        ),
      ],
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
    final confirmed = await _showAddContactConfirmationDialog(
      emailToAdd,
      _selectedRecoveryDays,
    );
    if (confirmed == true) {
      final dialog = createProgressDialog(
        context,
        context.strings.pleaseWait,
      );
      await dialog.show();
      try {
        final r = await EmergencyContactService.instance.addContact(
          context,
          emailToAdd,
          _selectedRecoveryDays,
        );
        await dialog.hide();
        if (r && mounted) {
          Navigator.of(context).pop(true);
        }
      } catch (e) {
        await dialog.hide();
        _logger.severe("Failed to add contact", e);
        if (mounted) {
          await showAlertBottomSheet(
            context,
            title: context.strings.error,
            message: context.strings.somethingWentWrong,
            assetPath: "assets/warning-blue.png",
          );
        }
      }
    }
  }

  Future<bool?> _showAddContactConfirmationDialog(
    String email,
    int recoveryDays,
  ) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated2,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colorScheme.fillFaint,
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: colorScheme.textBase,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Image.asset("assets/warning-blue.png"),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.strings.warning,
                    style: textTheme.h3Bold,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.strings.confirmAddingTrustedContact(
                      email,
                      recoveryDays,
                    ),
                    textAlign: TextAlign.center,
                    style: textTheme.body.copyWith(
                      color: colorScheme.textMuted,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: GradientButton(
                      onTap: () => Navigator.of(context).pop(true),
                      text: context.strings.proceed,
                      backgroundColor: colorScheme.warning400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVerifyLink(EnteTextTheme textTheme) {
    final bool canAdd = selectedEmail.isNotEmpty || _emailIsValid;

    return Center(
      child: GestureDetector(
        onTap: _onVerifyTap,
        child: Text(
          context.strings.verifyIDLabel,
          style: textTheme.bodyBold.copyWith(
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
      await showAlertBottomSheet(
        context,
        title: context.strings.invalidEmailAddress,
        message: context.strings.enterValidEmail,
        assetPath: "assets/warning-blue.png",
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
    final Set<String> existingEmails = {};

    existingEmails.add(widget.config.getEmail() ?? "");

    // Get suggested users from othersEmergencyContact (people who added you)
    for (final contact in widget.emergencyInfo.othersEmergencyContact) {
      if (!existingEmails.contains(contact.user.email)) {
        existingEmails.add(contact.user.email);
        suggestedUsers.add(contact.user);
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

    // Filter by search text
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
