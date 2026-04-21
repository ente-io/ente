import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/memory_share/memory_share.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/memory_share_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import "package:photos/ui/components/action_sheet_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/sharing/memory_link_details_sheet.dart";
import "package:photos/ui/tabs/shared/memory_link_item.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/dialog_util.dart";

class AllLinksPage extends StatefulWidget {
  final List<Collection> quickLinks;
  final List<MemoryShare> memoryShares;
  final String titleHeroTag;

  const AllLinksPage({
    required this.quickLinks,
    required this.memoryShares,
    required this.titleHeroTag,
    super.key,
  });

  @override
  State<AllLinksPage> createState() => _AllLinksPageState();
}

class _AllLinksPageState extends State<AllLinksPage> {
  static const _quickLinkHeroTagPrefix = "outgoing_collection";

  final List<Collection> _selectedQuickLinks = [];

  bool get _hasSelection => _selectedQuickLinks.isNotEmpty;

  Future<void> _navigateToCollectionPage(Collection c) async {
    final thumbnail = await CollectionsService.instance.getCover(c);
    if (!mounted) return;
    unawaited(
      routeToPage(
        context,
        CollectionPage(
          CollectionWithThumbnail(c, thumbnail),
          tagPrefix: _quickLinkHeroTagPrefix,
        ),
      ),
    );
  }

  Future<void> _toggleQuickLinkSelection(Collection c) async {
    if (_selectedQuickLinks.contains(c)) {
      _selectedQuickLinks.remove(c);
    } else {
      if (_selectedQuickLinks.isEmpty) {
        await HapticFeedback.mediumImpact();
      }
      _selectedQuickLinks.add(c);
    }
    setState(() {});
  }

  Future<void> _removeSelectedQuickLinks() async {
    if (_selectedQuickLinks.isEmpty) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).noQuickLinksSelected,
        AppLocalizations.of(context).pleaseSelectQuickLinksToRemove,
      );
      return;
    }
    final result = await showActionSheet(
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
            for (final link in List<Collection>.of(_selectedQuickLinks)) {
              await CollectionActions(CollectionsService.instance)
                  .trashCollectionKeepingPhotos(link, context);
              widget.quickLinks.remove(link);
            }
            setState(_selectedQuickLinks.clear);
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
    if (result?.action == ButtonAction.error) {
      await showGenericErrorDialog(context: context, error: result!.exception);
    }
  }

  Future<void> _openMemoryLink(MemoryShare share) async {
    final deleted = await showMemoryLinkDetailsSheet(
      context,
      shareUrl: share.url,
      shareId: share.id,
    );
    if (deleted != true || !mounted) return;
    setState(() {
      widget.memoryShares.removeWhere((m) => m.id == share.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final strings = AppLocalizations.of(context);
    final hasQuickLinks = widget.quickLinks.isNotEmpty;
    final hasMemoryLinks = widget.memoryShares.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        leadingWidth: 48,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_outlined),
        ),
        actions: [
          if (_hasSelection)
            IconButton(
              onPressed: _removeSelectedQuickLinks,
              icon: Icon(
                Icons.remove_circle_outline_outlined,
                color: colorScheme.blurStrokeBase,
              ),
            ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TitleBarTitleWidget(
                    title: "Links",
                    heroTag: widget.titleHeroTag,
                  ),
                  Text(
                    (widget.quickLinks.length + widget.memoryShares.length)
                        .toString(),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
          if (hasQuickLinks) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(strings.quickLinks, style: textTheme.largeBold),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: widget.quickLinks.length,
                itemBuilder: (context, index) {
                  final c = widget.quickLinks[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (_hasSelection) {
                        _toggleQuickLinkSelection(c);
                      } else {
                        _navigateToCollectionPage(c);
                      }
                    },
                    onLongPress: () {
                      if (_hasSelection) {
                        _navigateToCollectionPage(c);
                      } else {
                        _toggleQuickLinkSelection(c);
                      }
                    },
                    child: QuickLinkAlbumItem(
                      c: c,
                      selectedQuickLinks: _selectedQuickLinks,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (hasMemoryLinks) ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverToBoxAdapter(
                child: Text(strings.memoryLinks, style: textTheme.largeBold),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.separated(
                itemCount: widget.memoryShares.length,
                itemBuilder: (context, index) {
                  final share = widget.memoryShares[index];
                  final title = MemoryShareService.instance
                          .getMemoryShareTitle(share) ??
                      "Memory link";
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _openMemoryLink(share),
                    child: MemoryLinkAlbumItem(
                      title: title,
                      fileCount: share.fileCount,
                      previewUploadedFileID: share.previewUploadedFileID,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 10),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
          if (!hasQuickLinks && !hasMemoryLinks)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    "No links yet",
                    style: textTheme.bodyMuted,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
