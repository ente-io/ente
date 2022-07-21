import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/viewer/search/SearchResultsSuggestions.dart';

class SearchIconWidget extends StatefulWidget {
  bool openSearch;
  SearchIconWidget({Key key, this.openSearch = false}) : super(key: key);

  @override
  State<SearchIconWidget> createState() => _SearchIconWidgetState();
}

class _SearchIconWidgetState extends State<SearchIconWidget> {
  @override
  Widget build(BuildContext context) {
    return widget.openSearch
        ? Searchwidget(widget.openSearch)
        : IconButton(
            onPressed: () {
              setState(
                () {
                  widget.openSearch = !widget.openSearch;
                },
              );
            },
            icon: const Icon(Icons.search),
          );
  }
}

class Searchwidget extends StatefulWidget {
  bool openSearch;
  String searchQuery = '';
  Searchwidget(this.openSearch, {Key key}) : super(key: key);
  @override
  State<Searchwidget> createState() => _SearchwidgetState();
}

class _SearchwidgetState extends State<Searchwidget> {
  final ValueNotifier<String> _searchQ = ValueNotifier('');
  @override
  Widget build(BuildContext context) {
    Map<String, Set> collectionIDs;
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
                        onChanged: (value) {
                          collectionIDs = CollectionsService.instance
                              .getSearchedCollectionsId(value);
                          debugPrint(collectionIDs.toString());
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
                  debugPrint('listening to search value');
                  return newQuery != ''
                      ? SearchResultsSuggestions(
                          collectionIDs: collectionIDs,
                        )
                      : const SizedBox.shrink();
                },
              ),
            ],
          )
        : SearchIconWidget();
  }
}
