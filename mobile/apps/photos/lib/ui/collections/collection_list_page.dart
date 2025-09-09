import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import "package:flutter_svg/flutter_svg.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/album_sort_order_change_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/collection/collection_items.dart';
import "package:photos/models/selected_albums.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/collections/flex_grid_view.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/searchable_appbar.dart";
import "package:photos/ui/viewer/actions/album_selection_overlay_bar.dart";
import "package:photos/utils/local_settings.dart";

enum UISectionType {
  incomingCollections,
  outgoingCollections,
  homeCollections,
}

class CollectionListPage extends StatefulWidget {
  final List<Collection>? collections;
  final Widget? appTitle;
  final double? initialScrollOffset;
  final String tag;
  final UISectionType sectionType;

  const CollectionListPage(
    this.collections, {
    required this.sectionType,
    this.appTitle,
    this.initialScrollOffset,
    this.tag = "",
    super.key,
  });

  @override
  State<CollectionListPage> createState() => _CollectionListPageState();
}

class _CollectionListPageState extends State<CollectionListPage> {
  late StreamSubscription<CollectionUpdatedEvent>
      _collectionUpdatesSubscription;
  List<Collection>? collections;
  AlbumSortKey? sortKey;
  AlbumViewType? albumViewType;
  AlbumSortDirection? albumSortDirection;
  String _searchQuery = "";
  final _selectedAlbum = SelectedAlbums();
  late final ScrollController _scrollController;

  bool _isCollapsed = false;
  bool _hasCollapsedOnce = false;
  bool _hasAlbumsSelected = false;
  Timer? _selectionTimer;

  @override
  void initState() {
    super.initState();
    collections = widget.collections;
    _collectionUpdatesSubscription =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) async {
      unawaited(refreshCollections());
    });
    sortKey = localSettings.albumSortKey();
    albumViewType = localSettings.albumViewType();
    albumSortDirection = localSettings.albumSortDirection();
    _scrollController = ScrollController(
      initialScrollOffset: widget.initialScrollOffset ?? 0,
    );
    _selectedAlbum.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final hasSelection = _selectedAlbum.albums.isNotEmpty;

    if (hasSelection && !_hasAlbumsSelected) {
      setState(() {
        _isCollapsed = false;
        _hasAlbumsSelected = true;
      });

      _selectionTimer?.cancel();
      _selectionTimer = Timer(const Duration(milliseconds: 10), () {});
    } else if (!hasSelection && _hasAlbumsSelected) {
      setState(() {
        _hasAlbumsSelected = false;
        _isCollapsed = false;
      });
      _selectionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _collectionUpdatesSubscription.cancel();
    _scrollController.dispose();
    _selectedAlbum.removeListener(_onSelectionChanged);
    _selectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayLimitCount = (collections?.length ?? 0) +
        (widget.tag.isEmpty && _searchQuery.isEmpty ? 1 : 0);
    final bool enableSelectionMode =
        widget.sectionType == UISectionType.homeCollections ||
            widget.sectionType == UISectionType.outgoingCollections ||
            widget.sectionType == UISectionType.incomingCollections;
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            NotificationListener<ScrollNotification>(
              onNotification: (scrollInfo) {
                if (scrollInfo is UserScrollNotification &&
                    _hasAlbumsSelected) {
                  final shouldAllowCollapse =
                      _selectionTimer == null || !_selectionTimer!.isActive;

                  if (shouldAllowCollapse &&
                      (!_hasCollapsedOnce || !_isCollapsed) &&
                      (scrollInfo.direction == ScrollDirection.forward ||
                          scrollInfo.direction == ScrollDirection.reverse)) {
                    if (mounted && _hasAlbumsSelected) {
                      setState(() {
                        _isCollapsed = true;
                        _hasCollapsedOnce = true;
                      });
                    }
                  }
                }
                return false;
              },
              child: Scrollbar(
                interactive: true,
                controller: _scrollController,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  controller: _scrollController,
                  slivers: [
                    SearchableAppBar(
                      title: widget.appTitle ?? const SizedBox.shrink(),
                      heroTag: widget.tag,
                      onSearch: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        refreshCollections();
                      },
                      onSearchClosed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        refreshCollections();
                      },
                      actions: [
                        _sortMenu(collections!),
                      ],
                    ),
                    CollectionsFlexiGridViewWidget(
                      collections,
                      displayLimitCount: displayLimitCount,
                      tag: widget.tag,
                      enableSelectionMode: enableSelectionMode,
                      albumViewType: albumViewType ?? AlbumViewType.grid,
                      selectedAlbums: _selectedAlbum,
                    ),
                  ],
                ),
              ),
            ),
            AlbumSelectionOverlayBar(
              _selectedAlbum,
              widget.sectionType,
              collections!,
              showSelectAllButton: true,
              isCollapsed: _isCollapsed,
              onExpand: () {
                setState(() {
                  _isCollapsed = false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sortMenu(List<Collection> collections) {
    final colorTheme = getEnteColorScheme(context);
    final isLightMode = Theme.of(context).brightness == Brightness.light;
    Widget sortOptionText(AlbumSortKey key) {
      String text = key.toString();
      switch (key) {
        case AlbumSortKey.albumName:
          text = S.of(context).name;
          break;
        case AlbumSortKey.newestPhoto:
          text = S.of(context).newest;
          break;
        case AlbumSortKey.lastUpdated:
          text = S.of(context).lastUpdated;
      }
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            text,
          ),
          Icon(
            sortKey == key
                ? (albumSortDirection == AlbumSortDirection.ascending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward)
                : null,
            size: 18,
          ),
        ],
      );
    }

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              setState(() {
                albumViewType = albumViewType == AlbumViewType.grid
                    ? AlbumViewType.list
                    : AlbumViewType.grid;
              });
              await localSettings.setAlbumViewType(albumViewType!);
            },
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                height: 24,
                width: 24,
                child: albumViewType == AlbumViewType.grid
                    ? SvgPicture.asset(
                        isLightMode
                            ? "assets/icons/list_view_icon_light.svg"
                            : "assets/icons/list_view_icon_dark.svg",
                      )
                    : Icon(
                        Icons.grid_view,
                        color: colorTheme.textMuted,
                        size: 22,
                      ),
              ),
            ),
          ),
          GestureDetector(
            onTapDown: (TapDownDetails details) async {
              final int? selectedValue = await showMenu<int>(
                color: colorTheme.backgroundElevated,
                context: context,
                position: RelativeRect.fromLTRB(
                  details.globalPosition.dx,
                  details.globalPosition.dy,
                  details.globalPosition.dx,
                  details.globalPosition.dy + 50,
                ),
                items: List.generate(AlbumSortKey.values.length, (index) {
                  return PopupMenuItem(
                    value: index,
                    child: sortOptionText(AlbumSortKey.values[index]),
                  );
                }),
              );
              if (selectedValue != null) {
                sortKey = AlbumSortKey.values[selectedValue];
                await localSettings.setAlbumSortKey(sortKey!);
                albumSortDirection =
                    albumSortDirection == AlbumSortDirection.ascending
                        ? AlbumSortDirection.descending
                        : AlbumSortDirection.ascending;
                await localSettings.setAlbumSortDirection(albumSortDirection!);
                await refreshCollections();
                Bus.instance.fire(AlbumSortOrderChangeEvent());
              }
            },
            child: IconButtonWidget(
              icon: Icons.sort_rounded,
              iconButtonType: IconButtonType.secondary,
              iconColor: colorTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> refreshCollections() async {
    if (widget.sectionType == UISectionType.incomingCollections ||
        widget.sectionType == UISectionType.outgoingCollections) {
      final SharedCollections sharedCollections =
          await CollectionsService.instance.getSharedCollections();
      if (widget.sectionType == UISectionType.incomingCollections) {
        collections = sharedCollections.incoming;
      } else {
        collections = sharedCollections.outgoing;
      }
      if (_searchQuery.isNotEmpty) {
        collections = widget.collections
            ?.where(
              (c) => c.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }
    } else if (widget.sectionType == UISectionType.homeCollections) {
      collections =
          await CollectionsService.instance.getCollectionForOnEnteSection();
      if (_searchQuery.isNotEmpty) {
        collections = widget.collections
            ?.where(
              (c) => c.displayName
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
            )
            .toList();
      }
    }
    if (mounted) {
      setState(() {});
    }
  }
}
