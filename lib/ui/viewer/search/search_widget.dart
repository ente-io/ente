import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/search/search_results_suggestions.dart';

class SearchIconWidget extends StatefulWidget {
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
    return showSearchWidget
        ? Searchwidget(showSearchWidget)
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

// ignore: must_be_immutable
class Searchwidget extends StatefulWidget {
  bool openSearch;
  final String searchQuery = '';
  Searchwidget(this.openSearch, {Key key}) : super(key: key);
  @override
  State<Searchwidget> createState() => _SearchwidgetState();
}

class _SearchwidgetState extends State<Searchwidget> {
  final ValueNotifier<String> _searchQ = ValueNotifier('');
  @override
  Widget build(BuildContext context) {
    List<CollectionWithThumbnail> matchedCollections;
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
                          matchedCollections = await CollectionsService.instance
                              .getFilteredCollectionsWithThumbnail(value);
                          _searchQ.value = value;
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
              ValueListenableBuilder(
                valueListenable: _searchQ,
                builder: (
                  BuildContext context,
                  String newQuery,
                  Widget child,
                ) {
                  return newQuery != ''
                      ? SearchResultsSuggestions(
                          collectionsWithThumbnail: matchedCollections,
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          )
        : SearchIconWidget();
  }
}
