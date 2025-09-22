import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/components/title_bar_widget.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_utils/ente_utils.dart";
import 'package:flutter/material.dart';
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart";
import "package:locker/ui/sharing/add_participant_page.dart";
import "package:locker/ui/sharing/manage_album_participant.dart";

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
      AddParticipantPage(
        [widget.collection],
        addingViewer
            ? [ActionTypesToShow.addViewer]
            : [ActionTypesToShow.addCollaborator],
      ),
    );
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOwner =
        widget.collection.owner.id == Configuration.instance.getUserID();
    final colorScheme = getEnteColorScheme(context);
    final currentUserID = Configuration.instance.getUserID()!;
    final int participants = 1 + widget.collection.getSharees().length;
    final User owner = widget.collection.owner;
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
              title: widget.collection.name,
            ),
            flexibleSpaceCaption:
                context.l10n.albumParticipantsCount(participants),
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
                            title: context.l10n.albumOwner,
                            iconData: Icons.admin_panel_settings_outlined,
                          ),
                          MenuItemWidget(
                            captionedTextWidget: CaptionedTextWidget(
                              title: isOwner
                                  ? context.l10n.you
                                  : _nameIfAvailableElseEmail(
                                      widget.collection.owner,
                                    ),
                              makeTextBold: isOwner,
                            ),
                            leadingIconWidget: UserAvatarWidget(
                              owner,
                              currentUserID: currentUserID,
                              config: Configuration.instance,
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
                    return MenuSectionTitle(
                      title: context.l10n.collaborator,
                      iconData: Icons.edit_outlined,
                    );
                  } else if (index > 0 && index <= collaborators.length) {
                    final listIndex = index - 1;
                    final currentUser = collaborators[listIndex];
                    final isSameAsLoggedInUser =
                        currentUserID == currentUser.id;
                    final isLastItem =
                        !isOwner && index == collaborators.length;
                    return Column(
                      children: [
                        MenuItemWidget(
                          captionedTextWidget: CaptionedTextWidget(
                            title: isSameAsLoggedInUser
                                ? context.l10n.you
                                : _nameIfAvailableElseEmail(currentUser),
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                            config: Configuration.instance,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: isOwner ? Icons.chevron_right : null,
                          trailingIconIsMuted: true,
                          onTap: isOwner
                              ? () async {
                                  if (isOwner) {
                                    // ignore: unawaited_futures
                                    _navigateToManageUser(currentUser);
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
                  } else if (index == (1 + collaborators.length) && isOwner) {
                    return MenuItemWidget(
                      captionedTextWidget: CaptionedTextWidget(
                        title: collaborators.isNotEmpty
                            ? context.l10n.addMore
                            : context.l10n.addCollaborator,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        // ignore: unawaited_futures
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
                    return MenuSectionTitle(
                      title: context.l10n.viewer,
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
                                ? context.l10n.you
                                : _nameIfAvailableElseEmail(currentUser),
                            makeTextBold: isSameAsLoggedInUser,
                          ),
                          leadingIconSize: 24.0,
                          leadingIconWidget: UserAvatarWidget(
                            currentUser,
                            type: AvatarType.mini,
                            currentUserID: currentUserID,
                            config: Configuration.instance,
                          ),
                          menuItemColor: getEnteColorScheme(context).fillFaint,
                          trailingIcon: isOwner ? Icons.chevron_right : null,
                          trailingIconIsMuted: true,
                          onTap: isOwner
                              ? () async {
                                  if (isOwner) {
                                    // ignore: unawaited_futures
                                    _navigateToManageUser(currentUser);
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
                        title: viewers.isNotEmpty
                            ? context.l10n.addMore
                            : context.l10n.addViewer,
                        makeTextBold: true,
                      ),
                      leadingIcon: Icons.add_outlined,
                      menuItemColor: getEnteColorScheme(context).fillFaint,
                      onTap: () async {
                        // ignore: unawaited_futures
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
