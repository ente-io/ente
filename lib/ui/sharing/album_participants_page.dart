import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import 'package:photos/ui/sharing/add_partipant_page.dart';
import 'package:photos/ui/sharing/manage_album_participant.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class AlbumParticipantsPage extends StatefulWidget {
  final Collection collection;

  const AlbumParticipantsPage(
    this.collection, {
    super.key,
  });

  @override
  State<AlbumParticipantsPage> createState() => _AlbumParticipantsPageState();
}

class _AlbumParticipantsPageState extends State<AlbumParticipantsPage> {
  late int currentUserID;

  @override
  void initState() {
    currentUserID = Configuration.instance.getUserID()!;
    super.initState();
  }

  Future<void> _navigateToManageUser(User user) async {
    if (user.id == currentUserID) {
      return;
    }
    await routeToPage(
      context,
      ManageIndividualParticipant(collection: widget.collection, user: user),
    );
    if (mounted) {
      setState(() => {});
    }
  }

  Future<void> _navigateToAddUser(bool addingViewer) async {
    await routeToPage(
      context,
      AddParticipantPage(widget.collection, addingViewer),
    );
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        widget.collection.owner?.id == Configuration.instance.getUserID();
    final colorScheme = getEnteColorScheme(context);
    final currentUserID = Configuration.instance.getUserID()!;
    final int participants = 1 + widget.collection.getSharees().length;
    final User owner = widget.collection.owner!;
    if (owner.id == currentUserID && owner.email == "") {
      owner.email = Configuration.instance.getEmail()!;
    }
    final splitResult =
        widget.collection.getSharees().splitMatch((x) => x.isViewer);
    final List<User> viewers = splitResult.matched;
    viewers.sort((a, b) => a.email.compareTo(b.email));
    final List<User> collaborators = splitResult.unmatched;
    collaborators.sort((a, b) => a.email.compareTo(b.email));

    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: "${widget.collection.name}",
            ),
            flexibleSpaceCaption: "$participants Participants",
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
                          const MenuSectionTitle(
                            title: "Owner",
                            iconData: Icons.admin_panel_settings_outlined,
                          ),
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: isOwner
                                  ? "You"
                                  : widget.collection.owner?.email ?? '',
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
          SliverPadding(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0 && (isOwner || collaborators.isNotEmpty)) {
                    return const MenuSectionTitle(
                      title: "Collaborator",
                      iconData: Icons.edit_outlined,
                    );
                  } else if (index > 0 && index <= collaborators.length) {
                    final listIndex = index - 1;
                    final currentUser = collaborators[listIndex];
                    final isSameAsLoggedInUser =
                        currentUserID == currentUser.id;
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: isSameAsLoggedInUser
                                ? "You"
                                : currentUser.email,
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: isOwner ? Icons.chevron_right : null,
                          trailingIconIsMuted: true,
                          onTap: isOwner
                              ? () async {
                                  if (isOwner) {
                                    _navigateToManageUser(currentUser);
                                  }
                                }
                              : null,
                          isTopBorderRadiusRemoved: listIndex > 0,
                          isBottomBorderRadiusRemoved: true,
                          singleBorderRadius: 8,
                        ),
                        DividerWidget(
                          dividerType: DividerType.menu,
                          bgColor: getEnteColorScheme(context).blurStrokeFaint,
                        ),
                      ],
                    );
                  } else if (index == (1 + collaborators.length) && isOwner) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: collaborators.isNotEmpty
                            ? "Add more"
                            : "Add collaborator",
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        _navigateToAddUser(false);
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
                  if (index == 0 && (isOwner || viewers.isNotEmpty)) {
                    return const MenuSectionTitle(
                      title: "Viewer",
                      iconData: Icons.photo_outlined,
                    );
                  } else if (index > 0 && index <= viewers.length) {
                    final listIndex = index - 1;
                    final currentUser = viewers[listIndex];
                    final isSameAsLoggedInUser =
                        currentUserID == currentUser.id;
                    final isLastItem = !isOwner && index == viewers.length;
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: isSameAsLoggedInUser
                                ? "You"
                                : currentUser.email,
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: isOwner ? Icons.chevron_right : null,
                          trailingIconIsMuted: true,
                          onTap: isOwner
                              ? () async {
                                  if (isOwner) {
                                    await _navigateToManageUser(currentUser);
                                  }
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
                                bgColor: getEnteColorScheme(context).fillFaint,
                              ),
                      ],
                    );
                  } else if (index == (1 + viewers.length) && isOwner) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: viewers.isNotEmpty ? "Add more" : "Add viewer",
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        _navigateToAddUser(true);
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
        ],
      ),
    );
  }
}
