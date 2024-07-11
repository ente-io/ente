import 'package:flutter/material.dart';
import "package:intl/intl.dart";
import 'package:photos/ente_theme_data.dart';
import "package:photos/models/search/recent_searches.dart";
import 'package:photos/models/search/search_result.dart';
import "package:photos/models/search/search_types.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/viewer/search/result/search_result_page.dart';
import 'package:photos/ui/viewer/search/result/search_thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class SearchResultWidget extends StatelessWidget {
  final SearchResult searchResult;
  final Future<int>? resultCount;
  final Function? onResultTap;

  const SearchResultWidget(
    this.searchResult, {
    Key? key,
    this.resultCount,
    this.onResultTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final heroTagPrefix = searchResult.heroTag();
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(4)),
          border: Border.all(
            color: getEnteColorScheme(context).strokeFainter,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SearchThumbnailWidget(
              searchResult.previewThumbnail(),
              heroTagPrefix,
              searchResult: searchResult,
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 220,
                    child: Text(
                      searchResult.name(),
                      style: textTheme.body,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _resultTypeName(searchResult.type()),
                        style: textTheme.smallMuted,
                      ),
                      FutureBuilder<int>(
                        future: resultCount ??
                            Future.value(searchResult.resultFiles().length),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data! > 0) {
                            final noOfMemories = snapshot.data;

                            return Text(
                              " \u2022 " +
                                  (noOfMemories! > 9999
                                      ? NumberFormat().format(noOfMemories)
                                      : noOfMemories.toString()),
                              style: textTheme.smallMuted,
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.subTextColor,
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        RecentSearches().add(searchResult.name());

        if (onResultTap != null) {
          onResultTap!();
        } else {
          routeToPage(
            context,
            SearchResultPage(
              searchResult,
              enableGrouping: searchResult.type() != ResultType.magic,
            ),
          );
        }
      },
    );
  }

  String _resultTypeName(ResultType type) {
    switch (type) {
      case ResultType.collection:
        return "Album";
      case ResultType.year:
        return "Year";
      case ResultType.month:
        return "Month";
      case ResultType.file:
        return "File name";
      case ResultType.event:
        return "Day";
      case ResultType.location:
        return "Location";
      case ResultType.locationSuggestion:
        return "Add Location";
      case ResultType.fileType:
        return "Type";
      case ResultType.fileExtension:
        return "File extension";
      case ResultType.fileCaption:
        return "Description";
      case ResultType.magic:
        return "Magic";
      case ResultType.shared:
        return "Shared";
      case ResultType.faces:
        return "Person";
      default:
        return type.name.toUpperCase();
    }
  }
}
