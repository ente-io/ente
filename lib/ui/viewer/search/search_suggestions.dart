import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/clear_and_unfocus_search_bar_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/generic_search_result.dart';
import 'package:photos/models/search/search_result.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/ui/viewer/search/result/search_result_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class SearchSuggestionsWidget extends StatelessWidget {
  final List<SearchResult> results;

  const SearchSuggestionsWidget(
    this.results, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    late final String title;
    final resultsCount = results.length;
    title = S.of(context).searchResultCount(resultsCount);
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Bus.instance.fire(ClearAndUnfocusSearchBar());
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: getEnteTextTheme(context).largeBold,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final result = results[index];
                    if (result is AlbumSearchResult) {
                      final AlbumSearchResult albumSearchResult = result;
                      return SearchResultWidget(
                        result,
                        resultCount: CollectionsService.instance.getFileCount(
                          albumSearchResult.collectionWithThumbnail.collection,
                        ),
                        onResultTap: () => routeToPage(
                          context,
                          CollectionPage(
                            albumSearchResult.collectionWithThumbnail,
                            tagPrefix: result.heroTag(),
                          ),
                        ),
                      );
                    } else if (result is GenericSearchResult) {
                      return SearchResultWidget(
                        result,
                        onResultTap: result.onResultTap != null
                            ? () => result.onResultTap!(context)
                            : null,
                      );
                    } else {
                      Logger('SearchSuggestionsWidget')
                          .info("Invalid/Unsupported value");
                      return const SizedBox.shrink();
                    }
                  },
                  padding: EdgeInsets.only(
                    bottom: (MediaQuery.sizeOf(context).height / 2) + 50,
                  ),
                  separatorBuilder: (context, index) {
                    return const SizedBox(height: 12);
                  },
                  itemCount: results.length,
                  physics: const BouncingScrollPhysics(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
