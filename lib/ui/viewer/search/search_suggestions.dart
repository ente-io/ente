import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/generic_search_result.dart';
import 'package:photos/models/search/search_result.dart';
import 'package:photos/ui/viewer/gallery/collection_page.dart';
import 'package:photos/ui/viewer/search/result/file_result_widget.dart';
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
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.searchResultsColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: -3,
              blurRadius: 6,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(8)),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(
              maxHeight: 324,
            ),
            child: Scrollbar(
              child: ListView.builder(
                physics: const ClampingScrollPhysics(),
                shrinkWrap: true,
                itemCount: results.length + 1,
                itemBuilder: (context, index) {
                  if (results.length == index) {
                    return Container(
                      height: 6,
                      color: Theme.of(context).colorScheme.searchResultsColor,
                    );
                  }
                  final result = results[index];
                  if (result is AlbumSearchResult) {
                    final AlbumSearchResult albumSearchResult = result;
                    return SearchResultWidget(
                      result,
                      resultCount: FilesDB.instance.collectionFileCount(
                        albumSearchResult.collectionWithThumbnail.collection.id,
                      ),
                      onResultTap: () => routeToPage(
                        context,
                        CollectionPage(
                          albumSearchResult.collectionWithThumbnail,
                          tagPrefix: result.heroTag(),
                        ),
                      ),
                    );
                  } else if (result is FileSearchResult) {
                    return FileSearchResultWidget(result);
                  } else if (result is GenericSearchResult) {
                    return SearchResultWidget(result);
                  } else {
                    Logger('SearchSuggestionsWidget')
                        .info("Invalid/Unsupported value");
                    return const SizedBox.shrink();
                  }
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
