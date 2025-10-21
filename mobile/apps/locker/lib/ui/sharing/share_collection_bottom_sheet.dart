import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
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
  bool _isExpanded = false;
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: "Shared with X people" and close button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 20,
                      color: colorScheme.textMuted,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _shareeCount == 0
                            ? "Shared with 0 people"
                            : "Shared with $_shareeCount ${_shareeCount == 1 ? 'person' : 'people'}",
                        style: textTheme.body.copyWith(
                          color: colorScheme.textMuted,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.textBase,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sharees section (if any)
              if (_shareeCount > 0) ...[
                _buildShareesSection(colorScheme, textTheme),
                const SizedBox(height: 16),
              ],

              _buildAddEmailButton(colorScheme, textTheme),

              const SizedBox(height: 12),

              // Share as link button (skipped for now)
              _buildShareAsLinkButton(colorScheme, textTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareesSection(
    colorScheme,
    textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Avatar circles + expand/collapse button
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.backgroundElevated2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  // Avatar circles (show first 5)
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: Stack(
                        children: [
                          for (int i = 0;
                              i < (_shareeCount > 5 ? 5 : _shareeCount);
                              i++)
                            Positioned(
                              left: i * 24.0,
                              child: UserAvatarWidget(
                                _sharees[i],
                                currentUserID:
                                    Configuration.instance.getUserID()!,
                                config: Configuration.instance,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: colorScheme.textBase,
                  ),
                ],
              ),
            ),
          ),

          // Expanded sharees list
          if (_isExpanded) ...[
            const SizedBox(height: 8),
            _buildExpandedShareesList(colorScheme, textTheme),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandedShareesList(
    colorScheme,
    textTheme,
  ) {
    final currentUserID = Configuration.instance.getUserID()!;
    final isOwner = widget.collection.owner.id == currentUserID;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListView.separated(
        controller: _scrollController,
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _sharees.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colorScheme.strokeFaint,
          indent: 56,
        ),
        itemBuilder: (context, index) {
          final user = _sharees[index];
          return _buildShareeItem(user, colorScheme, textTheme, isOwner);
        },
      ),
    );
  }

  Widget _buildShareeItem(
    User user,
    colorScheme,
    textTheme,
    bool isOwner,
  ) {
    return ListTile(
      leading: UserAvatarWidget(
        user,
        currentUserID: Configuration.instance.getUserID()!,
        config: Configuration.instance,
      ),
      title: Text(
        user.email,
        style: textTheme.body,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Role icon
          Icon(
            user.isViewer ? Icons.visibility_outlined : Icons.people_outline,
            size: 20,
            color: colorScheme.textMuted,
          ),
          if (isOwner) ...[
            const SizedBox(width: 8),
            // More options button
            IconButton(
              icon: Icon(
                Icons.more_vert,
                size: 20,
                color: colorScheme.textBase,
              ),
              onPressed: () => _showShareeOptions(user),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  void _showShareeOptions(User user) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: colorScheme.backgroundElevated,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toggle role option
              ListTile(
                leading: Icon(
                  user.isViewer
                      ? Icons.people_outline
                      : Icons.visibility_outlined,
                  color: colorScheme.textBase,
                ),
                title: Text(
                  user.isViewer ? "Make Collaborator" : "Make Viewer",
                  style: textTheme.body,
                ),
                onTap: () {
                  Navigator.pop(context);
                  _toggleUserRole(user);
                },
              ),
              Divider(height: 1, color: colorScheme.strokeFaint),
              // Remove option
              ListTile(
                leading: Icon(
                  Icons.person_remove_outlined,
                  color: colorScheme.warning500,
                ),
                title: Text(
                  "Remove",
                  style: textTheme.body.copyWith(
                    color: colorScheme.warning500,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _removeSharee(user);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
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
      Navigator.pop(context);
    }
  }

  Future<void> _removeSharee(User user) async {
    final result = await _collectionActions.removeParticipant(
      context,
      widget.collection,
      user,
    );

    if (result && mounted) {
      Navigator.pop(context);
    }
  }

  Widget _buildAddEmailButton(
    colorScheme,
    textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: _showAddEmailDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                "Add Email",
                style: textTheme.body,
              ),
              const Spacer(),
              Icon(
                Icons.open_in_new,
                size: 20,
                color: colorScheme.textBase,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareAsLinkButton(
    colorScheme,
    textTheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: InkWell(
        onTap: () {
          // TODO: Implement share as link functionality
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated2,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(
                "Share as link",
                style: textTheme.body.copyWith(
                  color: colorScheme.primary500,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.link,
                size: 20,
                color: colorScheme.primary500,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEmailDialog() {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final emailController = TextEditingController();
    bool allowCollaboration = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: colorScheme.backgroundElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Add new email",
                        style: textTheme.h3,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: colorScheme.textBase,
                      ),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: emailController,
                  decoration: InputDecoration(
                    hintText: "Enter an email address",
                    hintStyle: textTheme.body.copyWith(
                      color: colorScheme.textMuted,
                    ),
                    filled: true,
                    fillColor: colorScheme.fillFaint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: allowCollaboration,
                      onChanged: (value) {
                        setDialogState(() {
                          allowCollaboration = value ?? false;
                        });
                      },
                      activeColor: colorScheme.primary500,
                    ),
                    Text(
                      "Allow collaboration",
                      style: textTheme.body,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final email = emailController.text.trim();
                      if (email.isNotEmpty) {
                        Navigator.pop(context);
                        _addSharee(email, allowCollaboration);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary500,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      "Create",
                      style: textTheme.body.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
      Navigator.pop(context);
    }
  }
}
