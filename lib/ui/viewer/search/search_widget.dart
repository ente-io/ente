import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/search/album_search_result.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/models/search/search_results.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/services/user_service.dart';
import 'package:photos/ui/viewer/search/search_results_suggestions.dart';

class SearchIconWidget extends StatefulWidget {
  const SearchIconWidget({Key key}) : super(key: key);

  @override
  State<SearchIconWidget> createState() => _SearchIconWidgetState();
}

class _SearchIconWidgetState extends State<SearchIconWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: "search_icon",
      child: IconButton(
        onPressed: () {
          setState(
            () {
              Navigator.push(
                context,
                TransparentRoute(
                  builder: (BuildContext context) => const SearchWidget(),
                ),
              );
            },
          );
        },
        icon: const Icon(Icons.search),
      ),
    );
  }
}

class SearchWidget extends StatefulWidget {
  final String searchQuery = '';
  const SearchWidget({Key key}) : super(key: key);
  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final List<SearchResult> results = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1.5),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Flexible(
                  child: Container(
                    color: Theme.of(context).colorScheme.defaultBackgroundColor,
                    child: TextFormField(
                      style: Theme.of(context).textTheme.subtitle1,
                      decoration: InputDecoration(
                        hintText: 'Search for albums, locations, files...',
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: Hero(
                          tag: "search_icon",
                          child: Icon(
                            Icons.search,
                            color: Theme.of(context)
                                .colorScheme
                                .iconColor
                                .withOpacity(0.5),
                          ),
                        ),
                        suffixIcon: IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: Icon(
                            Icons.close,
                            color: Theme.of(context)
                                .colorScheme
                                .iconColor
                                .withOpacity(0.5),
                          ),
                        ),
                      ),
                      onChanged: (value) async {
                        List<SearchResult> allResults = [];

                        final collectionResults = await CollectionsService
                            .instance
                            .getFilteredCollectionsWithThumbnail(value);
                        for (CollectionWithThumbnail collectionResult
                            in collectionResults) {
                          allResults.add(AlbumSearchResult(collectionResult));
                        }
                        final locationResults = await UserService.instance
                            .getLocationsAndMatchedFiles(value);
                        for (final result in locationResults) {
                          allResults.add(result);
                        }
                        final fileResults = await SearchService.instance
                            .getFilesOnFilenameSearch(value);
                        for (File file in fileResults) {
                          allResults.add(FileSearchResult(file));
                        }
                        if (mounted) {
                          setState(() {
                            results.clear();
                            results.addAll(allResults);
                          });
                        }
                      },
                      autofocus: true,
                    ),
                  ),
                ),
              ],
            ),
            results.isNotEmpty
                ? SearchResultsSuggestionsWidget(results)
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

class TransparentRoute extends PageRoute<void> {
  TransparentRoute({
    @required this.builder,
    RouteSettings settings,
  })  : assert(builder != null),
        super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;

  @override
  bool get opaque => false;

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final result = builder(context);
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(animation),
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: result,
      ),
    );
  }
}
