import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/alert_bottom_sheet.dart";
import "package:ente_ui/components/base_bottom_sheet.dart";
import "package:ente_ui/components/captioned_text_widget_v2.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget_v2.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/components/popup_menu_item_widget.dart";
import "package:locker/ui/sharing/add_email_bottom_sheet.dart";
import "package:locker/utils/collection_actions.dart";

Future<void> showShareCollectionSheet(
  BuildContext context, {
  required Collection collection,
}) {
  return showBaseBottomSheet<void>(
    context,
    title: context.l10n.sharedWith,
    headerSpacing: 20,
    child: ShareCollectionSheet(collection: collection),
  );
}

class ShareCollectionSheet extends StatefulWidget {
  final Collection collection;

  const ShareCollectionSheet({
    super.key,
    required this.collection,
  });

  @override
  State<ShareCollectionSheet> createState() => _ShareCollectionSheetState();
}

class _ShareCollectionSheetState extends State<ShareCollectionSheet> {
  late CollectionActions _collectionActions;
  final ScrollController _scrollController = ScrollController();

  List<User> get _sharees => widget.collection.getSharees();

  bool get _isOwner {
    final currentUserId = Configuration.instance.getUserID();
    return widget.collection.owner.id == currentUserId;
  }

  @override
  void initState() {
    super.initState();
    _collectionActions = CollectionActions();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildShareesList(colorScheme, textTheme),
        if (_isOwner) ...[
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: GradientButton(
              text: context.l10n.addEmail,
              onTap: () async {
                await showAddEmailSheet(
                  context,
                  collection: widget.collection,
                  onShareAdded: () {
                    if (mounted) {
                      setState(() {});
                    }
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildShareesList(colorScheme, textTheme) {
    final currentUserId = Configuration.instance.getUserID() ?? -1;

    final List<User> allUsers = [];

    if (!_isOwner) {
      final owner = widget.collection.owner;
      owner.role = CollectionParticipantRole.owner.toStringVal();
      allUsers.add(owner);
    }

    allUsers.addAll(_sharees);

    if (allUsers.isEmpty) {
      return Text(
        context.l10n.noSharedUsers,
        style: textTheme.small.copyWith(color: colorScheme.textMuted),
      );
    }

    const double maxVisibleHeight = 244.0;
    final showScrollbar = allUsers.length > 4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: maxVisibleHeight),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final isFirst = index == 0;
                  final isLast = index == allUsers.length - 1;
                  final role =
                      CollectionParticipantRoleExtn.fromString(user.role);

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
                        leadingIconSize: 24,
                        leadingIconWidget: UserAvatarWidget(
                          user,
                          currentUserID: currentUserId,
                          config: Configuration.instance,
                          type: AvatarType.mini,
                        ),
                        menuItemColor: colorScheme.fillFaint,
                        trailingWidget: _isOwner
                            ? _buildRolePopupMenu(user, colorScheme)
                            : _buildRoleIcon(role, colorScheme),
                        surfaceExecutionStates: false,
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
            allUsers.length,
            maxVisibleHeight,
            colorScheme,
          ),
        ],
      ],
    );
  }

  Widget _buildCustomScrollbar(
    int itemCount,
    double containerHeight,
    colorScheme,
  ) {
    const visibleItems = 4;
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

  Widget _buildRoleIcon(CollectionParticipantRole role, colorScheme) {
    final icon = switch (role) {
      CollectionParticipantRole.owner => HugeIcons.strokeRoundedCrown03,
      CollectionParticipantRole.collaborator =>
        HugeIcons.strokeRoundedUserMultiple,
      CollectionParticipantRole.viewer => HugeIcons.strokeRoundedView,
      _ => HugeIcons.strokeRoundedView,
    };

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(8),
      child: HugeIcon(
        icon: icon,
        color: colorScheme.textMuted,
        size: 20,
      ),
    );
  }

  Widget _buildRolePopupMenu(User user, colorScheme) {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == "viewer") {
          _setUserRole(user, CollectionParticipantRole.viewer);
        } else if (value == "collaborator") {
          _setUserRole(user, CollectionParticipantRole.collaborator);
        } else if (value == "remove") {
          _removeSharee(user);
        }
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
      position: PopupMenuPosition.under,
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedMoreVertical,
        color: colorScheme.textBase,
      ),
      itemBuilder: (context) => [
        // TODO: Re-enable viewer option when ready
        // PopupMenuItem<String>(
        //   value: "viewer",
        //   height: 0,
        //   padding: EdgeInsets.zero,
        //   child: PopupMenuItemWidget(
        //     icon: HugeIcon(
        //       icon: HugeIcons.strokeRoundedView,
        //       color: colorScheme.textBase,
        //       size: 20,
        //     ),
        //     label: context.l10n.viewer,
        //     isFirst: true,
        //     isLast: false,
        //   ),
        // ),
        // TODO: Re-enable collaborator option when ready
        // PopupMenuItem<String>(
        //   value: "collaborator",
        //   height: 0,
        //   padding: EdgeInsets.zero,
        //   child: PopupMenuItemWidget(
        //     icon: HugeIcon(
        //       icon: HugeIcons.strokeRoundedUserMultiple,
        //       color: colorScheme.textBase,
        //       size: 20,
        //     ),
        //     label: context.l10n.collaborator,
        //     isFirst: false,
        //     isLast: false,
        //   ),
        // ),
        PopupMenuItem<String>(
          value: "remove",
          height: 0,
          padding: EdgeInsets.zero,
          child: PopupMenuItemWidget(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedDelete02,
              color: colorScheme.warning500,
              size: 20,
            ),
            label: context.l10n.removeAccess,
            isFirst: true,
            isLast: true,
            isWarning: true,
          ),
        ),
      ],
    );
  }

  Future<void> _setUserRole(User user, CollectionParticipantRole role) async {
    final isDowngrade =
        user.isCollaborator && role == CollectionParticipantRole.viewer;

    if (isDowngrade) {
      final confirmed = await showAlertBottomSheet(
        context,
        title: context.l10n.changePermissions,
        message: context.l10n.cannotAddMoreFilesAfterBecomingViewer(
          user.displayName ?? user.email,
        ),
        buttons: [
          SizedBox(
            child: GradientButton(
              backgroundColor: getEnteColorScheme(context).warning400,
              text: context.l10n.yesConvertToViewer,
              onTap: () {
                Navigator.of(context).pop(true);
              },
            ),
          ),
        ],
        assetPath: "assets/warning-grey.png",
      );

      if (confirmed != true) {
        return;
      }
    }

    final result = await _collectionActions.addEmailToCollection(
      context,
      widget.collection,
      user.email,
      role,
      showProgress: true,
    );

    if (result && mounted) {
      user.role = role.toString();
      setState(() {});
    }
  }

  Future<void> _removeSharee(User user) async {
    final confirmed = await showAlertBottomSheet(
      context,
      title: context.l10n.removeWithQuestionMark,
      message: context.l10n.removeParticipantBody(
        user.displayName ?? user.email,
      ),
      assetPath: "assets/warning-grey.png",
      buttons: [
        SizedBox(
          child: GradientButton(
            backgroundColor: getEnteColorScheme(context).warning400,
            text: context.l10n.yesRemove,
            onTap: () {
              Navigator.of(context).pop(true);
            },
          ),
        ),
      ],
    );

    if (confirmed == true && mounted) {
      final result = await _collectionActions.removeParticipant(
        context,
        widget.collection,
        user,
      );
      if (result && mounted) {
        setState(() {});
      }
    }
  }
}
