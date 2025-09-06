import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import 'package:locker/utils/collection_actions.dart';

class CollectionPage extends UploaderPage {
  final Collection collection;

  const CollectionPage({
    super.key,
    required this.collection,
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends UploaderPageState<CollectionPage>
    with SearchMixin {
  late Collection _collection;
  List<EnteFile> _files = [];
  List<EnteFile> _filteredFiles = [];

  @override
  void onFileUploadComplete() {
    CollectionService.instance.getCollections().then((collections) {
      setState(() {
        _initializeData(collections.where((c) => c.id == _collection.id).first);
      });
    });
  }

  @override
  List<Collection> get allCollections => [];

  @override
  List<EnteFile> get allFiles => _files;

  @override
  Collection get selectedCollection => _collection;

  @override
  void onSearchResultsChanged(
      List<Collection> collections, List<EnteFile> files,) {
    setState(() {
      _filteredFiles = files;
    });
  }

  @override
  void onSearchStateChanged(bool isActive) {
    if (!isActive) {
      setState(() {
        _filteredFiles = _files;
      });
    }
  }

  List<EnteFile> get _displayedFiles =>
      isSearchActive ? _filteredFiles : _files;

  @override
  void initState() {
    super.initState();
    _initializeData(widget.collection);
    Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      final collection = (await CollectionService.instance.getCollections())
          .where(
            (c) => c.id == widget.collection.id,
          )
          .first;
      await _initializeData(collection);
    });
  }

  Future<void> _initializeData(Collection collection) async {
    _collection = collection;
    _files = await CollectionService.instance.getFilesInCollection(_collection);
    _filteredFiles = _files;
    setState(() {});
  }

  Future<void> _deleteCollection() async {
    await CollectionActions.deleteCollection(
      context,
      _collection,
      onSuccess: () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  Future<void> _editCollection() async {
    await CollectionActions.editCollection(
      context,
      _collection,
      onSuccess: () {
        setState(() {});
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: handleKeyEvent,
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton:
            isSearchActive ? const SizedBox.shrink() : _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leading: buildSearchLeading(),
      title: Text(
        _collection.name ?? context.l10n.untitled,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      elevation: 0,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
      actions: [
        buildSearchAction(),
        ...buildSearchActions(),
        _buildMenuButton(),
      ],
    );
  }

  Widget _buildMenuButton() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            _editCollection();
            break;
          case 'delete':
            _deleteCollection();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit),
                const SizedBox(width: 12),
                Text(context.l10n.edit),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete, color: Colors.red),
                const SizedBox(width: 12),
                Text(
                  context.l10n.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  Widget _buildBody() {
    if (isSearchActive) {
      return SearchResultView(
        collections: const [], // CollectionPage primarily shows files
        files: _filteredFiles,
        searchQuery: searchQuery,
        enableSorting: true,
        isHomePage: false,
        onSearchEverywhere: _searchEverywhere,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: _buildFilesList(),
    );
  }

  Widget _buildFilesList() {
    return _displayedFiles.isEmpty
        ? SizedBox(
            height: 400,
            child: _buildEmptyState(),
          )
        : ItemListView(
            key: ValueKey(_displayedFiles.length),
            files: _displayedFiles,
            enableSorting: true,
          );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearchActive ? Icons.search_off : Icons.folder_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              isSearchActive
                  ? 'No files found for "$searchQuery"'
                  : context.l10n.noFilesFound,
              style: getEnteTextTheme(context).large.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isSearchActive) ...[
              const SizedBox(height: 8),
              Text(
                'Try adjusting your search query',
                style: getEnteTextTheme(context).body.copyWith(
                      color: Colors.grey[600],
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
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

  Widget _buildFAB() {
    return FloatingActionButton(
      onPressed: addFile,
      tooltip: context.l10n.addFiles,
      child: const Icon(Icons.add),
    );
  }
}
