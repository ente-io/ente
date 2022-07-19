import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/collections_service.dart';

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
  Searchwidget(this.openSearch, {Key key}) : super(key: key);

  @override
  State<Searchwidget> createState() => _SearchwidgetState();
}

class _SearchwidgetState extends State<Searchwidget> {
  TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return widget.openSearch
        ? Row(
            children: [
              const SizedBox(width: 12),
              Flexible(
                child: Container(
                  color: Theme.of(context).colorScheme.defaultBackgroundColor,
                  child: TextFormField(
                    style: Theme.of(context).textTheme.subtitle1,
                    controller: searchController,
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
                      Set ids = CollectionsService.instance
                          .getSearchedCollectionsId(value);
                      debugPrint(ids.toString());
                    },
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
          )
        : SearchIconWidget();
  }
}
