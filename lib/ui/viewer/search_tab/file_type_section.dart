import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/events/event.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/ui/viewer/search/search_section_cta.dart";
import "package:photos/ui/viewer/search_tab/section_header.dart";
import "package:photos/utils/navigation_util.dart";

class FileTypeSection extends StatefulWidget {
  final List<GenericSearchResult> fileTypesSearchResults;
  const FileTypeSection(this.fileTypesSearchResults, {super.key});

  @override
  State<FileTypeSection> createState() => _FileTypeSectionState();
}

class _FileTypeSectionState extends State<FileTypeSection> {
  late List<GenericSearchResult> _fileTypesSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _fileTypesSearchResults = widget.fileTypesSearchResults;

    final streamsToListenTo =
        SectionType.fileTypesAndExtension.sectionUpdateEvents();
    for (Stream<Event> stream in streamsToListenTo) {
      streamSubscriptions.add(
        stream.listen((event) async {
          _fileTypesSearchResults =
              (await SectionType.fileTypesAndExtension.getData(
            context,
            limit: kSearchSectionLimit,
          )) as List<GenericSearchResult>;
          setState(() {});
        }),
      );
    }
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant FileTypeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _fileTypesSearchResults = widget.fileTypesSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_fileTypesSearchResults.isEmpty) {
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
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              SectionType.fileTypesAndExtension,
              hasMore:
                  (_fileTypesSearchResults.length >= kSearchSectionLimit - 1),
            ),
            const SizedBox(height: 2),
            SizedBox(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _fileTypesSearchResults
                      .map(
                        (fileTypeSearchResult) =>
                            FileTypeRecommendation(fileTypeSearchResult),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class FileTypeRecommendation extends StatelessWidget {
  static const knownTypesToAssetPath = {
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
  final GenericSearchResult fileTypeSearchResult;
  const FileTypeRecommendation(this.fileTypeSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    //remove 's' at end of extensions and use only 1st word if there exists
    //multiple words.
    final fileType = fileTypeSearchResult.name
        .call()
        .replaceAll(RegExp(r'.$'), "")
        .split(" ")
        .first;
    final assetPath = knownTypesToAssetPath[fileType];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 60),
        child: GestureDetector(
          onTap: () {
            RecentSearches().add(fileTypeSearchResult.name());
            if (fileTypeSearchResult.onResultTap != null) {
              fileTypeSearchResult.onResultTap!(context);
            } else {
              routeToPage(
                context,
                SearchResultPage(fileTypeSearchResult),
              );
            }
          },
          child: assetPath != null
              ? Image.asset(assetPath)
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Image.asset(
                      "assets/type_unknown.png",
                    ),
                    Positioned(
                      bottom: 12,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 48),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            fileType,
                            style: const TextStyle(
                              fontSize: 17.43,
                              fontFamily: "Inter",
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
