import "dart:async";
import "dart:math" as math;

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
import "package:photos/utils/pending_translation.dart";

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
        icon: HugeIcons.strokeRoundedPlayCircle,
      ),
      _FileTypeTile.fileType(
        label: pendingTranslation("Live"),
        name: livePhotos,
        type: FileType.livePhoto,
        icon: HugeIcons.strokeRoundedPlayCircle,
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
  bool get isFileType => fileType != null;

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
    return GestureDetector(
      onTap: _onTap,
      child: widget.tile.isFileType
          ? _FileTypeCard(widget.tile)
          : _FileExtensionPill(widget.tile),
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

class _FileTypeCard extends StatelessWidget {
  static const width = 108.0;
  static const height = 56.0;

  final _FileTypeTile tile;

  const _FileTypeCard(this.tile);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return CustomPaint(
      painter: _FileTypeCardBackgroundPainter(colorScheme.fill),
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            Positioned(
              left: 13,
              right: 38,
              top: 31,
              height: 17,
              child: Text(
                tile.label,
                style: TextStyles.mini.copyWith(
                  color: colorScheme.textBase,
                  fontSize: 12.461538,
                  fontWeight: FontWeight.w700,
                  height: 16.615385 / 12.461538,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Positioned(
              left: 74,
              top: 7,
              width: 34,
              height: 34,
              child: Center(
                child: HugeIcon(
                  icon: tile.icon,
                  size: 18,
                  color: colorScheme.textBase,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileExtensionPill extends StatelessWidget {
  final _FileTypeTile tile;

  const _FileExtensionPill(this.tile);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return Container(
      width: 78.75,
      height: 56,
      decoration: BoxDecoration(
        color: colorScheme.fill,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HugeIcon(icon: tile.icon, size: 22, color: colorScheme.textBase),
          const SizedBox(height: 2),
          Text(
            tile.label,
            style: TextStyles.tiny.copyWith(color: colorScheme.textBase),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FileTypeCardBackgroundPainter extends CustomPainter {
  final Color color;

  const _FileTypeCardBackgroundPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..isAntiAlias = true;
    canvas.drawPath(_FileTypeCardPath.build(size), paint);
  }

  @override
  bool shouldRepaint(_FileTypeCardBackgroundPainter oldDelegate) {
    return color != oldDelegate.color;
  }
}

class _FileTypeCardPath {
  static const _figmaWidth = 108.0;
  static const _figmaHeight = 56.0;
  static const _figmaPoints = [
    Offset(0, 0),
    Offset(47.5, 0),
    Offset(53.5, 7),
    Offset(108, 7),
    Offset(108, 56),
    Offset(0, 56),
  ];
  static const _figmaRadii = [16.0, 8.0, 0.0, 16.0, 16.0, 16.0];

  static Path build(Size size) {
    final scaleX = size.width / _figmaWidth;
    final scaleY = size.height / _figmaHeight;
    final radiusScale = math.min(scaleX, scaleY);
    final points = _figmaPoints
        .map((point) => Offset(point.dx * scaleX, point.dy * scaleY))
        .toList();
    final radii = _figmaRadii.map((radius) => radius * radiusScale).toList();
    return _roundedPolygon(points, radii);
  }

  static Path _roundedPolygon(List<Offset> points, List<double> radii) {
    final path = Path();
    for (var index = 0; index < points.length; index++) {
      final current = points[index];
      final previous = points[(index - 1 + points.length) % points.length];
      final next = points[(index + 1) % points.length];
      final incoming = previous - current;
      final outgoing = next - current;
      final incomingLength = incoming.distance;
      final outgoingLength = outgoing.distance;
      final radius = radii[index];

      if (radius <= 0 || incomingLength == 0 || outgoingLength == 0) {
        if (index == 0) {
          path.moveTo(current.dx, current.dy);
        } else {
          path.lineTo(current.dx, current.dy);
        }
        continue;
      }

      final incomingUnit = incoming / incomingLength;
      final outgoingUnit = outgoing / outgoingLength;
      final dotProduct =
          (incomingUnit.dx * outgoingUnit.dx) +
          (incomingUnit.dy * outgoingUnit.dy);
      final angle = math.acos(dotProduct.clamp(-1.0, 1.0));
      final tangentLength = math.min(
        radius / math.tan(angle / 2),
        math.min(incomingLength, outgoingLength) / 2,
      );
      final start = current + incomingUnit * tangentLength;
      final end = current + outgoingUnit * tangentLength;

      if (index == 0) {
        path.moveTo(start.dx, start.dy);
      } else {
        path.lineTo(start.dx, start.dy);
      }
      path.quadraticBezierTo(current.dx, current.dy, end.dx, end.dy);
    }
    path.close();
    return path;
  }
}
