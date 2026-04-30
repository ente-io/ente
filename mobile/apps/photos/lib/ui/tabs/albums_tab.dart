import "dart:async";
import "dart:math" as math;

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/album_sort_order_change_event.dart";
import "package:photos/events/app_mode_changed_event.dart";
import "package:photos/events/backup_folders_updated_event.dart";
import "package:photos/events/collection_meta_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/favorites_service_init_complete_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/events/user_logged_out_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/selected_albums.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/collection_list_page.dart";
import "package:photos/ui/collections/device/device_folders_vertical_grid_view.dart";
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/filter_pill_widget.dart";
import "package:photos/ui/components/buttons/soft_icon_button.dart";
import "package:photos/ui/components/text_input_widget_v2.dart";
import "package:photos/ui/tabs/albums/albums_manage_sheet.dart";
import "package:photos/ui/viewer/actions/album_selection_overlay_bar.dart";
import "package:photos/utils/local_settings.dart";

enum _AlbumsFilter { ente, onDevice, shared }

enum _AlbumsMenuAction { toggleView, name, created, updated }

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key, this.selectedAlbums});

  final SelectedAlbums? selectedAlbums;

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab>
    with AutomaticKeepAliveClientMixin {
  static const double _kHeaderToolbarHeight = 72;

  final ValueNotifier<_AlbumsFilter> _filter =
      ValueNotifier(_AlbumsFilter.ente);
  final ValueNotifier<List<Collection>?> _enteCollections = ValueNotifier(null);
  final ValueNotifier<List<Collection>?> _sharedCollections =
      ValueNotifier(null);
  late final ValueNotifier<AlbumViewType> _viewType =
      ValueNotifier(localSettings.albumViewType());
  late final ValueNotifier<AlbumSortKey> _sortKey =
      ValueNotifier(localSettings.albumSortKey());
  late final ValueNotifier<AlbumSortDirection> _sortDirection =
      ValueNotifier(localSettings.albumSortDirection());
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSearchActive = false;
  String _searchQuery = "";

  late final StreamSubscription<CollectionMetaEvent>
      _collectionMetaEventSubscription;
  late final StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  late final StreamSubscription<LocalPhotosUpdatedEvent>
      _localFilesSubscription;
  late final StreamSubscription<FavoritesServiceInitCompleteEvent>
      _favoritesInitComplete;
  late final StreamSubscription<AlbumSortOrderChangeEvent>
      _albumSortOrderChangeEvent;
  late final StreamSubscription<BackupFoldersUpdatedEvent>
      _backupFoldersUpdatedEvent;
  late final StreamSubscription<AppModeChangedEvent> _appModeChangedEvent;
  late final StreamSubscription<UserLoggedOutEvent> _loggedOutEvent;

  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 5),
    leading: true,
  );

  @override
  void initState() {
    super.initState();
    unawaited(_loadAll());

    _collectionMetaEventSubscription =
        Bus.instance.on<CollectionMetaEvent>().listen((_) {
      _debouncer.run(_loadAll);
    });
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((_) {
      _debouncer.run(_loadAll);
    });
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((_) {
      _debouncer.run(_loadAll);
    });
    _albumSortOrderChangeEvent =
        Bus.instance.on<AlbumSortOrderChangeEvent>().listen((_) {
      _syncSortState();
      unawaited(_loadAll());
    });
    _favoritesInitComplete =
        Bus.instance.on<FavoritesServiceInitCompleteEvent>().listen((_) {
      _debouncer.run(_loadAll);
    });
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((_) {
      if (mounted) {
        setState(() {});
      }
      _debouncer.run(_loadAll);
    });
    _appModeChangedEvent = Bus.instance.on<AppModeChangedEvent>().listen((_) {
      if (mounted) {
        setState(() {});
      }
      _debouncer.run(_loadAll);
    });
    _loggedOutEvent = Bus.instance.on<UserLoggedOutEvent>().listen((_) {
      _enteCollections.value = null;
      _sharedCollections.value = null;
    });
  }

  Future<void> _loadAll() async {
    await Future.wait([_loadEnteCollections(), _loadSharedCollections()]);
  }

  void _syncSortState() {
    _sortKey.value = localSettings.albumSortKey();
    _sortDirection.value = localSettings.albumSortDirection();
    _viewType.value = localSettings.albumViewType();
  }

  Future<void> _loadEnteCollections() async {
    final collections =
        await CollectionsService.instance.getCollectionForOnEnteSection();
    if (!mounted) return;
    _enteCollections.value = collections;
  }

  Future<void> _loadSharedCollections() async {
    final shared = await CollectionsService.instance.getSharedCollections();
    if (!mounted) return;
    _sharedCollections.value = shared.incoming;
  }

  void _selectFilter(_AlbumsFilter filter) {
    if (_filter.value == filter) return;
    widget.selectedAlbums?.clearAll();
    _filter.value = filter;
  }

  void _activateSearch() {
    if (_isSearchActive) return;
    setState(() {
      _isSearchActive = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _deactivateSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    if (!_isSearchActive && _searchQuery.isEmpty) return;
    setState(() {
      _isSearchActive = false;
      _searchQuery = "";
    });
  }

  List<Collection> _filterCollectionsByQuery(List<Collection> collections) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return collections;
    }
    return collections
        .where((c) => c.displayName.toLowerCase().contains(query))
        .toList();
  }

  Future<void> _toggleViewMode() async {
    final next = _viewType.value == AlbumViewType.grid
        ? AlbumViewType.list
        : AlbumViewType.grid;
    _viewType.value = next;
    await localSettings.setAlbumViewType(next);
  }

  Future<void> _setSortMode(AlbumSortKey key) async {
    AlbumSortDirection nextDirection;
    if (_sortKey.value == key) {
      nextDirection = _sortDirection.value == AlbumSortDirection.ascending
          ? AlbumSortDirection.descending
          : AlbumSortDirection.ascending;
    } else if (key == AlbumSortKey.albumName) {
      nextDirection = AlbumSortDirection.ascending;
    } else {
      nextDirection = AlbumSortDirection.descending;
    }

    _sortKey.value = key;
    _sortDirection.value = nextDirection;
    await localSettings.setAlbumSortKey(key);
    await localSettings.setAlbumSortDirection(nextDirection);
    if (mounted) {
      Bus.instance.fire(AlbumSortOrderChangeEvent());
    }
  }

  Widget _buildAlbumsMenuRow({
    required String label,
    required TextStyle labelStyle,
    required TextStyle secondaryStyle,
    required Color indicatorColor,
    String? secondaryLabel,
    bool isActive = false,
  }) {
    final Widget title = secondaryLabel == null
        ? Text(label, style: labelStyle)
        : Row(
            children: [
              Text(label, style: labelStyle),
              const SizedBox(width: 6),
              Text("•", style: secondaryStyle),
              const SizedBox(width: 6),
              Text(secondaryLabel, style: secondaryStyle),
            ],
          );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        title,
        if (isActive)
          HugeIcon(
            icon: _sortDirection.value == AlbumSortDirection.ascending
                ? HugeIcons.strokeRoundedArrowUp02
                : HugeIcons.strokeRoundedArrowDown02,
            size: 12,
            color: indicatorColor,
          ),
      ],
    );
  }

  Future<void> _showAlbumsMenu(TapDownDetails details) async {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final strings = AppLocalizations.of(context);
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);
    final left = math.max(16.0, details.globalPosition.dx - 164);
    final top = details.globalPosition.dy + 12;
    final right = math.max(
      16.0,
      overlaySize.width - details.globalPosition.dx - 24,
    );
    final isListView = _viewType.value == AlbumViewType.list;
    final currentSortKey = _sortKey.value;

    PopupMenuItem<_AlbumsMenuAction> item({
      required _AlbumsMenuAction value,
      required Widget child,
      bool showDivider = true,
    }) {
      return PopupMenuItem<_AlbumsMenuAction>(
        value: value,
        padding: EdgeInsets.zero,
        height: 52,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(
                    bottom: BorderSide(color: colorScheme.strokeFaint),
                  )
                : null,
          ),
          child: child,
        ),
      );
    }

    final selected = await showMenu<_AlbumsMenuAction>(
      context: context,
      color: colorScheme.fill,
      elevation: 8,
      constraints: const BoxConstraints.tightFor(width: 196),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: colorScheme.strokeFaint),
      ),
      position: RelativeRect.fromLTRB(
        left,
        top,
        right,
        overlaySize.height - top,
      ),
      items: [
        item(
          value: _AlbumsMenuAction.toggleView,
          child: _buildAlbumsMenuRow(
            label: isListView ? strings.grid : strings.list,
            labelStyle: textTheme.mini,
            secondaryStyle: textTheme.miniMuted,
            indicatorColor: colorScheme.textMuted,
          ),
        ),
        item(
          value: _AlbumsMenuAction.name,
          child: _buildAlbumsMenuRow(
            label: strings.name,
            secondaryLabel: currentSortKey == AlbumSortKey.albumName
                ? (_sortDirection.value == AlbumSortDirection.ascending
                    ? strings.sortAToZ
                    : strings.sortZToA)
                : null,
            isActive: currentSortKey == AlbumSortKey.albumName,
            labelStyle: textTheme.mini,
            secondaryStyle: textTheme.miniMuted,
            indicatorColor: colorScheme.textMuted,
          ),
        ),
        item(
          value: _AlbumsMenuAction.created,
          child: _buildAlbumsMenuRow(
            label: strings.created,
            isActive: currentSortKey == AlbumSortKey.newestPhoto,
            labelStyle: textTheme.mini,
            secondaryStyle: textTheme.miniMuted,
            indicatorColor: colorScheme.textMuted,
          ),
        ),
        item(
          value: _AlbumsMenuAction.updated,
          showDivider: false,
          child: _buildAlbumsMenuRow(
            label: strings.updated,
            isActive: currentSortKey == AlbumSortKey.lastUpdated,
            labelStyle: textTheme.mini,
            secondaryStyle: textTheme.miniMuted,
            indicatorColor: colorScheme.textMuted,
          ),
        ),
      ],
    );

    switch (selected) {
      case _AlbumsMenuAction.toggleView:
        await _toggleViewMode();
        break;
      case _AlbumsMenuAction.name:
        await _setSortMode(AlbumSortKey.albumName);
        break;
      case _AlbumsMenuAction.created:
        await _setSortMode(AlbumSortKey.newestPhoto);
        break;
      case _AlbumsMenuAction.updated:
        await _setSortMode(AlbumSortKey.lastUpdated);
        break;
      case null:
        break;
    }
  }

  @override
  void dispose() {
    _collectionMetaEventSubscription.cancel();
    _collectionUpdatesSubscription.cancel();
    _localFilesSubscription.cancel();
    _favoritesInitComplete.cancel();
    _albumSortOrderChangeEvent.cancel();
    _backupFoldersUpdatedEvent.cancel();
    _appModeChangedEvent.cancel();
    _loggedOutEvent.cancel();
    _debouncer.cancelDebounceTimer();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _filter.dispose();
    _enteCollections.dispose();
    _sharedCollections.dispose();
    _viewType.dispose();
    _sortKey.dispose();
    _sortDirection.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final strings = AppLocalizations.of(context);
    final selectedAlbums = widget.selectedAlbums;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  height: _kHeaderToolbarHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          layoutBuilder: (currentChild, previousChildren) =>
                              Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          ),
                          transitionBuilder: (child, animation) {
                            final curvedAnimation = CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeOutCubic,
                              reverseCurve: Curves.easeInCubic,
                            );
                            final beginOffset =
                                child.key == const ValueKey("search_title")
                                    ? const Offset(0.04, 0)
                                    : const Offset(-0.04, 0);
                            return FadeTransition(
                              opacity: curvedAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: beginOffset,
                                  end: Offset.zero,
                                ).animate(curvedAnimation),
                                child: child,
                              ),
                            );
                          },
                          child: _isSearchActive
                              ? Row(
                                  key: const ValueKey("search_title"),
                                  children: [
                                    Expanded(
                                      child: TextInputWidgetV2(
                                        textEditingController:
                                            _searchController,
                                        focusNode: _searchFocusNode,
                                        hintText: strings.searchAlbums,
                                        autoFocus: true,
                                        shouldSurfaceExecutionStates: false,
                                        leadingWidget: HugeIcon(
                                          icon: HugeIcons.strokeRoundedSearch01,
                                          size: 18,
                                          color: colorScheme.textMuted,
                                        ),
                                        trailingWidget: GestureDetector(
                                          onTap: _deactivateSearch,
                                          child: HugeIcon(
                                            icon:
                                                HugeIcons.strokeRoundedCancel01,
                                            size: 12,
                                            color: colorScheme.textMuted,
                                          ),
                                        ),
                                        onChange: (value) {
                                          setState(() {
                                            _searchQuery = value;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    SoftIconButton(
                                      icon: HugeIcon(
                                        icon: HugeIcons
                                            .strokeRoundedFilterHorizontal,
                                        size: 18,
                                        color: colorScheme.textBase,
                                      ),
                                      onTap: () => showAlbumsManageSheet(
                                        context,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  strings.albums,
                                  key: const ValueKey("albums_title"),
                                  style: textTheme.h4Bold,
                                ),
                        ),
                      ),
                      if (!_isSearchActive) ...[
                        SoftIconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSearch01,
                            size: 18,
                            color: colorScheme.textBase,
                          ),
                          onTap: _activateSearch,
                        ),
                        const SizedBox(width: 6),
                        SoftIconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedFilterHorizontal,
                            size: 18,
                            color: colorScheme.textBase,
                          ),
                          onTap: () => showAlbumsManageSheet(context),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Row(
                  children: [
                    Expanded(
                      child: ValueListenableBuilder<_AlbumsFilter>(
                        valueListenable: _filter,
                        builder: (context, selected, _) => Row(
                          children: [
                            FilterPillWidget(
                              label: strings.ente,
                              selected: selected == _AlbumsFilter.ente,
                              onTap: () => _selectFilter(_AlbumsFilter.ente),
                            ),
                            const SizedBox(width: 8),
                            FilterPillWidget(
                              label: strings.onDevice,
                              selected: selected == _AlbumsFilter.onDevice,
                              onTap: () =>
                                  _selectFilter(_AlbumsFilter.onDevice),
                            ),
                            const SizedBox(width: 8),
                            FilterPillWidget(
                              label: strings.searchResultShared,
                              selected: selected == _AlbumsFilter.shared,
                              onTap: () => _selectFilter(_AlbumsFilter.shared),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SoftIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedMoreVertical,
                        size: 18,
                        color: colorScheme.textBase,
                      ),
                      onTap: () {},
                      onTapDown: _showAlbumsMenu,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    AnimatedBuilder(
                      animation: Listenable.merge(
                        [
                          _filter,
                          _enteCollections,
                          _sharedCollections,
                          _viewType,
                        ],
                      ),
                      builder: (context, _) {
                        final filter = _filter.value;
                        final List<Collection>? collections;
                        final bool showCreateAlbum;
                        switch (filter) {
                          case _AlbumsFilter.ente:
                            collections = _enteCollections.value;
                            showCreateAlbum = true;
                          case _AlbumsFilter.shared:
                            collections = _sharedCollections.value;
                            showCreateAlbum = false;
                          case _AlbumsFilter.onDevice:
                            return DeviceFolderVerticalGridSliver(
                              searchQuery: _searchQuery,
                            );
                        }
                        if (collections == null) {
                          return const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: EnteLoadingWidget(),
                            ),
                          );
                        }
                        final filteredCollections = _filterCollectionsByQuery(
                          collections,
                        );
                        return CollectionsFlexiGridViewWidget(
                          filteredCollections,
                          albumViewType: _viewType.value,
                          selectedAlbums: widget.selectedAlbums,
                          shrinkWrap: true,
                          shouldShowCreateAlbum:
                              showCreateAlbum && _searchQuery.trim().isEmpty,
                          enableSelectionMode: true,
                        );
                      },
                    ),
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: 64 + MediaQuery.paddingOf(context).bottom,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (selectedAlbums != null)
          AnimatedBuilder(
            animation: Listenable.merge(
              [_filter, _enteCollections, _sharedCollections],
            ),
            builder: (context, _) {
              final filter = _filter.value;
              final UISectionType sectionType;
              final List<Collection>? collections;
              switch (filter) {
                case _AlbumsFilter.ente:
                  sectionType = UISectionType.homeCollections;
                  collections = _enteCollections.value;
                case _AlbumsFilter.shared:
                  sectionType = UISectionType.incomingCollections;
                  collections = _sharedCollections.value;
                case _AlbumsFilter.onDevice:
                  return const SizedBox.shrink();
              }
              if (collections == null) return const SizedBox.shrink();
              final filteredCollections =
                  _filterCollectionsByQuery(collections);
              if (filteredCollections.isEmpty) return const SizedBox.shrink();
              return AlbumSelectionOverlayBar(
                selectedAlbums,
                sectionType,
                filteredCollections,
                showSelectAllButton: true,
              );
            },
          ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
