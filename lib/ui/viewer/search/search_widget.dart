import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/viewer/search/search_results_suggestions.dart';

class SearchIconWidget extends StatefulWidget {
  final String searchQuery = '';
  const SearchIconWidget({Key key}) : super(key: key);

  @override
  State<SearchIconWidget> createState() => _SearchIconWidgetState();
}

class _SearchIconWidgetState extends State<SearchIconWidget> {
  bool showSearchWidget;
  @override
  void initState() {
    super.initState();
    showSearchWidget = false;
  }

  @override
  Widget build(BuildContext context) {
    //when false - show the search icon, when true - show the textfield for search
    return showSearchWidget
        ? SearchWidget(showSearchWidget)
        : IconButton(
            onPressed: () {
              setState(
                () {
                  showSearchWidget = !showSearchWidget;
                },
              );
            },
            icon: const Icon(Icons.search),
          );
  }
}

class SearchWidget extends StatefulWidget {
  bool openSearch;
  final String searchQuery = '';
  SearchWidget(this.openSearch, {Key key}) : super(key: key);
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final List<SearchResult> results = [];
  @override
  Widget build(BuildContext context) {
    return widget.openSearch
        ? Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 12),
                  Flexible(
                    child: Container(
                      color:
                          Theme.of(context).colorScheme.defaultBackgroundColor,
                      child: TextFormField(
                        style: Theme.of(context).textTheme.subtitle1,
                        decoration: InputDecoration(
                          filled: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: UnderlineInputBorder(
                            borderSide: BorderSide.none,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          prefixIcon: const Icon(Icons.search),
                        ),
                        onChanged: (value) async {
                          List<SearchResult> combinedResults = [];

                          final collectionResults = await CollectionsService
                              .instance
                              .getFilteredCollectionsWithThumbnail(value);
                          for (CollectionWithThumbnail collectionResult
                              in collectionResults) {
                            combinedResults
                                .add(AlbumSearchResult(collectionResult));
                          }
                          final locationResults = await UserService.instance
                              .getLocationsToMatchedFiles(value);
                          for (final result in locationResults) {
                            combinedResults.add(result);
                          }
                          final fileResults = await FilesDB.instance
                              .getFilesOnFileNameSearch(value);
                          for (File file in fileResults) {
                            combinedResults.add(FileSearchResult(file));
                          }
                          setState(() {
                            results.clear();
                            results.addAll(combinedResults);
                          });
                        },
                        autofocus: true,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        widget.openSearch = !widget.openSearch;
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              SearchResultsSuggestionsWidget(results),
              // const SizedBox.shrink();
            ],
          )
        : const SearchIconWidget();
  }
}
