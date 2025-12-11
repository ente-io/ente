import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/components/popup_menu_item_widget.dart";
import "package:locker/ui/sharing/add_email_bottom_sheet.dart";
import "package:locker/utils/collection_actions.dart";

class ShareCollectionBottomSheet extends StatefulWidget {
  final Collection collection;

  const ShareCollectionBottomSheet({
    super.key,
    required this.collection,
  });

  @override
  State<ShareCollectionBottomSheet> createState() =>
      _ShareCollectionBottomSheetState();
}

class _ShareCollectionBottomSheetState
    extends State<ShareCollectionBottomSheet> {
  late CollectionActions _collectionActions;

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
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

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
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(colorScheme, textTheme),
              const SizedBox(height: 20),
              _buildShareesList(colorScheme, textTheme),
              if (_isOwner) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    text: context.l10n.addEmail,
                    onTap: () async {
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (context) => AddEmailBottomSheet(
                          collection: widget.collection,
                          onShareAdded: () {
                            if (mounted) {
                              setState(() {});
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
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
          context.l10n.sharedWith,
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

  Widget _buildShareesList(colorScheme, textTheme) {
    if (_sharees.isEmpty) {
      return Text(
        context.l10n.noSharedUsers,
        style: textTheme.small.copyWith(color: colorScheme.textMuted),
      );
    }

    final currentUserId = Configuration.instance.getUserID() ?? -1;

    return Column(
      children: List.generate(_sharees.length, (index) {
        final user = _sharees[index];
        final isFirst = index == 0;
        final isLast = index == _sharees.length - 1;

        return Column(
          children: [
            if (!isFirst)
              DividerWidget(
                dividerType: DividerType.menu,
                bgColor: colorScheme.fillFaint,
              ),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
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
              trailingWidget:
                  _isOwner ? _buildRolePopupMenu(user, colorScheme) : null,
              trailingIcon: _isOwner
                  ? null
                  : (user.isViewer
                      ? Icons.visibility_outlined
                      : Icons.people_outline),
              trailingIconIsMuted: true,
              surfaceExecutionStates: false,
              isTopBorderRadiusRemoved: !isFirst,
              isBottomBorderRadiusRemoved: !isLast,
              singleBorderRadius: 8,
            ),
          ],
        );
      }),
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
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      color: Colors.transparent,
      child: HugeIcon(
        icon: user.isViewer
            ? HugeIcons.strokeRoundedView
            : HugeIcons.strokeRoundedUserGroup,
        color: colorScheme.textMuted,
        size: 20,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          value: "viewer",
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
            isLast: false,
          ),
        ),
        PopupMenuItem<String>(
          value: "collaborator",
          height: 0,
          padding: EdgeInsets.zero,
          child: PopupMenuItemWidget(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedUserGroup,
              color: colorScheme.textBase,
              size: 20,
            ),
            label: context.l10n.collaborator,
            isFirst: false,
            isLast: false,
          ),
        ),
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
            isFirst: false,
            isLast: true,
            isWarning: true,
          ),
        ),
      ],
    );
  }

  Future<void> _setUserRole(User user, CollectionParticipantRole role) async {
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
