import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import 'package:photos/models/search/search_result.dart';
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/search/result/contact_result_page.dart";
import 'package:photos/ui/viewer/search/result/search_result_page.dart';
import 'package:photos/ui/viewer/search/result/search_thumbnail_widget.dart';

class SearchResultWidget extends StatelessWidget {
  final SearchResult searchResult;
  final Future<int>? resultCount;
  final Function? onResultTap;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showTypeLabel;

  const SearchResultWidget(
    this.searchResult, {
    super.key,
    this.resultCount,
    this.onResultTap,
    this.borderRadius = BorderRadius.zero,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    this.showTypeLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final heroTagPrefix = searchResult.heroTag();
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return SizedBox(
      key: ValueKey(searchResult.hashCode),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () {
            RecentSearches().add(searchResult.name());

            if (onResultTap != null) {
              onResultTap!();
            } else {
              if (searchResult.type() == ResultType.shared) {
                routeToPage(
                  context,
                  ContactResultPage(
                    searchResult,
                  ),
                );
              } else {
                routeToPage(
                  context,
                  SearchResultPage(
                    searchResult,
                  ),
                );
              }
            }
          },
          child: Padding(
            padding: padding,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                searchResult.type() == ResultType.shared
                    ? ContactSearchThumbnailWidget(
                        heroTagPrefix,
                        searchResult: searchResult as GenericSearchResult,
                      )
                    : SearchThumbnailWidget(
                        searchResult.previewThumbnail(),
                        heroTagPrefix,
                        searchResult: searchResult,
                      ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        searchResult.name(),
                        style: textTheme.bodyBold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      FutureBuilder<int>(
                        future: resultCount ??
                            Future.value(searchResult.resultFiles().length),
                        builder: (context, snapshot) {
                          final label = showTypeLabel
                              ? _resultTypeLabel(context, searchResult.type())
                              : null;
                          if (snapshot.hasData && (snapshot.data ?? 0) > 0) {
                            final count = snapshot.data!;
                            final countText = count > 9999
                                ? NumberFormat().format(count)
                                : count.toString();
                            return Text(
                              label != null
                                  ? "$label \u2022 $countText"
                                  : countText,
                              style: textTheme.smallMuted,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          if (label != null) {
                            return Text(
                              label,
                              style: textTheme.smallMuted,
                              overflow: TextOverflow.ellipsis,
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.strokeMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _resultTypeLabel(BuildContext context, ResultType type) {
    final localizations = AppLocalizations.of(context);
    switch (type) {
      case ResultType.file:
        return localizations.searchResultFileName;
      case ResultType.fileCaption:
        return localizations.searchResultDescription;
      case ResultType.fileType:
        return localizations.searchResultType;
      case ResultType.fileExtension:
        return localizations.searchResultFileExtension;
      case ResultType.faces:
        return localizations.searchResultPerson;
      case ResultType.shared:
        return localizations.searchResultShared;
      case ResultType.uploader:
        return localizations.searchResultUploadedBy;
      case ResultType.cameraMake:
        return localizations.searchResultCameraMake;
      case ResultType.cameraModel:
        return localizations.searchResultCameraModel;
      case ResultType.collection:
      case ResultType.year:
      case ResultType.month:
      case ResultType.event:
      case ResultType.location:
      case ResultType.locationSuggestion:
      case ResultType.magic:
        return null;
    }
  }
}
