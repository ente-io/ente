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
import "package:locker/ui/components/empty_state_widget.dart";
import 'package:locker/ui/components/item_list_view.dart';
import "package:locker/ui/components/popup_menu_item_widget.dart";
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import "package:locker/ui/sharing/share_collection_bottom_sheet.dart";
import 'package:locker/utils/collection_actions.dart';
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
  bool _isCollectionDeleted = false;
  bool _isDeletingCollection = false;
  bool _ignoreCollectionUpdates = false;

  late Collection _collection;
  List<EnteFile> _files = [];
  List<EnteFile> _filteredFiles = [];
  late CollectionViewType collectionViewType;
  bool isQuickLink = false;
  bool isFavorite = false;

  final _selectedFiles = SelectedFiles();

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
      if (_ignoreCollectionUpdates || _isCollectionDeleted) {
        return;
      }
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
          if (!_isCollectionDeleted && mounted) {
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

  Future<void> _deleteCollection() async {
    if (_isDeletingCollection) {
      return;
    }
    _isDeletingCollection = true;
    _ignoreCollectionUpdates = true;
    var didDelete = false;
    try {
      await CollectionActions.deleteCollection(
        context,
        _collection,
        onSuccess: () {
          didDelete = true;
          _isCollectionDeleted = true;
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    } finally {
      if (!didDelete) {
        _ignoreCollectionUpdates = false;
      }
      _isDeletingCollection = false;
    }
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

      await showModalBottomSheet(
        context: context,
        backgroundColor: getEnteColorScheme(context).backgroundBase,
        isScrollControlled: true,
        builder: (context) => ShareCollectionBottomSheet(
          collection: _collection,
        ),
      );
      // Refresh state after share sheet closes
      if (mounted) {
        setState(() {});
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
            // TODO(aman): Re-enable file multi-select overlay when bulk actions return.
            // FileSelectionOverlayBar(
            //   files: _displayedFiles,
            //   selectedFiles: _selectedFiles,
            // ),
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
        height: 48,
        width: 48,
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
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.strokeFaint),
      ),
      color: colorScheme.backdropBase,
      surfaceTintColor: Colors.transparent,
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      elevation: 15,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      constraints: const BoxConstraints(minWidth: 120),
      offset: const Offset(-36, 36),
      child: Container(
        height: 48,
        width: 48,
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
        final items = <PopupMenuItem<String>>[];
        var itemIndex = 0;
        var totalItems = 0;

        if (collectionViewType == CollectionViewType.ownedCollection ||
            collectionViewType == CollectionViewType.hiddenOwnedCollection ||
            collectionViewType == CollectionViewType.quickLink) {
          totalItems = 2;
        } else if (collectionViewType ==
                CollectionViewType.sharedCollectionViewer ||
            collectionViewType ==
                CollectionViewType.sharedCollectionCollaborator) {
          totalItems = 1;
        }

        if (collectionViewType == CollectionViewType.ownedCollection ||
            collectionViewType == CollectionViewType.hiddenOwnedCollection ||
            collectionViewType == CollectionViewType.quickLink) {
          items.add(
            PopupMenuItem<String>(
              value: 'edit',
              height: 0,
              padding: EdgeInsets.zero,
              child: PopupMenuItemWidget(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPencilEdit02,
                  color: colorScheme.textBase,
                  size: 20,
                ),
                label: context.l10n.edit,
                isFirst: itemIndex == 0,
                isLast: itemIndex == totalItems - 1,
              ),
            ),
          );
          itemIndex++;

          items.add(
            PopupMenuItem<String>(
              value: 'delete',
              padding: EdgeInsets.zero,
              height: 0,
              child: PopupMenuItemWidget(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: colorScheme.warning500,
                  size: 20,
                ),
                isWarning: true,
                label: context.l10n.delete,
                isFirst: itemIndex == 0,
                isLast: itemIndex == totalItems - 1,
              ),
            ),
          );
        }

        if (collectionViewType == CollectionViewType.sharedCollectionViewer ||
            collectionViewType ==
                CollectionViewType.sharedCollectionCollaborator) {
          items.add(
            PopupMenuItem<String>(
              value: 'leave_collection',
              padding: EdgeInsets.zero,
              height: 0,
              child: PopupMenuItemWidget(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: colorScheme.textBase,
                  size: 20,
                ),
                label: context.l10n.leaveCollection,
                isFirst: true,
                isLast: true,
              ),
            ),
          );
        }

        return items;
      },
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
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
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
                    // TODO(aman): pass selectedFiles when multi-select returns.
                    selectedFiles: null,
                    physics: const BouncingScrollPhysics(),
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
