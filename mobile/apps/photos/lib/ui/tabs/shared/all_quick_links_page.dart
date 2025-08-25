import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
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

  Future<void> _toggleQuickLinkSelection(Collection c) async {
    if (selectedQuickLinks.contains(c)) {
      selectedQuickLinks.remove(c);
    } else {
      selectedQuickLinks.isEmpty ? await HapticFeedback.mediumImpact() : null;
      selectedQuickLinks.add(c);
    }
    setState(() {
      isAnyQuickLinkSelected = selectedQuickLinks.isNotEmpty;
    });
  }

  Future<bool> _removeQuickLinks() async {
    if (selectedQuickLinks.isEmpty) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).noQuickLinksSelected,
        AppLocalizations.of(context).pleaseSelectQuickLinksToRemove,
      );
      return true;
    }
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: AppLocalizations.of(context).yesRemove,
          onTap: () async {
            for (var selectedQuickLink in selectedQuickLinks) {
              await CollectionActions(CollectionsService.instance)
                  .trashCollectionKeepingPhotos(selectedQuickLink, context);
              widget.quickLinks.remove(selectedQuickLink);
            }
            setState(() {
              selectedQuickLinks.clear();
              isAnyQuickLinkSelected = false;
            });
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: AppLocalizations.of(context).cancel,
        ),
      ],
      title: AppLocalizations.of(context).removePublicLinks,
      body: AppLocalizations.of(context)
          .thisWillRemovePublicLinksOfAllSelectedQuickLinks,
    );
    if (actionResult?.action != null) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      }
      return actionResult.action == ButtonAction.first;
    } else {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
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
              await _removeQuickLinks();
            },
            icon: Icon(
              Icons.remove_circle_outline_outlined,
              color: colorScheme.blurStrokeBase,
            ),
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
                  title: AppLocalizations.of(context).quickLinks,
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
