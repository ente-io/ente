import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";

class AllQuickLinksPage extends StatefulWidget {
  final List<Collection> quickLinks;
  final String titleHeroTag;
  const AllQuickLinksPage({
    required this.quickLinks,
    required this.titleHeroTag,
    super.key,
  });

  @override
  State<AllQuickLinksPage> createState() => _AllQuickLinksPageState();
}

class _AllQuickLinksPageState extends State<AllQuickLinksPage> {
  List<Collection> selectedQuickLinks = [];
  bool isAnyQuickLinkSelected = false;
  final _logger = Logger("QuickLinks");
  static const heroTagPrefix = "outgoing_collection";

  Future<void> _navigateToCollectionPage(Collection c) async {
    final thumbnail = await CollectionsService.instance.getCover(c);
    final page = CollectionPage(
      CollectionWithThumbnail(
        c,
        thumbnail,
      ),
      tagPrefix: heroTagPrefix,
    );
    // ignore: unawaited_futures
    routeToPage(context, page);
  }

  void _toggleQuickLinkSelection(Collection c) {
    if (selectedQuickLinks.contains(c)) {
      selectedQuickLinks.remove(c);
    } else {
      selectedQuickLinks.add(c);
    }
    setState(() {
      isAnyQuickLinkSelected = selectedQuickLinks.isNotEmpty;
    });
  }

  Future<void> _removeQuickLink() async {
    try {
      final dialog = createProgressDialog(
        context,
        S.of(context).removeLink,
        isDismissible: true,
      );
      await dialog.show();

      for (var selectedQuickLink in selectedQuickLinks) {
        if (selectedQuickLink.isQuickLinkCollection() &&
            !selectedQuickLink.hasSharees) {
          await CollectionActions(CollectionsService.instance)
              .trashCollectionKeepingPhotos(selectedQuickLink, context);
          widget.quickLinks.remove(selectedQuickLink);
        } else {
          widget.quickLinks.remove(selectedQuickLink);
          await CollectionsService.instance.disableShareUrl(selectedQuickLink);
        }
      }
      setState(() {
        selectedQuickLinks.clear();
        isAnyQuickLinkSelected = false;
      });
      await dialog.hide();
    } catch (e, s) {
      _logger.severe("failed to trash collection", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () {
            Navigator.pop(context);
          },
          child: const Icon(
            Icons.arrow_back_outlined,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () async {
              await _removeQuickLink();
            },
            icon: const Icon(Icons.remove_circle_outline_outlined),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TitleBarTitleWidget(
                  title: S.of(context).quickLinks,
                  heroTag: widget.titleHeroTag,
                ),
                Text(widget.quickLinks.length.toString()),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
                horizontal: 16,
              ),
              child: ListView.separated(
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      isAnyQuickLinkSelected
                          ? _toggleQuickLinkSelection(widget.quickLinks[index])
                          : _navigateToCollectionPage(widget.quickLinks[index]);
                    },
                    onLongPress: () {
                      isAnyQuickLinkSelected
                          ? _navigateToCollectionPage(widget.quickLinks[index])
                          : _toggleQuickLinkSelection(widget.quickLinks[index]);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: QuickLinkAlbumItem(
                      c: widget.quickLinks[index],
                      selectedQuickLinks: selectedQuickLinks,
                    ),
                  );
                },
                separatorBuilder: (context, index) {
                  return const SizedBox(height: 10);
                },
                itemCount: widget.quickLinks.length,
                physics: const BouncingScrollPhysics(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
