import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/search_result.dart';
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Theme.of(context).colorScheme.searchResultsColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SearchThumbnailWidget(
                searchResult.previewThumbnail(),
                heroTagPrefix,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _resultTypeName(searchResult.type()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 220,
                    child: Text(
                      searchResult.name(),
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FutureBuilder<int>(
                    future: resultCount ??
                        Future.value(searchResult.resultFiles().length),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data! > 0) {
                        final noOfMemories = snapshot.data;
                        return RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .searchResultsCountTextColor,
                            ),
                            children: [
                              TextSpan(text: noOfMemories.toString()),
                              TextSpan(
                                text:
                                    noOfMemories != 1 ? ' memories' : ' memory',
                              ),
                            ],
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  )
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.subTextColor,
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        if (onResultTap != null) {
          onResultTap!();
        } else {
          routeToPage(
            context,
            SearchResultPage(searchResult),
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
      case ResultType.fileType:
        return "Type";
      case ResultType.fileExtension:
        return "File extension";
      case ResultType.fileCaption:
        return "Description";
      default:
        return type.name.toUpperCase();
    }
  }
}
