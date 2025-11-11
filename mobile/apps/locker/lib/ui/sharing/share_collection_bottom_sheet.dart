import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/toggle_switch_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/theme/text_style.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/share_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:hugeicons/hugeicons.dart";
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_api_client.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/collections/models/public_url.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/components/gradient_button.dart";
import "package:locker/ui/sharing/advanced_sharing_bottom_sheet.dart";
import "package:locker/ui/sharing/album_share_info_widget.dart";
import "package:locker/utils/collection_actions.dart";

/// A bottom sheet widget for sharing a collection with others.
///
/// This widget provides a clean, modern interface for:
/// - Viewing and managing sharees (users with access)
/// - Adding new sharees via email
/// - Creating and managing public links
/// - Configuring advanced sharing options
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
  bool _isShareesExpanded = false;
  final ScrollController _scrollController = ScrollController();
  late CollectionActions _collectionActions;

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

  List<User> get _sharees => widget.collection.getSharees();

  int get _shareeCount => _sharees.length;

  bool get _isOwner =>
      widget.collection.owner.id == Configuration.instance.getUserID();

  PublicURL? get _publicUrl => widget.collection.publicURLs.isNotEmpty
      ? widget.collection.publicURLs.first
      : null;

  bool get _hasPublicLink => _publicUrl != null;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backdropBase,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  _buildHeader(colorScheme, textTheme),
                  if (_shareeCount > 0) ...[
                    const SizedBox(height: 20),
                    _buildShareesCard(colorScheme, textTheme),
                  ],
                  const SizedBox(height: 12),
                  if (_hasPublicLink) ...[
                    if (_isOwner) _buildAddEmailButton(),
                    if (_isOwner) const SizedBox(height: 24),
                    _buildPublicLinkSection(colorScheme, textTheme),
                    const SizedBox(height: 12),
                    _buildShareLinkButton(),

                    // Hide Advance Options
                    // const SizedBox(height: 24),
                    // _buildAdvancedOptionsRow(colorScheme, textTheme),
                    // const SizedBox(height: 24),
                  ] else ...[
                    _buildCompactActionsCard(colorScheme, textTheme),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final shareText = context.l10n.shareWithPeopleSectionTitle(_shareeCount);

    return Row(
      children: [
        Icon(
          Icons.group_outlined,
          size: 20,
          color: colorScheme.textMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            shareText,
            style: textTheme.body.copyWith(
              color: colorScheme.textMuted,
              fontSize: 16,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colorScheme.backdropBase,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.close,
              color: colorScheme.textBase,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareesCard(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                _isShareesExpanded = !_isShareesExpanded;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildShareeAvatarsPreview(
                      colorScheme,
                      textTheme,
                    ),
                  ),
                  Icon(
                    _isShareesExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.textBase,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isShareesExpanded) ...[
            ...List.generate(_sharees.length, (index) {
              final user = _sharees[index];
              return _buildShareeItem(
                user,
                colorScheme,
                textTheme,
                isLast: index == _sharees.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildShareeAvatarsPreview(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return SizedBox(
      height: 44,
      child: AlbumSharesIcons(
        sharees: _sharees,
        type: AvatarType.mini,
        limitCountTo: 5,
        removeBorder: false,
        padding: EdgeInsets.zero,
        stackAlignment: Alignment.centerLeft,
      ),
    );
  }

  Widget _buildShareeItem(
    User user,
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme, {
    bool isLast = false,
  }) {
    final currentUserId = Configuration.instance.getUserID();
    final isCurrentUser = user.id == currentUserId;
    final isOwnerUser = user.id == widget.collection.owner.id;

    Widget trailingIcon;
    if (isOwnerUser) {
      trailingIcon = Icon(
        Icons.admin_panel_settings_outlined,
        size: 20,
        color: colorScheme.textMuted,
      );
    } else if (_isOwner && !isCurrentUser) {
      trailingIcon = PopupMenuButton<String>(
        icon: Icon(
          user.isViewer ? Icons.visibility_outlined : Icons.people_outline,
          size: 20,
          color: colorScheme.textMuted,
        ),
        color: colorScheme.backgroundElevated2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        onSelected: (value) {
          if (value == "toggle_role") {
            _toggleUserRole(user);
          } else if (value == "remove") {
            _removeSharee(user);
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem<String>(
            value: "toggle_role",
            child: Row(
              children: [
                Icon(
                  user.isViewer
                      ? Icons.people_outline
                      : Icons.visibility_outlined,
                  color: colorScheme.textBase,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  user.isViewer ? "Set as collaborator" : "Set as viewer",
                  style: textTheme.body,
                ),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: "remove",
            child: Row(
              children: [
                Icon(
                  Icons.delete_outline,
                  color: colorScheme.warning500,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  "Remove from shared",
                  style: textTheme.body.copyWith(
                    color: colorScheme.warning500,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      trailingIcon = Icon(
        user.isViewer ? Icons.visibility_outlined : Icons.people_outline,
        size: 20,
        color: colorScheme.textMuted,
      );
    }

    return Container(
      width: double.infinity,
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.strokeFaint,
                  width: 0.5,
                ),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            UserAvatarWidget(
              user,
              currentUserID: currentUserId!,
              config: Configuration.instance,
              type: AvatarType.mini,
            ),
            const SizedBox(width: 12),
            Text(
              _displayName(user),
              style: textTheme.body.copyWith(
                color: colorScheme.textBase,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            trailingIcon,
          ],
        ),
      ),
    );
  }

  Widget _buildCompactActionsCard(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final bool canManage = _isOwner;
    final l10n = context.l10n;
    final shareLabel = _hasPublicLink ? l10n.sendLink : l10n.shareALink;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCompactActionRow(
            colorScheme,
            textTheme,
            title: l10n.addANewEmail,
            icon: Icons.open_in_new_rounded,
            enabled: canManage,
            textColor: canManage ? colorScheme.textBase : colorScheme.textMuted,
            iconColor: canManage ? colorScheme.textBase : colorScheme.textMuted,
            onTap: canManage
                ? () async {
                    await _showAddEmailDialog();
                  }
                : null,
          ),
          Divider(
            height: 1,
            color: colorScheme.strokeFaint,
          ),
          _buildCompactActionRow(
            colorScheme,
            textTheme,
            title: shareLabel,
            icon: Icons.link,
            enabled: canManage || _hasPublicLink,
            textColor: (canManage || _hasPublicLink)
                ? colorScheme.primary700
                : colorScheme.textMuted,
            iconColor: (canManage || _hasPublicLink)
                ? colorScheme.primary700
                : colorScheme.textMuted,
            onTap: (canManage || _hasPublicLink)
                ? () async {
                    await _handleShareLinkTap();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionRow(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme, {
    required String title,
    required IconData icon,
    required bool enabled,
    Color? textColor,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final Color effectiveTextColor =
        textColor ?? (enabled ? colorScheme.textBase : colorScheme.textMuted);
    final Color effectiveIconColor =
        iconColor ?? (enabled ? colorScheme.textBase : colorScheme.textMuted);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: textTheme.body.copyWith(
                  color: effectiveTextColor,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(
              icon,
              size: 20,
              color: effectiveIconColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddEmailButton() {
    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        hugeIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedFileUpload,
          color: Colors.white,
        ),
        onTap: () async {
          await _showAddEmailDialog();
        },
        text: "Add Email",
      ),
    );
  }

  Future<void> _handleShareLinkTap() async {
    if (_hasPublicLink && _publicUrl != null) {
      await _sharePublicLink(_publicUrl!.url);
      return;
    }

    if (!_isOwner) {
      return;
    }

    final created = await _createPublicLink();
    if (created && mounted && _publicUrl != null) {
      await _sharePublicLink(_publicUrl!.url);
    }
  }

  Widget _buildPublicLinkSection(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    final publicUrl = _publicUrl;

    final isCollectEnabled =
        widget.collection.publicURLs.firstOrNull?.enableCollect ?? false;

    if (publicUrl == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Public Link",
          style: textTheme.largeBold,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.fillFaint,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  publicUrl.url,
                  style: textTheme.bodyMuted,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _copyPublicLink(publicUrl.url),
                icon: Icon(
                  Icons.copy,
                  color: colorScheme.textBase,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _buildToggleRow(
          label: "Allow uploads",
          value: isCollectEnabled,
          onChanged: _isOwner
              ? () async {
                  await _updatePublicUrlSettings(
                    {'enableCollect': !isCollectEnabled},
                    showProgressDialog: true,
                  );
                }
              : null,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    );
  }

  Widget _buildShareLinkButton() {
    final publicUrl = _publicUrl;
    if (publicUrl == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: GradientButton(
        hugeIcon: const HugeIcon(
          icon: HugeIcons.strokeRoundedFileUpload,
          color: Colors.white,
        ),
        onTap: () async {
          await _sharePublicLink(publicUrl.url);
        },
        text: context.l10n.sendLink,
      ),
    );
  }

  Widget _buildAdvancedOptionsRow(
    EnteColorScheme colorScheme,
    EnteTextTheme textTheme,
  ) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: colorScheme.backgroundBase,
          builder: (context) => AdvancedSharingBottomSheet(
            collection: widget.collection,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 20,
        ),
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated2,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Advanced options",
              style: textTheme.body,
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.textBase,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String label,
    required bool value,
    required EnteColorScheme colorScheme,
    required EnteTextTheme textTheme,
    Future<void> Function()? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textTheme.body.copyWith(
              color: colorScheme.textBase,
              fontSize: 16,
            ),
          ),
          ToggleSwitchWidget(
            value: () => value,
            onChanged: onChanged ?? () async {},
          ),
        ],
      ),
    );
  }

  String _displayName(User user) {
    final name = user.displayName;
    if (name != null && name.trim().isNotEmpty) {
      return name;
    }
    return user.email;
  }

  Future<void> _showAddEmailDialog() async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final emailController = TextEditingController();
    bool allowCollaboration = false;
    bool isSubmitting = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: colorScheme.backgroundElevated2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            width: 400,
            decoration: BoxDecoration(
              color: colorScheme.backgroundElevated2,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.l10n.addANewEmail,
                      style: textTheme.largeBold,
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(dialogContext).pop(false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.backgroundElevated,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.close,
                          color: colorScheme.textBase,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  autofocus: true,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: context.l10n.enterEmail,
                    hintStyle: textTheme.body.copyWith(
                      color: colorScheme.textMuted,
                    ),
                    filled: true,
                    fillColor: colorScheme.fillFaint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: colorScheme.strokeFaint,
                      ),
                    ),
                  ),
                  style: textTheme.body.copyWith(
                    color: colorScheme.textBase,
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    setDialogState(() {
                      allowCollaboration = !allowCollaboration;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.fillFaint,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: allowCollaboration
                                ? colorScheme.primary700
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: allowCollaboration
                                  ? colorScheme.primary700
                                  : colorScheme.strokeBase,
                              width: 2,
                            ),
                          ),
                          child: allowCollaboration
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Allow collaboration",
                            style: textTheme.body.copyWith(
                              color: colorScheme.textBase,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 36),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    onTap: isSubmitting
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isNotEmpty) {
                              setDialogState(() {
                                isSubmitting = true;
                              });
                              Navigator.pop(dialogContext, true);
                              await _addSharee(email, allowCollaboration);
                            }
                          },
                    text: context.l10n.create,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _addSharee(String email, bool isCollaborator) async {
    final role = isCollaborator
        ? CollectionParticipantRole.collaborator
        : CollectionParticipantRole.viewer;

    final result = await _collectionActions.addEmailToCollection(
      context,
      widget.collection,
      email,
      role,
      showProgress: true,
    );

    if (result && mounted) {
      setState(() {});
    }
  }

  Future<void> _toggleUserRole(User user) async {
    final newRole = user.isViewer
        ? CollectionParticipantRole.collaborator
        : CollectionParticipantRole.viewer;

    final result = await _collectionActions.addEmailToCollection(
      context,
      widget.collection,
      user.email,
      newRole,
      showProgress: true,
    );

    if (result && mounted) {
      user.role = newRole.toString();
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

  Future<bool> _createPublicLink() async {
    final success = await CollectionActions.enableUrl(
      context,
      widget.collection,
    );
    if (success && mounted) {
      setState(() {});
    }
    return success;
  }

  Future<void> _copyPublicLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      showShortToast(context, "Link copied to clipboard");
    }
  }

  Future<void> _sharePublicLink(String url) async {
    await shareText(url, context: context);
  }

  Future<void> _updatePublicUrlSettings(
    Map<String, dynamic> updates, {
    bool showProgressDialog = true,
  }) async {
    final dialog = showProgressDialog
        ? createProgressDialog(context, "Please wait...")
        : null;
    await dialog?.show();
    try {
      await CollectionApiClient.instance.updateShareUrl(
        widget.collection,
        updates,
      );
      await dialog?.hide();
      showShortToast(context, "Collection updated");
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        await dialog?.hide();
        await showGenericErrorDialog(context: context, error: e);
        rethrow;
      }
    }
  }
}
