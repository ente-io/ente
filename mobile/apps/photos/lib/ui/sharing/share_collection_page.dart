import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:photos/extensions/user_extension.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/collection/user.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/sharing/add_participant_page.dart";
import 'package:photos/ui/sharing/album_participants_page.dart';
import "package:photos/ui/sharing/album_share_info_widget.dart";
import "package:photos/ui/sharing/manage_album_participant.dart";
import 'package:photos/ui/sharing/manage_links_widget.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';

class ShareCollectionPage extends StatefulWidget {
  final Collection collection;

  const ShareCollectionPage(this.collection, {super.key});

  @override
  State<ShareCollectionPage> createState() => _ShareCollectionPageState();
}

class _ShareCollectionPageState extends State<ShareCollectionPage> {
  late List<User?> _sharees;
  final CollectionActions collectionActions =
      CollectionActions(CollectionsService.instance);
  final GlobalKey sendLinkButtonKey = GlobalKey();

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
    _sharees = widget.collection.sharees;
    final bool hasUrl = widget.collection.hasLink;
    final children = <Widget>[];
    children.add(
      MenuSectionTitle(
        title: AppLocalizations.of(context)
            .shareWithPeopleSectionTitle(numberOfPeople: _sharees.length),
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
          title: AppLocalizations.of(context).addViewer,
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
          title: AppLocalizations.of(context).addCollaborator,
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
          content: AppLocalizations.of(context).sharedAlbumSectionDescription,
        ),
      );
    }

    final bool hasExpired =
        widget.collection.publicURLs.firstOrNull?.isExpired ?? false;
    children.addAll([
      const SizedBox(
        height: 24,
      ),
      MenuSectionTitle(
        title: hasUrl
            ? AppLocalizations.of(context).publicLinkEnabled
            : AppLocalizations.of(context).shareALink,
        iconData: Icons.public,
      ),
    ]);
    if (hasUrl) {
      if (hasExpired) {
        children.add(
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: AppLocalizations.of(context).linkHasExpired,
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
            CollectionsService.instance.getPublicUrl(widget.collection);
        children.addAll(
          [
            MenuItemWidget(
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).copyLink,
                makeTextBold: true,
              ),
              leadingIcon: Icons.copy,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              showOnlyLoadingState: true,
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: url));
                showShortToast(
                  context,
                  AppLocalizations.of(context).linkCopiedToClipboard,
                );
              },
              isBottomBorderRadiusRemoved: true,
            ),
            DividerWidget(
              dividerType: DividerType.menu,
              bgColor: getEnteColorScheme(context).fillFaint,
            ),
            MenuItemWidget(
              key: sendLinkButtonKey,
              captionedTextWidget: CaptionedTextWidget(
                title: AppLocalizations.of(context).sendLink,
                makeTextBold: true,
              ),
              leadingIcon: Icons.adaptive.share,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              onTap: () async {
                // ignore: unawaited_futures
                await shareAlbumLinkWithPlaceholder(
                  context,
                  widget.collection,
                  url,
                  sendLinkButtonKey,
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
              title: AppLocalizations.of(context).manageLink,
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
        ],
      );
    } else {
      children.addAll([
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).createPublicLink,
            makeTextBold: true,
          ),
          leadingIcon: Icons.link,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          showOnlyLoadingState: true,
          onTap: () async {
            final bool result =
                await collectionActions.enableUrl(context, widget.collection);
            if (result && mounted) {
              setState(() => {});
            }
          },
        ),
        _sharees.isEmpty
            ? MenuSectionDescriptionWidget(
                content: AppLocalizations.of(context).shareWithNonenteUsers,
              )
            : const SizedBox.shrink(),
        const SizedBox(
          height: 24,
        ),
        MenuSectionTitle(
          title: AppLocalizations.of(context).collectPhotos,
          iconData: Icons.public,
        ),
        MenuItemWidget(
          captionedTextWidget: CaptionedTextWidget(
            title: AppLocalizations.of(context).createCollaborativeLink,
            makeTextBold: true,
          ),
          leadingIcon: Icons.people_alt_outlined,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          showOnlyLoadingState: true,
          onTap: () async {
            final bool result = await collectionActions.enableUrl(
              context,
              widget.collection,
              enableCollect: true,
            );
            if (result && mounted) {
              setState(() => {});
            }
          },
        ),
        _sharees.isEmpty
            ? MenuSectionDescriptionWidget(
                content:
                    AppLocalizations.of(context).collabLinkSectionDescription,
              )
            : const SizedBox.shrink(),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.collection.displayName,
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
