import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/sharing/add_participant_page.dart";
import 'package:photos/ui/sharing/manage_album_participant.dart';
import 'package:photos/ui/sharing/public_link_enabled_actions_widget.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class AlbumParticipantsPage extends StatefulWidget {
  final Collection collection;

  const AlbumParticipantsPage(this.collection, {super.key});

  @override
  State<AlbumParticipantsPage> createState() => _AlbumParticipantsPageState();
}

class _AlbumParticipantsPageState extends State<AlbumParticipantsPage> {
  late int currentUserID;
  late Collection _collection;
  final GlobalKey _sendLinkButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    currentUserID = Configuration.instance.getUserID()!;
    _collection = widget.collection;
    _refreshCollection();
  }

  Future<void> _refreshCollection() async {
    try {
      final latest =
          await collectionsService.fetchCollectionByID(widget.collection.id);
      if (mounted) {
        setState(() {
          _collection = latest;
        });
      }
    } catch (_) {}
  }

  Future<void> _navigateToManageUser(User user) async {
    if (user.id == currentUserID) {
      return;
    }
    await routeToPage(
      context,
      ManageIndividualParticipant(collection: _collection, user: user),
    );
    await _refreshCollection();
  }

  Future<void> _navigateToAddUser(List<ActionTypesToShow> actions) async {
    await routeToPage(
      context,
      AddParticipantPage([_collection], actions),
    );
    await _refreshCollection();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserID = Configuration.instance.getUserID()!;
    final role = _collection.getRole(currentUserID);
    final bool adminRoleEnabled = flagService.enableAdminRole;
    final bool surfacePublicLinkEnabled = flagService.surfacePublicLink;
    final bool isOwner = role == CollectionParticipantRole.owner;
    final bool isAdmin = role == CollectionParticipantRole.admin;
    final bool canManageParticipants = isOwner || (adminRoleEnabled && isAdmin);
    final bool hasActivePublicLink = _collection.hasLink &&
        !(_collection.publicURLs.firstOrNull?.isExpired ?? true);
    final bool shouldShowPublicLink =
        !isOwner && hasActivePublicLink && surfacePublicLinkEnabled;
    final colorScheme = getEnteColorScheme(context);
    final int participants = 1 + _collection.getSharees().length;
    final User owner = _collection.owner;
    if (owner.id == currentUserID && owner.email == "") {
      owner.email = Configuration.instance.getEmail()!;
    }
    final List<User> allSharees = _collection.getSharees();
    final List<User> admins = [];
    final List<User> collaborators = [];
    final List<User> viewers = [];
    if (adminRoleEnabled) {
      for (final User sharee in allSharees) {
        if (sharee.isAdmin) {
          admins.add(sharee);
        } else if (sharee.isCollaborator) {
          collaborators.add(sharee);
        } else {
          viewers.add(sharee);
        }
      }
      admins.sort((a, b) => a.email.compareTo(b.email));
      collaborators.sort((a, b) => a.email.compareTo(b.email));
      viewers.sort((a, b) => a.email.compareTo(b.email));
      if (isAdmin && !admins.any((u) => u.id == currentUserID)) {
        admins.insert(
          0,
          User(
            id: currentUserID,
            email: Configuration.instance.getEmail() ?? "",
            role: CollectionParticipantRole.admin.toStringVal(),
          ),
        );
      }
    } else {
      for (final User sharee in allSharees) {
        if (sharee.isCollaborator) {
          collaborators.add(sharee);
        } else {
          viewers.add(sharee);
        }
      }
      collaborators.sort((a, b) => a.email.compareTo(b.email));
      viewers.sort((a, b) => a.email.compareTo(b.email));
    }

    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: _collection.displayName,
            ),
            flexibleSpaceCaption: AppLocalizations.of(
              context,
            ).albumParticipantsCount(count: participants),
          ),
          if (shouldShowPublicLink)
            SliverPadding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MenuSectionTitle(
                      title: AppLocalizations.of(context).publicLinkEnabled,
                      iconData: Icons.public,
                    ),
                    PublicLinkEnabledActionsWidget(
                      collection: _collection,
                      sendLinkButtonKey: _sendLinkButtonKey,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
                  child: Column(
                    children: [
                      Column(
                        children: [
                          MenuSectionTitle(
                            title: AppLocalizations.of(context).albumOwner,
                            iconData: Icons.admin_panel_settings_outlined,
                          ),
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: isOwner
                                  ? AppLocalizations.of(context).you
                                  : _nameIfAvailableElseEmail(
                                      _collection.owner,
                                    ),
                              makeTextBold: isOwner,
                            ),
                            leadingIconWidget: UserAvatarWidget(
                              owner,
                              currentUserID: currentUserID,
                            ),
                            leadingIconSize: 24,
                            menuItemColor: colorScheme.fillFaint,
                            singleBorderRadius: 8,
                            isGestureDetectorDisabled: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              childCount: 1,
            ),
          ),
          if (adminRoleEnabled && (admins.isNotEmpty || canManageParticipants))
            SliverPadding(
              padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == 0 &&
                        (canManageParticipants || admins.isNotEmpty)) {
                      return MenuSectionTitle(
                        title: AppLocalizations.of(context).admins,
                        iconData: Icons.admin_panel_settings_outlined,
                      );
                    } else if (index > 0 && index <= admins.length) {
                      final listIndex = index - 1;
                      final currentUser = admins[listIndex];
                      final isSameAsLoggedInUser =
                          currentUserID == currentUser.id;
                      final isLastItem =
                          !canManageParticipants && index == admins.length;
                      return Column(
                        children: [
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: isSameAsLoggedInUser
                                  ? AppLocalizations.of(context).you
                                  : _nameIfAvailableElseEmail(currentUser),
                              makeTextBold: isSameAsLoggedInUser,
                            ),
                            leadingIconSize: 24.0,
                            leadingIconWidget: UserAvatarWidget(
                              currentUser,
                              type: AvatarType.mini,
                              currentUserID: currentUserID,
                            ),
                            menuItemColor: colorScheme.fillFaint,
                            trailingIcon:
                                canManageParticipants && !isSameAsLoggedInUser
                                    ? Icons.chevron_right
                                    : null,
                            trailingIconIsMuted: true,
                            onTap: canManageParticipants &&
                                    !isSameAsLoggedInUser
                                ? () async {
                                    await _navigateToManageUser(currentUser);
                                  }
                                : null,
                            isTopBorderRadiusRemoved: listIndex > 0,
                            isBottomBorderRadiusRemoved: !isLastItem,
                            singleBorderRadius: 8,
                          ),
                          isLastItem
                              ? const SizedBox.shrink()
                              : DividerWidget(
                                  dividerType: DividerType.menu,
                                  bgColor: colorScheme.fillFaint,
                                ),
                        ],
                      );
                    } else if (index == (1 + admins.length) &&
                        canManageParticipants) {
                      return MenuItemWidget(
                        captionedTextWidget: CaptionedTextWidget(
                          title: admins.isNotEmpty
                              ? AppLocalizations.of(context).addMoreAdmins
                              : AppLocalizations.of(context).addAdmin,
                          makeTextBold: true,
                        ),
                        leadingIcon: Icons.add_outlined,
                        menuItemColor: colorScheme.fillFaint,
                        onTap: () async {
                          await _navigateToAddUser(
                            [ActionTypesToShow.addAdmin],
                          );
                        },
                        isTopBorderRadiusRemoved: admins.isNotEmpty,
                        singleBorderRadius: 8,
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount: 1 + admins.length + 1,
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0 &&
                      (canManageParticipants || collaborators.isNotEmpty)) {
                    return MenuSectionTitle(
                      title: AppLocalizations.of(context).collaborator,
                      iconData: Icons.edit_outlined,
                    );
                  } else if (index > 0 && index <= collaborators.length) {
                    final listIndex = index - 1;
                    final currentUser = collaborators[listIndex];
                    final isSameAsLoggedInUser =
                        currentUserID == currentUser.id;
                    final isLastItem =
                        !canManageParticipants && index == collaborators.length;
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: isSameAsLoggedInUser
                                ? AppLocalizations.of(context).you
                                : _nameIfAvailableElseEmail(currentUser),
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                          ),
                          menuItemColor: colorScheme.fillFaint,
                          trailingIcon: canManageParticipants
                              ? Icons.chevron_right
                              : null,
                          trailingIconIsMuted: true,
                          onTap: canManageParticipants
                              ? () async {
                                  await _navigateToManageUser(currentUser);
                                }
                              : null,
                          isTopBorderRadiusRemoved: listIndex > 0,
                          isBottomBorderRadiusRemoved: !isLastItem,
                          singleBorderRadius: 8,
                        ),
                        isLastItem
                            ? const SizedBox.shrink()
                            : DividerWidget(
                                dividerType: DividerType.menu,
                                bgColor: colorScheme.fillFaint,
                              ),
                      ],
                    );
                  } else if (index == (1 + collaborators.length) &&
                      canManageParticipants) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: collaborators.isNotEmpty
                            ? AppLocalizations.of(context).addMore
                            : AppLocalizations.of(context).addCollaborator,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: colorScheme.fillFaint,
                      onTap: () async {
                        await _navigateToAddUser([
                          ActionTypesToShow.addCollaborator,
                        ]);
                      },
                      isTopBorderRadiusRemoved: collaborators.isNotEmpty,
                      singleBorderRadius: 8,
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: 1 + collaborators.length + 1,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0 &&
                      (canManageParticipants || viewers.isNotEmpty)) {
                    return MenuSectionTitle(
                      title: AppLocalizations.of(context).viewer,
                      iconData: Icons.photo_outlined,
                    );
                  } else if (index > 0 && index <= viewers.length) {
                    final listIndex = index - 1;
                    final currentUser = viewers[listIndex];
                    final isSameAsLoggedInUser =
                        currentUserID == currentUser.id;
                    final isLastItem =
                        !canManageParticipants && index == viewers.length;
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: isSameAsLoggedInUser
                                ? AppLocalizations.of(context).you
                                : _nameIfAvailableElseEmail(currentUser),
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                          ),
                          menuItemColor: colorScheme.fillFaint,
                          trailingIcon: canManageParticipants
                              ? Icons.chevron_right
                              : null,
                          trailingIconIsMuted: true,
                          onTap: canManageParticipants
                              ? () async {
                                  await _navigateToManageUser(currentUser);
                                }
                              : null,
                          isTopBorderRadiusRemoved: listIndex > 0,
                          isBottomBorderRadiusRemoved: !isLastItem,
                          singleBorderRadius: 8,
                        ),
                        isLastItem
                            ? const SizedBox.shrink()
                            : DividerWidget(
                                dividerType: DividerType.menu,
                                bgColor: colorScheme.fillFaint,
                              ),
                      ],
                    );
                  } else if (index == (1 + viewers.length) &&
                      canManageParticipants) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: viewers.isNotEmpty
                            ? AppLocalizations.of(context).addMore
                            : AppLocalizations.of(context).addViewer,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: colorScheme.fillFaint,
                      onTap: () async {
                        await _navigateToAddUser([ActionTypesToShow.addViewer]);
                      },
                      isTopBorderRadiusRemoved: viewers.isNotEmpty,
                      singleBorderRadius: 8,
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: 1 + viewers.length + 1,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 72)),
        ],
      ),
    );
  }

  String _nameIfAvailableElseEmail(User user) {
    final name = user.displayName;
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return user.email;
  }
}
