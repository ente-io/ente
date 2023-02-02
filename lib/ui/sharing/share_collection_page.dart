import 'package:collection/collection.dart';
import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/divider_widget.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/ui/components/menu_section_title.dart';
import 'package:photos/ui/sharing/add_partipant_page.dart';
import 'package:photos/ui/sharing/album_participants_page.dart';
import 'package:photos/ui/sharing/manage_links_widget.dart';
import 'package:photos/ui/sharing/user_avator_widget.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class ShareCollectionPage extends StatefulWidget {
  final Collection collection;

  const ShareCollectionPage(this.collection, {Key? key}) : super(key: key);

  @override
  State<ShareCollectionPage> createState() => _ShareCollectionPageState();
}

class _ShareCollectionPageState extends State<ShareCollectionPage> {
  late List<User?> _sharees;
  final CollectionActions collectionActions =
      CollectionActions(CollectionsService.instance);

  Future<void> _navigateToManageUser() async {
    await routeToPage(
      context,
      AlbumParticipantsPage(widget.collection),
    );
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    _sharees = widget.collection.sharees ?? [];
    final bool hasUrl = widget.collection.hasLink;
    final children = <Widget>[];
    children.add(
      MenuSectionTitle(
        title: _sharees.isEmpty
            ? "Share with specific people"
            : "Shared with ${_sharees.length} ${_sharees.length == 1 ? 'person' : 'people'}",
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
        captionedTextWidget: const CaptionedTextWidget(
          title: "Add viewer",
          makeTextBold: true,
        ),
        leadingIcon: Icons.add,
        menuItemColor: getEnteColorScheme(context).fillFaint,
        borderRadius: 4.0,
        isTopBorderRadiusRemoved: _sharees.isNotEmpty,
        isBottomBorderRadiusRemoved: true,
        onTap: () async {
          routeToPage(
            context,
            AddParticipantPage(widget.collection, true),
          ).then(
            (value) => {
              if (mounted) {setState(() => {})}
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
        captionedTextWidget: const CaptionedTextWidget(
          title: "Add collaborator",
          makeTextBold: true,
        ),
        leadingIcon: Icons.add,
        menuItemColor: getEnteColorScheme(context).fillFaint,
        borderRadius: 4.0,
        isTopBorderRadiusRemoved: _sharees.isNotEmpty,
        onTap: () async {
          routeToPage(context, AddParticipantPage(widget.collection, false))
              .then(
            (value) => {
              if (mounted) {setState(() => {})}
            },
          );
        },
      ),
    );
    if (_sharees.isEmpty && !hasUrl) {
      children.add(
        const MenuSectionDescriptionWidget(
          content:
              "Create shared and collaborative albums with other ente users, "
              "including users on free plans.",
        ),
      );
    }

    final bool hasExpired =
        widget.collection.publicURLs?.firstOrNull?.isExpired ?? false;
    children.addAll([
      const SizedBox(
        height: 24,
      ),
      MenuSectionTitle(
        title: hasUrl ? "Public link enabled" : "Share a link",
        iconData: Icons.public,
      ),
    ]);
    if (hasUrl) {
      if (hasExpired) {
        children.add(
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: "Link has expired",
              textColor: getEnteColorScheme(context).warning500,
            ),
            leadingIcon: Icons.error_outline,
            leadingIconColor: getEnteColorScheme(context).warning500,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            onTap: () async {},
            isBottomBorderRadiusRemoved: true,
          ),
        );
      } else {
        final String collectionKey = Base58Encode(
          CollectionsService.instance.getCollectionKey(widget.collection.id),
        );
        final String url =
            "${widget.collection.publicURLs!.first!.url}#$collectionKey";
        children.addAll(
          [
            MenuItemWidget(
              captionedTextWidget: const CaptionedTextWidget(
                title: "Copy link",
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
              captionedTextWidget: const CaptionedTextWidget(
                title: "Send link",
                makeTextBold: true,
              ),
              leadingIcon: Icons.adaptive.share,
              menuItemColor: getEnteColorScheme(context).fillFaint,
              onTap: () async {
                shareText(url);
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
            captionedTextWidget: const CaptionedTextWidget(
              title: "Manage link",
              makeTextBold: true,
            ),
            leadingIcon: Icons.link,
            trailingIcon: Icons.navigate_next,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            trailingIconIsMuted: true,
            onTap: () async {
              routeToPage(
                context,
                ManageSharedLinkWidget(collection: widget.collection),
              ).then(
                (value) => {
                  if (mounted) {setState(() => {})}
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
          captionedTextWidget: const CaptionedTextWidget(
            title: "Create public link",
            makeTextBold: true,
          ),
          leadingIcon: Icons.link,
          menuItemColor: getEnteColorScheme(context).fillFaint,
          isBottomBorderRadiusRemoved: true,
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
            ? const MenuSectionDescriptionWidget(
                content: "Share with non-ente users",
              )
            : const SizedBox.shrink(),
        const SizedBox(
          height: 24,
        ),
        const MenuSectionTitle(
          title: "Collaborative link",
          iconData: Icons.public,
        ),
        MenuItemWidget(
          captionedTextWidget: const CaptionedTextWidget(
            title: "Collect photos",
            makeTextBold: true,
          ),
          leadingIcon: Icons.link,
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
            ? const MenuSectionDescriptionWidget(
                content:
                    "Create a link to allow people to add and view photos in "
                    "your shared album without needing an ente app or account. Great for collecting event photos.",
              )
            : const SizedBox.shrink(),
      ]);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.collection.name ?? "Unnamed",
          style: Theme.of(context).textTheme.headline5?.copyWith(fontSize: 16),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (collection.getSharees().isEmpty) {
      return const SizedBox.shrink();
    } else if (collection.getSharees().length == 1) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          MenuItemWidget(
            captionedTextWidget: CaptionedTextWidget(
              title: collection.getSharees().firstOrNull?.email ?? '',
            ),
            leadingIconWidget: UserAvatarWidget(
              collection.getSharees().first,
              thumbnailView: true,
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
            captionedTextWidget: const CaptionedTextWidget(
              title: 'Manage',
            ),
            leadingIcon: Icons.people_outline,
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
