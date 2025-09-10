import "package:ente_sharing/models/user.dart";
import "package:ente_sharing/user_avator_widget.dart";
import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/components/menu_section_description_widget.dart";
import "package:ente_ui/components/menu_section_title.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/ente_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/extensions/user_extension.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/services/configuration.dart"; 
import "package:locker/ui/sharing/add_participant_page.dart";
import "package:locker/ui/sharing/album_participants_page.dart";
import "package:locker/ui/sharing/album_share_info_widget.dart";
import "package:locker/ui/sharing/manage_album_participant.dart";
import "package:locker/ui/sharing/manage_links_widget.dart";
import "package:locker/utils/collection_actions.dart";

class ShareCollectionPage extends StatefulWidget {
  final Collection collection;
  const ShareCollectionPage({super.key, required this.collection});

  @override
  State<ShareCollectionPage> createState() => _ShareCollectionPageState();
}

class _ShareCollectionPageState extends State<ShareCollectionPage> {
  late List<User?> _sharees;

  Future<void> _navigateToManageUser() async {
    if (_sharees.length == 1) {
      await routeToPage(
        context,
        ManageIndividualParticipant(
          collection: widget.collection,
          user: _sharees.first!,
        ),
      );
    } else {
      await routeToPage(
        context,
        AlbumParticipantsPage(widget.collection),
      );
    }
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasUrl = widget.collection.hasLink;
    final bool hasExpired =
        widget.collection.publicURLs.firstOrNull?.isExpired ?? false;
    _sharees = widget.collection.sharees;

    final children = <Widget>[];

    children.add(
      MenuSectionTitle(
        title: context.l10n.shareWithPeopleSectionTitle(_sharees.length),
        iconData: Icons.workspaces,
      ),
    );

    children.add(
      EmailItemWidget(
        widget.collection,
        onTap: _navigateToManageUser,
      ),
    );

    children.add(
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: context.l10n.addViewer,
          makeTextBold: true,
        ),
        leadingIcon: Icons.add,
        menuItemColor: getEnteColorScheme(context).fillFaint,
        isTopBorderRadiusRemoved: _sharees.isNotEmpty,
        isBottomBorderRadiusRemoved: true,
        onTap: () async {
          // ignore: unawaited_futures
          routeToPage(
          context,
          AddParticipantPage(
            [widget.collection],
            const [ActionTypesToShow.addViewer],
          ),
          ).then(
            (value) => {
              if (mounted) {setState(() => {})},
            },
          );
        },
      ),
    );
    children.add(
      DividerWidget(
        dividerType: DividerType.menu,
        bgColor: getEnteColorScheme(context).fillFaint,
      ),
    );

    children.add(
      MenuItemWidget(
        captionedTextWidget: CaptionedTextWidget(
          title: context.l10n.addCollaborator,
          makeTextBold: true,
        ),
        leadingIcon: Icons.add,
        menuItemColor: getEnteColorScheme(context).fillFaint,
        isTopBorderRadiusRemoved: true,
        onTap: () async {
          // ignore: unawaited_futures
          routeToPage(
            context,
            AddParticipantPage(
              [widget.collection],
              const [ActionTypesToShow.addCollaborator],
            ),
          ).then(
            (value) => {
              if (mounted) {setState(() => {})},
            },
          );
        },
      ),
    );

    if (_sharees.isEmpty && !hasUrl) {
      children.add(
        MenuSectionDescriptionWidget(
          content: context.l10n.sharedCollectionSectionDescription,
        ),
      );
    }

    children.addAll([
      const SizedBox(
        height: 24,
      ),
      MenuSectionTitle(
        title:
            hasUrl ? context.l10n.publicLinkEnabled : context.l10n.shareALink,
        iconData: Icons.public,
      ),
    ]);
    if (hasUrl) {
      if (hasExpired) {
        children.add(
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.linkHasExpired,
              textColor: getEnteColorScheme(context).warning500,
            ),
            leadingIcon: Icons.error_outline,
            leadingIconColor: getEnteColorScheme(context).warning500,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            isBottomBorderRadiusRemoved: true,
          ),
        );
      } else {
        final String url =
            CollectionService.instance.getPublicUrl(widget.collection);
        children.addAll(
          [
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: context.l10n.copyLink,
                makeTextBold: true,
              ),
              leadingIcon: Icons.copy,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              showOnlyLoadingState: true,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                showShortToast(context, "Link copied to clipboard");
              },
              isBottomBorderRadiusRemoved: true,
            ),
            DividerWidget(
              dividerType: DividerType.menu,
              bgColor: getEnteColorScheme(context).fillFaint,
            ),
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: context.l10n.sendLink,
                makeTextBold: true,
              ),
              leadingIcon: Icons.adaptive.share,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              onTap: () async {
                // ignore: unawaited_futures
                await shareText(
                  url,
                  context: context,
                );
              },
              isTopBorderRadiusRemoved: true,
              isBottomBorderRadiusRemoved: true,
            ),
          ],
        );
      }

      children.addAll(
        [
          DividerWidget(
            dividerType: DividerType.menu,
            bgColor: getEnteColorScheme(context).fillFaint,
          ),
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.manageLink,
              makeTextBold: true,
            ),
            leadingIcon: Icons.link,
            trailingIcon: Icons.navigate_next,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            trailingIconIsMuted: true,
            onTap: () async {
              // ignore: unawaited_futures
              routeToPage(
                context,
                ManageSharedLinkWidget(collection: widget.collection),
              ).then(
                (value) => {
                  if (mounted) {setState(() => {})},
                },
              );
            },
            isTopBorderRadiusRemoved: true,
          ),
          const SizedBox(height: 24),
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.removeLink,
              textColor: warning500,
              makeTextBold: true,
            ),
            leadingIcon: Icons.remove_circle_outline,
            leadingIconColor: warning500,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            surfaceExecutionStates: false,
            onTap: () async {
              final bool result = await CollectionActions.disableUrl(
                context,
                widget.collection,
              );
              if (result && mounted) {
                Navigator.of(context).pop();
                if (widget.collection.isQuickLinkCollection()) {
                  Navigator.of(context).pop();
                }
              }
            },
          ),
        ],
      );
    } else {
      children.addAll(
        [
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: context.l10n.createPublicLink,
              makeTextBold: true,
            ),
            leadingIcon: Icons.link,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            showOnlyLoadingState: true,
            onTap: () async {
              final bool result =
                  await CollectionActions.enableUrl(context, widget.collection);
              if (result && mounted) {
                setState(() => {});
              }
            },
          ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.collection.name ?? "Collection",
          style:
              Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 16),
        ),
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: ListBody(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmailItemWidget extends StatelessWidget {
  final Collection collection;
  final Function? onTap;

  const EmailItemWidget(
    this.collection, {
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (collection.getSharees().isEmpty) {
      return const SizedBox.shrink();
    } else if (collection.getSharees().length == 1) {
      final User? user = collection.getSharees().firstOrNull;
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: user?.displayName ?? user?.email ?? '',
            ),
            leadingIconWidget: UserAvatarWidget(
              collection.getSharees().first,
              thumbnailView: false,
              config: Configuration.instance,
            ),
            leadingIconSize: 24,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            trailingIconIsMuted: true,
            trailingIcon: Icons.chevron_right,
            onTap: () async {
              if (onTap != null) {
                onTap!();
              }
            },
            isBottomBorderRadiusRemoved: true,
          ),
          DividerWidget(
            dividerType: DividerType.menu,
            bgColor: getEnteColorScheme(context).fillFaint,
          ),
        ],
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MenuItemWidget(
            captionedTextWidget: Flexible(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                child: SizedBox(
                  height: 24,
                  child: AlbumSharesIcons(
                    sharees: collection.getSharees(),
                    padding: const EdgeInsets.all(0),
                    limitCountTo: 10,
                    type: AvatarType.mini,
                    removeBorder: false,
                  ),
                ),
              ),
            ),
            alignCaptionedTextToLeft: true,
            // leadingIcon: Icons.people_outline,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            trailingIconIsMuted: true,
            trailingIcon: Icons.chevron_right,
            onTap: () async {
              if (onTap != null) {
                onTap!();
              }
            },
            isBottomBorderRadiusRemoved: true,
          ),
          DividerWidget(
            dividerType: DividerType.menu,
            bgColor: getEnteColorScheme(context).fillFaint,
          ),
        ],
      );
    }
  }
}
