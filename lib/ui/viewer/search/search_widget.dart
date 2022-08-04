import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
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
  final ValueNotifier<String> _searchQuery = ValueNotifier('');
  bool showSearchWidget;
  @override
  void initState() {
    super.initState();
    debugPrint('showSearchWidget-----------');
    showSearchWidget = false;
  }

  @override
  Widget build(BuildContext context) {
    //when false - show the search icon, when true - show the textfield for search
    return showSearchWidget
        ? searchWidget()
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

  Widget searchWidget() {
    final List<SearchResult> results = [];
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            Flexible(
              child: Container(
                color: Theme.of(context).colorScheme.defaultBackgroundColor,
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
                    final locationResults = await UserService.instance
                        .getLocationsToMatchedFiles(value);
                    for (final result in locationResults) {
                      results.add(result);
                    }
                    final collectionResults = await CollectionsService.instance
                        .getFilteredCollectionsWithThumbnail(value);
                    results.add(AlbumSearchResult(collectionResults));
                    final fileResults =
                        await FilesDB.instance.getFilesOnFileNameSearch(value);
                    results.add(FileSearchResult(fileResults));
                    _searchQuery.value = value;
                  },
                  autofocus: true,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  showSearchWidget = !showSearchWidget;
                });
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ValueListenableBuilder(
          valueListenable: _searchQuery,
          builder: (
            BuildContext context,
            String newQuery,
            Widget child,
          ) {
            return newQuery != ''
                ? SearchResultsSuggestionsWidget(results)
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
