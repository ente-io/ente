import 'dart:async';

import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/services/trash/trash_service.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/collection_page.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/trash_page.dart';
import 'package:locker/utils/collection_sort_util.dart';
import 'package:logging/logging.dart';

class AllCollectionsPage extends StatefulWidget {
  const AllCollectionsPage({super.key});

  @override
  State<AllCollectionsPage> createState() => _AllCollectionsPageState();
}

class _AllCollectionsPageState extends State<AllCollectionsPage>
    with SearchMixin {
  List<Collection> _sortedCollections = [];
  List<Collection> _allCollections = [];
  Collection? _uncategorizedCollection;
  int? _uncategorizedFileCount;
  List<EnteFile> _allFiles = [];
  bool _isLoading = true;
  String? _error;
  final _logger = Logger("AllCollectionsPage");

  @override
  List<Collection> get allCollections => _allCollections;

  @override
  List<EnteFile> get allFiles => _allFiles;

  @override
  void onSearchResultsChanged(
    List<Collection> collections,
    List<EnteFile> files,
  ) {
    setState(() {
      if (searchQuery.isEmpty) {
        final regularCollections = collections
            .where((c) => c.type != CollectionType.uncategorized)
            .toList();
        _sortedCollections =
            CollectionSortUtil.getSortedCollections(regularCollections);
      } else {
        _sortedCollections =
            CollectionSortUtil.getSortedCollections(collections);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _loadCollections();
    Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      await _loadCollections();
    });
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final collections = await CollectionService.instance.getCollections();

      final regularCollections = <Collection>[];
      Collection? uncategorized;

      for (final collection in collections) {
        if (collection.type == CollectionType.uncategorized) {
          uncategorized = collection;
        } else {
          regularCollections.add(collection);
        }
      }

      CollectionSortUtil.sortCollections(regularCollections);

      _allCollections = List.from(collections);
      _sortedCollections = List.from(regularCollections);
      _uncategorizedCollection = uncategorized;
      _uncategorizedFileCount = uncategorized != null
          ? (await CollectionService.instance
                  .getFilesInCollection(uncategorized))
              .length
          : 0;
      _allFiles = await CollectionService.instance.getAllFiles();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe("Failed to load collections", e);
      setState(() {
        _error = 'Failed to load collections: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          leading: buildSearchLeading(),
          title: Text(context.l10n.collections),
          centerTitle: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
          actions: [
            buildSearchAction(),
            ...buildSearchActions(),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadCollections,
              child: Text(context.l10n.retry),
            ),
          ],
        ),
      );
    }

    if (isSearchActive) {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: SearchResultView(
          collections: _sortedCollections,
          files: const [],
          searchQuery: searchQuery,
          enableSorting: true,
          isHomePage: false,
          onSearchEverywhere: _searchEverywhere,
        ),
      );
    }

    if (_sortedCollections.isEmpty) {
      if (searchQuery.isNotEmpty) {
        return FileListViewHelpers.createSearchEmptyState(
          searchQuery: searchQuery,
          message: context.l10n.noCollectionsFoundForQuery(searchQuery),
        );
      } else {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.noCollectionsFound,
                  style: getEnteTextTheme(context).large.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (searchQuery.isNotEmpty)
            Container(
              padding: const EdgeInsets.only(bottom: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                '${_sortedCollections.length} result${_sortedCollections.length == 1 ? '' : 's'} for "$searchQuery"',
                style: getEnteTextTheme(context).small.copyWith(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
              ),
            ),
          Flexible(
            child: ItemListView(
              collections: _sortedCollections,
              enableSorting: true,
            ),
          ),
          if (!isSearchActive && _uncategorizedCollection != null)
            _buildUncategorizedHook(),
          _buildTrashHook(),
        ],
      ),
    );
  }

  Widget _buildTrashHook() {
    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 16.0),
      child: InkWell(
        onTap: _openTrash,
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.trash,
                  style: getEnteTextTheme(context).large.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openTrash() async {
    final trashFiles = await TrashService.instance.getTrashFiles();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => TrashPage(trashFiles: trashFiles),
      ),
    );
  }

  void _searchEverywhere() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => HomePage(initialSearchQuery: searchQuery),
      ),
      (route) => false,
    );
  }

  Widget _buildUncategorizedHook() {
    if (_uncategorizedCollection == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: InkWell(
        onTap: () => _openUncategorized(),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withOpacity(0.3),
            border: Border.all(
              color: Theme.of(context).dividerColor.withOpacity(0.5),
              width: 0.5,
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            children: [
              Icon(
                Icons.folder_open_outlined,
                color: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.color
                    ?.withOpacity(0.7),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      context.l10n.uncategorized,
                      style: getEnteTextTheme(context).large.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    if (_uncategorizedFileCount! > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•',
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.5),
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_uncategorizedFileCount!}',
                        style: getEnteTextTheme(context).small.copyWith(
                              color: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.color
                                  ?.withOpacity(0.7),
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.color
                    ?.withOpacity(0.6),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUncategorized() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            CollectionPage(collection: _uncategorizedCollection!),
      ),
    );
  }
}
