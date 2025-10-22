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
import 'package:locker/l10n/l10n.dart';
import 'package:locker/models/selected_files.dart';
import 'package:locker/services/collections/collections_service.dart';
import 'package:locker/services/collections/models/collection.dart';
import "package:locker/services/collections/models/collection_view_type.dart";
import "package:locker/services/configuration.dart";
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/ui/components/item_list_view.dart';
import "package:locker/ui/components/menu_item_widget.dart";
import 'package:locker/ui/components/search_result_view.dart';
import 'package:locker/ui/mixins/search_mixin.dart';
import 'package:locker/ui/pages/home_page.dart';
import 'package:locker/ui/pages/uploader_page.dart';
import "package:locker/ui/sharing/share_collection_bottom_sheet.dart";
import "package:locker/ui/viewer/actions/file_selection_overlay_bar.dart";
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

  late Collection _collection;
  List<EnteFile> _files = [];
  List<EnteFile> _filteredFiles = [];
  late CollectionViewType collectionViewType;
  bool isQuickLink = false;

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
        _logger.severe('Error updating collection', e);
      }
    });

    collectionViewType = getCollectionViewType(
      _collection,
      Configuration.instance.getUserID()!,
    );
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

      await showModalBottomSheet(
        context: context,
        backgroundColor: getEnteColorScheme(context).backgroundBase,
        isScrollControlled: true,
        builder: (context) => ShareCollectionBottomSheet(
          collection: collection,
        ),
      );
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
            FileSelectionOverlayBar(
              files: _displayedFiles,
              selectedFiles: _selectedFiles,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(EnteColorScheme colorScheme) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.strokeFaint),
      ),
      elevation: 15,
      padding: const EdgeInsetsGeometry.all(0),
      menuPadding: const EdgeInsets.all(0),
      shadowColor: Colors.black.withValues(alpha: 0.08),
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
        } else if (collectionViewType == CollectionViewType.sharedCollection) {
          totalItems = 1;
        }

        if (collectionViewType == CollectionViewType.ownedCollection ||
            collectionViewType == CollectionViewType.hiddenOwnedCollection ||
            collectionViewType == CollectionViewType.quickLink) {
          items.add(
            PopupMenuItem<String>(
              value: 'rename',
              height: 0,
              padding: EdgeInsets.zero,
              child: MenuItemWidget(
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
              child: MenuItemWidget(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  color: colorScheme.warning500,
                  size: 20,
                ),
                isDelete: true,
                label: context.l10n.delete,
                isFirst: itemIndex == 0,
                isLast: itemIndex == totalItems - 1,
              ),
            ),
          );
        }

        if (collectionViewType == CollectionViewType.sharedCollection) {
          items.add(
            PopupMenuItem<String>(
              value: 'leave_collection',
              padding: EdgeInsets.zero,
              height: 0,
              child: MenuItemWidget(
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
                title: _collection.name ?? context.l10n.untitled,
                trailingWidgets: widget.isUncategorized
                    ? const []
                    : [
                        GestureDetector(
                          onTap: () async {
                            await _shareCollection();
                          },
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
                        ),
                        const SizedBox(width: 8),
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
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: _displayedFiles.isEmpty
              ? SizedBox(
                  height: 400,
                  child: _buildEmptyState(textTheme),
                )
              : ItemListView(
                  key: ValueKey(_displayedFiles.length),
                  files: _displayedFiles,
                  selectedFiles: _selectedFiles,
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(EnteTextTheme textTheme) {
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
              style: textTheme.large.copyWith(
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            if (isSearchActive) ...[
              const SizedBox(height: 8),
              Text(
                context.l10n.tryAdjustingYourSearchQuery,
                style: textTheme.body.copyWith(
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
}
