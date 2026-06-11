import "dart:async";

import "package:ente_components/theme/text_styles.dart";
import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";

class FileTypeSection extends StatelessWidget {
  final bool hasAnySearchableFiles;

  const FileTypeSection({required this.hasAnySearchableFiles, super.key});

  @override
  Widget build(BuildContext context) {
    if (!hasAnySearchableFiles) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8, bottom: 24),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SectionType.fileTypesAndExtension.sectionTitle(context),
                    style: TextStyles.h2.copyWith(
                      color: textTheme.largeBold.color,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.fileTypesAndExtension.getEmptyStateText(
                        context,
                      ),
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const SearchSectionEmptyCTAIcon(SectionType.fileTypesAndExtension),
          ],
        ),
      );
    }

    final tiles = _previewTiles(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(SectionType.fileTypesAndExtension, hasMore: true),
          const SizedBox(height: 8),
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              itemCount: tiles.length,
              itemBuilder: (context, index) {
                return _FileTypeRecommendation(tiles[index]);
              },
              separatorBuilder: (context, index) => const SizedBox(width: 10),
            ),
          ),
        ],
      ),
    );
  }

  List<_FileTypeTile> _previewTiles(BuildContext context) {
    final photos = getHumanReadableString(context, FileType.image);
    final videos = getHumanReadableString(context, FileType.video);
    final livePhotos = getHumanReadableString(context, FileType.livePhoto);
    return [
      _FileTypeTile.fileType(
        label: photos,
        name: photos,
        type: FileType.image,
        icon: HugeIcons.strokeRoundedImage01,
      ),
      _FileTypeTile.fileType(
        label: videos,
        name: videos,
        type: FileType.video,
        icon: HugeIcons.strokeRoundedVideo02,
      ),
      _FileTypeTile.fileType(
        label: livePhotos,
        name: livePhotos,
        type: FileType.livePhoto,
        icon: HugeIcons.strokeRoundedLiveStreaming01,
      ),
      const _FileTypeTile.extension(
        label: "PNG",
        name: "PNGs",
        extension: "PNG",
        icon: HugeIcons.strokeRoundedFile01,
      ),
      const _FileTypeTile.extension(
        label: "JPG",
        name: "JPGs",
        extension: "JPG",
        icon: HugeIcons.strokeRoundedFile01,
      ),
      const _FileTypeTile.extension(
        label: "HEIC",
        name: "HEICs",
        extension: "HEIC",
        icon: HugeIcons.strokeRoundedFile01,
      ),
      const _FileTypeTile.extension(
        label: "MP4",
        name: "MP4s",
        extension: "MP4",
        icon: HugeIcons.strokeRoundedFile01,
      ),
    ];
  }
}

class _FileTypeTile {
  final String label;
  final String name;
  final FileType? fileType;
  final String? extension;
  final List<List<dynamic>> icon;

  const _FileTypeTile.fileType({
    required this.label,
    required this.name,
    required FileType type,
    required this.icon,
  }) : fileType = type,
       extension = null;

  const _FileTypeTile.extension({
    required this.label,
    required this.name,
    required this.extension,
    required this.icon,
  }) : fileType = null;

  Future<GenericSearchResult> resolve() {
    final type = fileType;
    if (type != null) {
      return SearchService.instance.getFileTypeResult(
        fileType: type,
        typeName: name,
      );
    }
    return SearchService.instance.getFileExtensionResult(
      extension: extension!,
      extensionName: name,
    );
  }
}

class _FileTypeRecommendation extends StatefulWidget {
  final _FileTypeTile tile;

  const _FileTypeRecommendation(this.tile);

  @override
  State<_FileTypeRecommendation> createState() =>
      _FileTypeRecommendationState();
}

class _FileTypeRecommendationState extends State<_FileTypeRecommendation> {
  final _logger = Logger("FileTypeRecommendation");

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return GestureDetector(
      onTap: _onTap,
      child: Container(
        width: 78.75,
        height: 56,
        decoration: BoxDecoration(
          color: colorScheme.fill,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: widget.tile.icon,
              size: 22,
              color: colorScheme.textBase,
            ),
            const SizedBox(height: 2),
            Text(
              widget.tile.label,
              style: TextStyles.tiny.copyWith(color: colorScheme.textBase),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onTap() async {
    try {
      final searchResult = await widget.tile.resolve();
      if (!mounted) {
        return;
      }
      RecentSearches().add(searchResult.name());
      unawaited(routeToPage(context, SearchResultPage(searchResult)));
    } catch (e, s) {
      _logger.severe("Failed to resolve file type result", e, s);
    }
  }
}
