import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/extensions/list.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
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
    final result = await routeToPage(
      context,
      ManageIndividualParticipant(collection: widget.collection, user: user),
    );
    if (result != null && mounted) {
      setState(() => {});
    }
  }

  Future<void> _navigateToAddUser(bool addingViewer) async {
    final result = await routeToPage(
      context,
      AddParticipantPage(widget.collection),
    );
    if (result != null && mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final currentUserID = Configuration.instance.getUserID()!;
    final int particpants = 1 + widget.collection.getSharees().length;
    final User owner = widget.collection.owner!;
    if (owner.id == currentUserID && owner.email == "") {
      owner.email = Configuration.instance.getEmail()!;
    }
    final splitResult =
        widget.collection.getSharees().splitMatch((x) => x.isViewer);
    final List<User> viewers = splitResult.matched;
    final List<User> collaborators = splitResult.unmatched;

    return Scaffold(
      body: CustomScrollView(
        primary: false,
        slivers: <Widget>[
          TitleBarWidget(
            flexibleSpaceTitle: TitleBarTitleWidget(
              title: "${widget.collection.name}",
            ),
            flexibleSpaceCaption: "$particpants Participants",
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
                            captionedTextWidget: const CaptionedTextWidget(
                              title: "You",
                              makeTextBold: true,
                            ),
                            leadingIconWidget: UserAvatarWidget(
                              owner,
                              currentUserID: currentUserID,
                            ),
                            leadingIconSize: 24,
                            menuItemColor: colorScheme.fillFaint,
                            borderRadius: 8,
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
                  if (index == 0) {
                    return const MenuSectionTitle(
                      title: "Collaborator",
                      iconData: Icons.edit_outlined,
                    );
                  } else if (index > 0 && index <= collaborators.length) {
                    final listIndex = index - 1;
                    final currentUser = collaborators[listIndex];
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: currentUser.email,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          pressedColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: Icons.chevron_right,
                          trailingIconIsMuted: true,
                          onTap: () async {
                            await _navigateToManageUser(currentUser);
                          },
                          isTopBorderRadiusRemoved: listIndex > 0,
                          isBottomBorderRadiusRemoved: true,
                          borderRadius: 8,
                        ),
                        DividerWidget(
                          dividerType: DividerType.menu,
                          bgColor: getEnteColorScheme(context).blurStrokeFaint,
                        ),
                      ],
                    );
                  } else if (index == (1 + collaborators.length)) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title:
                            collaborators.isNotEmpty ? "Add more" : "Add email",
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      pressedColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        await _navigateToAddUser(false);
                      },
                      isTopBorderRadiusRemoved: collaborators.isNotEmpty,
                      borderRadius: 8,
                    );
                  }
                  return const Text("-----");
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
                  if (index == 0) {
                    return const MenuSectionTitle(
                      title: "Viewer",
                      iconData: Icons.photo_outlined,
                    );
                  } else if (index > 0 && index <= viewers.length) {
                    final listIndex = index - 1;
                    final currentUser = viewers[listIndex];
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: currentUser.email,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          pressedColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: Icons.chevron_right,
                          trailingIconIsMuted: true,
                          onTap: () async {
                            await _navigateToManageUser(currentUser);
                          },
                          isTopBorderRadiusRemoved: listIndex > 0,
                          isBottomBorderRadiusRemoved: true,
                          borderRadius: 8,
                        ),
                        DividerWidget(
                          dividerType: DividerType.menu,
                          bgColor: getEnteColorScheme(context).blurStrokeFaint,
                        ),
                      ],
                    );
                  } else if (index == (1 + viewers.length)) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: viewers.isNotEmpty ? "Add more" : "Add Viewer",
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      pressedColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        await _navigateToAddUser(true);
                      },
                      isTopBorderRadiusRemoved: viewers.isNotEmpty,
                      borderRadius: 8,
                    );
                  }
                  return const Text("-----");
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
