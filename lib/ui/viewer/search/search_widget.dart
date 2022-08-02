import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
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
    List<CollectionWithThumbnail> matchedCollections = [];
    List<File> matchedFiles = [];
    List<dynamic> matchedLocationNamesAndBboxs = [];
    List<dynamic> matchedLocationsResults = [];
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
                    matchedCollections = await CollectionsService.instance
                        .getFilteredCollectionsWithThumbnail(value);
                    matchedFiles =
                        await FilesDB.instance.getFilesOnFileNameSearch(value);
                    matchedLocationNamesAndBboxs =
                        await UserService.instance.getLocationSearchData(value);
                    log("sss----------------------");
                    // matchedLocationsResults = await FilesDB.instance
                    //     .getFilesInsideBbox(matchedLocationNamesAndBboxs);
                    // print('getFilesInsideBox finished');
                    // print('Matched Locations');
                    // print(matchedLocationNamesAndBboxs);
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
                ? SearchResultsSuggestions(
                    matchedCollections,
                    matchedFiles,
                    matchedLocationNamesAndBboxs,
                  )
                : const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
