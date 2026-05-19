import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
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

  const FileTypeSection({
    required this.hasAnySearchableFiles,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!hasAnySearchableFiles) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    SectionType.fileTypesAndExtension.sectionTitle(context),
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      SectionType.fileTypesAndExtension
                          .getEmptyStateText(context),
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
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            SectionType.fileTypesAndExtension,
            hasMore: true,
          ),
          const SizedBox(height: 2),
          SizedBox(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 4.5),
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: tiles
                    .map(
                      (tile) => _FileTypeRecommendation(tile),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_FileTypeTile> _previewTiles(BuildContext context) {
    return [
      _FileTypeTile.fileType(
        assetKey: "PHOTO",
        name: getHumanReadableString(context, FileType.image),
        type: FileType.image,
      ),
      _FileTypeTile.fileType(
        assetKey: "VIDEO",
        name: getHumanReadableString(context, FileType.video),
        type: FileType.video,
      ),
      _FileTypeTile.fileType(
        assetKey: "LIVE",
        name: getHumanReadableString(context, FileType.livePhoto),
        type: FileType.livePhoto,
      ),
      const _FileTypeTile.extension(
        assetKey: "PNG",
        name: "PNGs",
        extension: "PNG",
      ),
      const _FileTypeTile.extension(
        assetKey: "JPG",
        name: "JPGs",
        extension: "JPG",
      ),
      const _FileTypeTile.extension(
        assetKey: "HEIC",
        name: "HEICs",
        extension: "HEIC",
      ),
      const _FileTypeTile.extension(
        assetKey: "MP4",
        name: "MP4s",
        extension: "MP4",
      ),
    ];
  }
}

class _FileTypeTile {
  final String assetKey;
  final String name;
  final FileType? fileType;
  final String? extension;

  const _FileTypeTile.fileType({
    required this.assetKey,
    required this.name,
    required FileType type,
  })  : fileType = type,
        extension = null;

  const _FileTypeTile.extension({
    required this.assetKey,
    required this.name,
    required this.extension,
  })  : fileType = null,
        assert(extension != null);

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
  static const knownTypesToAssetPath = {
    "PHOTO": "assets/type_photos.png",
    "VIDEO": "assets/type_videos.png",
    "LIVE": "assets/type_live.png",
    "AVI": "assets/type_AVI.png",
    "GIF": "assets/type_GIF.png",
    "HEIC": "assets/type_HEIC.png",
    "JPEG": "assets/type_JPEG.png",
    "JPG": "assets/type_JPG.png",
    "MKV": "assets/type_MKV.png",
    "MP4": "assets/type_MP4.png",
    "PNG": "assets/type_PNG.png",
    "WEBP": "assets/type_WEBP.png",
  };

  final _logger = Logger("FileTypeRecommendation");

  @override
  Widget build(BuildContext context) {
    final fileTypeKey = widget.tile.assetKey;
    final assetPath = knownTypesToAssetPath[fileTypeKey]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 68),
        child: GestureDetector(
          onTap: _onTap,
          child: Image.asset(assetPath),
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
      unawaited(
        routeToPage(
          context,
          SearchResultPage(searchResult),
        ),
      );
    } catch (e, s) {
      _logger.severe("Failed to resolve file type result", e, s);
    }
  }
}
