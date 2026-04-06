import "dart:async";

import 'package:ente_events/event_bus.dart';
import "package:ente_ui/components/title_bar_title_widget.dart";
import "package:ente_ui/theme/colors.dart";
import 'package:ente_ui/theme/ente_theme.dart';
import "package:ente_ui/theme/text_style.dart";
import "package:ente_ui/utils/dialog_util.dart";
import 'package:flutter/material.dart';
import "package:hugeicons/hugeicons.dart";
import 'package:locker/events/collections_updated_event.dart';
import "package:locker/extensions/collection_extension.dart";
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_files.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import 'package:locker/services/files/sync/models/file.dart';
import "package:locker/ui/components/collection_popup_menu_widget.dart";
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/item_list_view.dart';
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import "package:locker/ui/sharing/share_collection_bottom_sheet.dart";
import "package:locker/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:logging/logging.dart";

class CollectionPage extends UploaderPage {
  final Collection collection;
  final bool isUncategorized;

  const CollectionPage({
    super.key,
    required this.collection,
    this.isUncategorized = false,
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
  bool isFavorite = false;

  final _selectedFiles = SelectedFiles();
  final _scrollController = ScrollController();

  @override
  void onFileUploadComplete() {
    _logger.info(
      "File upload completed from CollectionPage (${widget.collection.id}), refreshing collection data",
    );
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
    _scrollController.dispose();
    super.dispose();
  }

  List<EnteFile> get _displayedFiles =>
      isSearchActive ? _filteredFiles : _files;

  bool get _isSelectionEnabled =>
      collectionViewType != CollectionViewType.quickLink;

  @override
  void initState() {
    super.initState();
    _initializeData(widget.collection);
    _collectionUpdateSubscription =
        Bus.instance.on<CollectionsUpdatedEvent>().listen((event) async {
      _logger.info(
        "CollectionsUpdatedEvent received on CollectionPage (${widget.collection.id}): ${event.source}",
      );
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
        _logger.severe('Error updating collection', e);
      }
    });

    collectionViewType = getCollectionViewType(
      _collection,
      Configuration.instance.getUserID()!,
    );
    isFavorite = collectionViewType == CollectionViewType.favorite;
  }

  Future<void> _initializeData(Collection collection) async {
    _collection = collection;
    _files = await CollectionService.instance.getFilesInCollection(_collection);
    _filteredFiles = _files;
    setState(() {});
  }

  Future<void> _shareCollection() async {
    try {
      if ((collectionViewType != CollectionViewType.ownedCollection &&
          collectionViewType != CollectionViewType.sharedCollectionViewer &&
          collectionViewType !=
              CollectionViewType.sharedCollectionCollaborator &&
          collectionViewType != CollectionViewType.hiddenOwnedCollection &&
          collectionViewType != CollectionViewType.favorite &&
          !isQuickLink)) {
        throw Exception(
          "Cannot share collection of type $collectionViewType",
        );
      }

      await showShareCollectionSheet(context, collection: _collection);
      if (mounted) {
        setState(() {});
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: handleKeyEvent,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: colorScheme.backgroundBase,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 48,
          leadingWidth: 48,
          leading: GestureDetector(
            onTap: () {
              Navigator.pop(context);
            },
            child: const Icon(
              Icons.arrow_back_outlined,
            ),
          ),
        ),
        backgroundColor: colorScheme.backgroundBase,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            _buildBody(colorScheme, textTheme),
            FileSelectionOverlayBar(
              files: _displayedFiles,
              selectedFiles: _selectedFiles,
              collectionViewType: collectionViewType,
              scrollController: _scrollController,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShareButton(EnteColorScheme colorScheme) {
    if (isFavorite) {
      return const SizedBox.shrink();
    }
    final canShare = collectionViewType == CollectionViewType.ownedCollection ||
        collectionViewType == CollectionViewType.hiddenOwnedCollection ||
        collectionViewType == CollectionViewType.sharedCollectionViewer ||
        collectionViewType == CollectionViewType.sharedCollectionCollaborator ||
        isQuickLink;
    if (!canShare) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: _shareCollection,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.backdropBase,
        ),
        padding: const EdgeInsets.all(12),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedShare08,
          color: colorScheme.textBase,
        ),
      ),
    );
  }

  Widget _buildMenuButton(EnteColorScheme colorScheme) {
    if (isFavorite) {
      return SizedBox.fromSize();
    }
    final canManageCollection =
        collectionViewType == CollectionViewType.ownedCollection ||
        collectionViewType == CollectionViewType.hiddenOwnedCollection ||
        collectionViewType == CollectionViewType.sharedCollectionViewer ||
        collectionViewType ==
            CollectionViewType.sharedCollectionCollaborator ||
        collectionViewType == CollectionViewType.quickLink;
    if (!canManageCollection) {
      return SizedBox.fromSize();
    }

    return CollectionPopupMenuWidget(
      collection: _collection,
      child: Container(
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.backdropBase,
        ),
        padding: const EdgeInsets.all(12),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedMoreVertical,
          color: colorScheme.textBase,
        ),
      ),
    );
  }

  Widget _buildBody(EnteColorScheme colorScheme, EnteTextTheme textTheme) {
    if (isSearchActive) {
      return SearchResultView(
        collections: const [], // CollectionPage primarily shows files
        files: _filteredFiles,
        searchQuery: searchQuery,
        isHomePage: false,
        onSearchEverywhere: _searchEverywhere,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TitleBarTitleWidget(
                title: _collection.displayName ?? context.l10n.untitled,
                trailingWidgets: widget.isUncategorized
                    ? const []
                    : [
                        _buildShareButton(colorScheme),
                        const SizedBox(width: 12),
                        _buildMenuButton(colorScheme),
                      ],
              ),
              Text(
                _displayedFiles.length.toString(),
                style: textTheme.smallMuted,
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: _displayedFiles.isEmpty
                ? Center(
                    child: EmptyStateWidget(
                      assetPath: 'assets/empty_state.png',
                      title: context.l10n.collectionEmptyStateTitle,
                      subtitle: context.l10n.collectionEmptyStateSubtitle,
                      showBorder: false,
                    ),
                  )
                : ItemListView(
                    key: ValueKey(_displayedFiles.length),
                    files: _displayedFiles,
                    selectedFiles: _selectedFiles,
                    scrollController: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    selectionEnabled: _isSelectionEnabled,
                  ),
          ),
        ),
      ],
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
}
