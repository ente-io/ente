import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/extensions/list.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:photos/ui/components/title_bar_widget.dart';
import "package:photos/ui/sharing/add_participant_page.dart";
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
              title: widget.collection.displayName,
            ),
            flexibleSpaceCaption: AppLocalizations.of(context)
                .albumParticipantsCount(count: participants),
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
                                      widget.collection.owner,
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
          SliverPadding(
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index == 0 && (isOwner || collaborators.isNotEmpty)) {
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
                        !isOwner && index == collaborators.length;
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
                            ? AppLocalizations.of(context).addMore
                            : AppLocalizations.of(context).addCollaborator,
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
                      title: AppLocalizations.of(context).viewer,
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
                            ? AppLocalizations.of(context).addMore
                            : AppLocalizations.of(context).addViewer,
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
