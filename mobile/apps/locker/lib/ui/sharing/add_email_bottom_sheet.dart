import "package:email_validator/email_validator.dart";
import "package:ente_accounts/services/user_service.dart";
import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_sharing/verify_identity_dialog.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:intl/intl.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/components/popup_menu_item_widget.dart";
import "package:locker/ui/viewer/date/date_time_picker.dart";
import "package:locker/utils/collection_actions.dart";

class AddEmailBottomSheet extends StatefulWidget {
  final Collection collection;
  final VoidCallback onShareAdded;

  const AddEmailBottomSheet({
    super.key,
    required this.collection,
    required this.onShareAdded,
  });

  @override
  State<AddEmailBottomSheet> createState() => _AddEmailBottomSheetState();
}

class _AddEmailBottomSheetState extends State<AddEmailBottomSheet> {
  bool _shareLater = false;
  String _email = "";
  bool _emailIsValid = false;
  DateTime? _scheduledDate;
  TimeOfDay? _scheduledTime;
  CollectionParticipantRole _selectedRole = CollectionParticipantRole.viewer;

  final _textController = TextEditingController();
  final _textFieldFocusNode = FocusNode();
  final _scrollController = ScrollController();

  late CollectionActions _collectionActions;
  late List<User> _suggestedUsers;

  @override
  void initState() {
    super.initState();
    _collectionActions = CollectionActions();
    _suggestedUsers = _getSuggestedUsers();
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFieldFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
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
                  const SizedBox(height: 20),
                  _buildEmailInputField(colorScheme, textTheme),
                  if (_suggestedUsers.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _buildExistingContactsSection(colorScheme, textTheme),
                  ],
                  // _buildShareLaterCheckbox(colorScheme, textTheme),
                  if (_shareLater) ...[
                    const SizedBox(height: 12),
                    _buildScheduleDateTimeRow(colorScheme, textTheme),
                  ],
                  const SizedBox(height: 20),
                  _buildShareButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(colorScheme, textTheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          context.l10n.addNewEmail,
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

  Widget _buildEmailInputField(colorScheme, textTheme) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              focusNode: _textFieldFocusNode,
              autofillHints: const [AutofillHints.email],
              decoration: InputDecoration(
                hintText: context.l10n.enterNameOrEmailToShareWith,
                hintStyle: textTheme.body.copyWith(
                  color: colorScheme.textMuted,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
              onChanged: (value) {
                _email = value.trim();
                _emailIsValid = _isValidEmail(_email);
                setState(() {});
              },
              autocorrect: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
            ),
          ),
          // TODO: Re-enable role selection when collaborator role is available
          // Padding(
          //   padding: const EdgeInsets.only(right: 8),
          //   child: _buildRoleDropdown(colorScheme, textTheme),
          // ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown(colorScheme, textTheme) {
    return PopupMenuButton<CollectionParticipantRole>(
      onSelected: (role) {
        setState(() {
          _selectedRole = role;
        });
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.strokeFaint),
      ),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      color: colorScheme.backdropBase,
      surfaceTintColor: Colors.transparent,
      elevation: 15,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      constraints: const BoxConstraints(minWidth: 120),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.backdropBase,
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: _selectedRole == CollectionParticipantRole.viewer
                  ? HugeIcons.strokeRoundedView
                  : HugeIcons.strokeRoundedUserMultiple,
              color: colorScheme.textBase,
              size: 20,
            ),
            const SizedBox(width: 4),
            HugeIcon(
              icon: HugeIcons.strokeRoundedArrowDown01,
              color: colorScheme.textBase,
              size: 24,
            ),
          ],
        ),
      ),
      // TODO: Re-enable collaborator option when ready
      // For now, only viewer role is available in Locker
      itemBuilder: (context) => [
        PopupMenuItem<CollectionParticipantRole>(
          value: CollectionParticipantRole.viewer,
          height: 0,
          padding: EdgeInsets.zero,
          child: PopupMenuItemWidget(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedView,
              color: colorScheme.textBase,
              size: 20,
            ),
            label: context.l10n.viewer,
            isFirst: true,
            isLast: true,
          ),
        ),
      ],
    );
  }

  Widget _buildExistingContactsSection(colorScheme, textTheme) {
    final filteredUsers = _suggestedUsers
        .where(
          (user) => user.email
              .toLowerCase()
              .contains(_textController.text.trim().toLowerCase()),
        )
        .toList();

    if (filteredUsers.isEmpty) {
      return const SizedBox.shrink();
    }

    const double maxVisibleHeight = 121.0;
    final showScrollbar = filteredUsers.length > 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.chooseFromAnExistingContact,
          style: textTheme.small.copyWith(color: colorScheme.textMuted),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  constraints:
                      const BoxConstraints(maxHeight: maxVisibleHeight),
                  child: ListView.builder(
                    controller: _scrollController,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      final isFirst = index == 0;
                      final isLast = index == filteredUsers.length - 1;
                      return Column(
                        children: [
                          if (!isFirst)
                            DividerWidget(
                              dividerType: DividerType.menu,
                              bgColor: colorScheme.fillFaint,
                            ),
                          MenuItemWidgetV2(
                            captionedTextWidget: CaptionedTextWidgetV2(
                              title: user.email,
                            ),
                            leadingIconSize: 24.0,
                            leadingIconWidget: UserAvatarWidget(
                              user,
                              type: AvatarType.mini,
                              config: Configuration.instance,
                            ),
                            menuItemColor: colorScheme.fillFaint,
                            surfaceExecutionStates: false,
                            onTap: () async {
                              _textFieldFocusNode.unfocus();
                              _textController.text = user.email;
                              _email = user.email;
                              _emailIsValid = true;
                              setState(() {});
                            },
                            onLongPress: () {
                              showVerifyIdentitySheet(
                                context,
                                self: false,
                                config: Configuration.instance,
                                email: user.email,
                              );
                            },
                            isTopBorderRadiusRemoved: !isFirst,
                            isBottomBorderRadiusRemoved: !isLast,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
            if (showScrollbar) ...[
              const SizedBox(width: 4),
              _buildCustomScrollbar(
                filteredUsers.length,
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
    colorScheme,
  ) {
    const visibleItems = 2;
    final thumbHeightRatio = visibleItems / itemCount;
    final thumbHeight = containerHeight * thumbHeightRatio;

    return AnimatedBuilder(
      animation: _scrollController,
      builder: (context, child) {
        double thumbPosition = 0;
        if (_scrollController.hasClients &&
            _scrollController.positions.length == 1) {
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

  Widget _buildShareLaterCheckbox(colorScheme, textTheme) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _shareLater = !_shareLater;
          if (!_shareLater) {
            _scheduledDate = null;
            _scheduledTime = null;
          }
        });
      },
      child: SizedBox(
        width: double.infinity,
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _shareLater
                      ? colorScheme.primary700
                      : colorScheme.strokeMuted,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
                color:
                    _shareLater ? colorScheme.primary700 : Colors.transparent,
              ),
              alignment: Alignment.center,
              child: _shareLater
                  ? const Icon(
                      Icons.check,
                      size: 12,
                      color: Colors.white,
                    )
                  : null,
            ),
            Text(
              context.l10n.shareLater,
              style: textTheme.small,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleDateTimeRow(colorScheme, textTheme) {
    final dateText = _scheduledDate != null
        ? DateFormat("dd/MM/yy").format(_scheduledDate!)
        : "DD/MM/YY";
    final timeText = _scheduledTime != null
        ? "${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')}"
        : "00:00";

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: colorScheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: textTheme.small.copyWith(
                      color: _scheduledDate != null
                          ? colorScheme.textBase
                          : colorScheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: _selectTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    size: 18,
                    color: colorScheme.textMuted,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: textTheme.small.copyWith(
                      color: _scheduledTime != null
                          ? colorScheme.textBase
                          : colorScheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final initialDate = _scheduledDate ??
        DateTime.now().add(
          const Duration(days: 1),
        );
    final pickedDate = await showDatePickerSheet(
      context,
      initialDate: initialDate,
      minDate: DateTime.now(),
    );
    if (pickedDate != null && mounted) {
      setState(() {
        _scheduledDate = pickedDate;
      });
    }
  }

  Future<void> _selectTime() async {
    final initialTime = _scheduledTime ?? TimeOfDay.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (pickedTime != null && mounted) {
      setState(() {
        _scheduledTime = pickedTime;
      });
    }
  }

  Widget _buildShareButton() {
    final bool canShare =
        _emailIsValid && (!_shareLater || _isScheduledDateTimeValid());
    final buttonText =
        _shareLater ? context.l10n.scheduleShare : context.l10n.share;
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        text: buttonText,
        onTap: canShare ? _onShareTap : null,
      ),
    );
  }

  Future<void> _onShareTap() async {
    final success = await _collectionActions.addEmailToCollection(
      context,
      widget.collection,
      _email,
      _selectedRole,
      showProgress: true,
    );

    if (success) {
      widget.onShareAdded();
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  List<User> _getSuggestedUsers() {
    final List<User> suggestedUsers = [];
    final Set<String> existingEmails = {};

    existingEmails.add(Configuration.instance.getEmail() ?? "");
    final int ownerID = Configuration.instance.getUserID()!;

    for (final c in CollectionService.instance.getActiveCollections()) {
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

    suggestedUsers.sort((a, b) => a.email.compareTo(b.email));
    return suggestedUsers;
  }

  bool _isValidEmail(String email) {
    return EmailValidator.validate(email);
  }

  bool _isScheduledDateTimeValid() {
    if (_scheduledDate == null || _scheduledTime == null) {
      return false;
    }
    final scheduledDateTime = DateTime(
      _scheduledDate!.year,
      _scheduledDate!.month,
      _scheduledDate!.day,
      _scheduledTime!.hour,
      _scheduledTime!.minute,
    );
    return scheduledDateTime.isAfter(DateTime.now());
  }
}
