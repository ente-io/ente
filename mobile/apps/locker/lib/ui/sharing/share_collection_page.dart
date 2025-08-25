import "package:ente_ui/components/captioned_text_widget.dart";
import "package:ente_ui/components/divider_widget.dart";
import "package:ente_ui/components/menu_item_widget.dart";
import "package:ente_ui/theme/colors.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:ente_utils/ente_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/collections/models/collection.dart";
import "package:locker/ui/components/menu_section_title.dart";
import "package:locker/ui/sharing/manage_links_widget.dart";
import "package:locker/utils/collection_actions.dart";

class ShareCollectionPage extends StatefulWidget {
  final Collection collection;
  const ShareCollectionPage({super.key, required this.collection});

  @override
  State<ShareCollectionPage> createState() => _ShareCollectionPageState();
}

class _ShareCollectionPageState extends State<ShareCollectionPage> {
  @override
  Widget build(BuildContext context) {
    final bool hasUrl = widget.collection.hasLink; 
    final bool hasExpired =
        widget.collection.publicURLs.firstOrNull?.isExpired ?? false;
    final children = <Widget>[];
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
            isBottomBorderRadiusRemoved: true,
          ),
        );
      } else {
        final String url =
            CollectionService.instance.getPublicUrl(widget.collection);
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
            captionedTextWidget: const CaptionedTextWidget(
              title: "Manage link",
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
            captionedTextWidget: const CaptionedTextWidget(
              title: "Remove Link",
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
            captionedTextWidget: const CaptionedTextWidget(
              title: "Create public link",
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
