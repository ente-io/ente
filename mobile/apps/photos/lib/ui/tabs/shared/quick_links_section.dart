import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/api/file_share_url.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/quick_link_item.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/single_file_share_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/sharing/manage_single_file_link_widget.dart";
import "package:photos/ui/tabs/section_title.dart";
import "package:photos/ui/tabs/shared/all_quick_links_page.dart";
import "package:photos/ui/tabs/shared/quick_link_album_item.dart";
import "package:photos/ui/tabs/shared/quick_link_file_item.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/utils/navigation_util.dart";

class QuickLinksSection extends StatefulWidget {
  final List<Collection> collectionQuickLinks;
  final String titleHeroTag;

  const QuickLinksSection({
    super.key,
    required this.collectionQuickLinks,
    required this.titleHeroTag,
  });

  @override
  State<QuickLinksSection> createState() => _QuickLinksSectionState();
}

class _QuickLinksSectionState extends State<QuickLinksSection> {
  static const _maxQuickLinks = 4;
  static const _heroTagPrefix = "outgoing_collection";

  List<QuickLinkItem>? _combinedQuickLinks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadQuickLinks();
  }

  @override
  void didUpdateWidget(QuickLinksSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectionQuickLinks != widget.collectionQuickLinks) {
      _loadQuickLinks();
    }
  }

  Future<void> _loadQuickLinks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch single file share URLs
      final fileShareUrls =
          await SingleFileShareService.instance.getActiveShareUrls();

      // Combine both types into a single list
      final combined = <QuickLinkItem>[];

      // Add collection quick links
      for (final collection in widget.collectionQuickLinks) {
        combined.add(CollectionQuickLink(collection));
      }

      // Add single file share quick links
      for (final fileShare in fileShareUrls) {
        combined.add(FileQuickLink(fileShare));
      }

      // Sort by creation time (newest first)
      combined.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      if (mounted) {
        setState(() {
          _combinedQuickLinks = combined;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          // Fall back to just collection quick links on error
          _combinedQuickLinks = widget.collectionQuickLinks
              .map((c) => CollectionQuickLink(c))
              .toList();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EnteLoadingWidget(),
      );
    }

    final quickLinks = _combinedQuickLinks ?? [];
    if (quickLinks.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorTheme = getEnteColorScheme(context);
    final numberOfQuickLinks = quickLinks.length;

    return Column(
      children: [
        SectionOptions(
          onTap: numberOfQuickLinks > _maxQuickLinks
              ? () {
                  unawaited(
                    routeToPage(
                      context,
                      AllQuickLinksPage(
                        titleHeroTag: widget.titleHeroTag,
                        quickLinks: widget.collectionQuickLinks,
                      ),
                    ),
                  );
                }
              : null,
          Hero(
            tag: widget.titleHeroTag,
            child: SectionTitle(
              title: AppLocalizations.of(context).quickLinks,
            ),
          ),
          trailingWidget: numberOfQuickLinks > _maxQuickLinks
              ? IconButtonWidget(
                  icon: Icons.chevron_right,
                  iconButtonType: IconButtonType.secondary,
                  iconColor: colorTheme.blurStrokePressed,
                )
              : null,
        ),
        const SizedBox(height: 2),
        ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.only(
            bottom: 12,
            left: 12,
            right: 12,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final item = quickLinks[index];
            return _buildQuickLinkItem(item);
          },
          separatorBuilder: (context, index) {
            return const SizedBox(height: 4);
          },
          itemCount: min(numberOfQuickLinks, _maxQuickLinks),
        ),
      ],
    );
  }

  Widget _buildQuickLinkItem(QuickLinkItem item) {
    switch (item) {
      case CollectionQuickLink(:final collection):
        return GestureDetector(
          onTap: () async {
            final thumbnail =
                await CollectionsService.instance.getCover(collection);
            final page = CollectionPage(
              CollectionWithThumbnail(collection, thumbnail),
              tagPrefix: _heroTagPrefix,
            );
            // ignore: unawaited_futures
            routeToPage(context, page);
          },
          child: QuickLinkAlbumItem(c: collection),
        );
      case FileQuickLink(:final fileShareUrl):
        return GestureDetector(
          onTap: () async {
            await _navigateToFileDetail(fileShareUrl);
          },
          child: QuickLinkFileItem(
            fileShareUrl: fileShareUrl,
            onShareTap: () => _navigateToManageLink(fileShareUrl),
          ),
        );
    }
  }

  Future<void> _navigateToFileDetail(FileShareUrl fileShareUrl) async {
    final file = await FilesDB.instance.getAnyUploadedFile(fileShareUrl.fileID);
    if (file != null && mounted) {
      unawaited(
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              List.unmodifiable([file]),
              0,
              "quick_link_file_${file.uploadedFileID}",
            ),
          ),
        ),
      );
    }
  }

  Future<void> _navigateToManageLink(FileShareUrl fileShareUrl) async {
    final file = await FilesDB.instance.getAnyUploadedFile(fileShareUrl.fileID);
    final result = await routeToPage(
      context,
      ManageSingleFileLinkWidget(
        fileShareUrl: fileShareUrl,
        file: file,
      ),
    );
    // Reload if link was removed
    if (result == true && mounted) {
      unawaited(_loadQuickLinks());
    }
  }
}
