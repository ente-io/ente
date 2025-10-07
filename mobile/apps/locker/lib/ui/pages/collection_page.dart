import "dart:async";

import 'package:ente_events/event_bus.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/utils/dialog_util.dart";

import "package:ente_utils/navigation_util.dart";
import 'package:flutter/material.dart';
import 'package:locker/events/collections_updated_event.dart';
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_files.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import "package:locker/ui/sharing/album_participants_page.dart";
import "package:locker/ui/sharing/manage_links_widget.dart";
import "package:locker/ui/sharing/share_collection_page.dart";
import "package:locker/ui/viewer/actions/file_selection_overlay_bar.dart";
import 'package:locker/utils/collection_actions.dart';
import "package:logging/logging.dart";

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
  final _logger = Logger("CollectionPage");
  late StreamSubscription<CollectionsUpdatedEvent>
      _collectionUpdateSubscription;

  late Collection _collection;
  List<EnteFile> _files = [];
  List<EnteFile> _filteredFiles = [];
  late CollectionViewType collectionViewType;
  bool isQuickLink = false;
  bool showFAB = true;

  final _selectedFiles = SelectedFiles();

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
    List<Collection> collections,
    List<EnteFile> files,
  ) {
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

  @override
  void dispose() {
    _collectionUpdateSubscription.cancel();
    super.dispose();
  }

  List<EnteFile> get _displayedFiles =>
      isSearchActive ? _filteredFiles : _files;

  @override
  void initState() {
    super.initState();
    _initializeData(widget.collection);
    _collectionUpdateSubscription =
        Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      if (!mounted) return;

      try {
        final collections = await CollectionService.instance.getCollections();

        final matchingCollection = collections.where(
          (c) => c.id == widget.collection.id,
        );

        if (matchingCollection.isNotEmpty) {
          await _initializeData(matchingCollection.first);
        } else {
          _logger.warning(
            'Collection ${widget.collection.id} no longer exists, navigating back',
          );
          if (mounted) {
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        _logger.severe('Error updating collection: $e');
      }
    });

    collectionViewType = getCollectionViewType(
      _collection,
      Configuration.instance.getUserID()!,
    );

    showFAB = collectionViewType == CollectionViewType.ownedCollection ||
        collectionViewType == CollectionViewType.hiddenOwnedCollection ||
        collectionViewType == CollectionViewType.quickLink;
  }

  Future<void> _initializeData(Collection collection) async {
    _collection = collection;
    _files = await CollectionService.instance.getFilesInCollection(_collection);
    _filteredFiles = _files;
    setState(() {});
  }

  Future<void> _deleteCollection() async {
    await CollectionActions.deleteCollection(context, _collection);
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

  Future<void> _shareCollection() async {
    final collection = widget.collection;
    try {
      if ((collectionViewType != CollectionViewType.ownedCollection &&
          collectionViewType != CollectionViewType.sharedCollection &&
          collectionViewType != CollectionViewType.hiddenOwnedCollection &&
          collectionViewType != CollectionViewType.favorite &&
          !isQuickLink)) {
        throw Exception(
          "Cannot share collection of type $collectionViewType",
        );
      }
      if (Configuration.instance.getUserID() == collection.owner.id) {
        unawaited(
          routeToPage(
            context,
            (isQuickLink && (collection.hasLink))
                ? ManageSharedLinkWidget(collection: collection)
                : ShareCollectionPage(collection: collection),
          ),
        );
      } else {
        unawaited(
          routeToPage(
            context,
            AlbumParticipantsPage(collection),
          ),
        );
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _leaveCollection() async {
    await CollectionActions.leaveCollection(
      context,
      _collection,
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
        bottomNavigationBar: ListenableBuilder(
          listenable: _selectedFiles,
          builder: (context, _) {
            return _selectedFiles.hasSelections
                ? FileSelectionOverlayBar(
                    files: _displayedFiles,
                    selectedFiles: _selectedFiles,
                  )
                : const SizedBox.shrink();
          },
        ),
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
        IconButton(
          icon: Icon(
            Icons.adaptive.share,
          ),
          onPressed: () async {
            await _shareCollection();
          },
        ),
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
          case 'leave_collection':
            _leaveCollection();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          if (collectionViewType == CollectionViewType.ownedCollection ||
              collectionViewType == CollectionViewType.hiddenOwnedCollection ||
              collectionViewType == CollectionViewType.quickLink)
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
          if (collectionViewType == CollectionViewType.ownedCollection ||
              collectionViewType == CollectionViewType.hiddenOwnedCollection ||
              collectionViewType == CollectionViewType.quickLink)
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
          if (collectionViewType == CollectionViewType.sharedCollection)
            PopupMenuItem<String>(
              value: 'leave_collection',
              child: Row(
                children: [
                  const Icon(Icons.logout),
                  const SizedBox(width: 12),
                  Text(context.l10n.leaveCollection),
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
            selectedFiles: _selectedFiles,
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
                  ? context.l10n.noFilesFoundForQuery(searchQuery)
                  : context.l10n.noFilesFound,
              style: getEnteTextTheme(context).large.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
            if (isSearchActive) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.tryAdjustingYourSearchQuery,
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
    return showFAB
        ? FloatingActionButton(
            onPressed: addFile,
            tooltip: context.l10n.addFiles,
            child: const Icon(Icons.add),
          )
        : const SizedBox.shrink();
  }
}
