import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/events/collection_meta_event.dart";
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/models/collection/collection_items.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/actions/smart_albums_status_widget.dart";
import "package:photos/ui/viewer/gallery/collect_photos_bottom_buttons.dart";
import "package:photos/ui/viewer/gallery/empty_album_state.dart";
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart";
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class CollectionPage extends StatefulWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final bool? hasVerifiedLock;
  final bool isFromCollectPhotos;

  const CollectionPage(
    this.c, {
    this.tagPrefix = "collection",
    this.hasVerifiedLock = false,
    this.isFromCollectPhotos = false,
    super.key,
  });

  @override
  State<CollectionPage> createState() => _CollectionPageState();
}

class _CollectionPageState extends State<CollectionPage> {
  final _selectedFiles = SelectedFiles();
  bool _isCollapsed = false;
  bool _hasCollapsedOnce = false;
  bool _hasFilesSelected = false;
  Timer? _selectionTimer;

  @override
  void initState() {
    super.initState();
    _selectedFiles.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    final hasSelection = _selectedFiles.files.isNotEmpty;

    if (hasSelection && !_hasFilesSelected) {
      setState(() {
        _isCollapsed = false;
        _hasFilesSelected = true;
      });

      _selectionTimer?.cancel();
      _selectionTimer = Timer(const Duration(milliseconds: 10), () {});
    } else if (!hasSelection && _hasFilesSelected) {
      setState(() {
        _hasFilesSelected = false;
        _isCollapsed = false;
      });
      _selectionTimer?.cancel();
    }
  }

  @override
  void dispose() {
    _selectedFiles.removeListener(_onSelectionChanged);
    _selectionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasVerifiedLock == false && widget.c.collection.isHidden()) {
      return const EmptyState();
    }

    final galleryType = getGalleryType(
      widget.c.collection,
      Configuration.instance.getUserID()!,
    );
    final List<EnteFile>? initialFiles =
        widget.c.thumbnail != null ? [widget.c.thumbnail!] : null;

    final gallery = NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is UserScrollNotification && _hasFilesSelected) {
          final shouldAllowCollapse =
              _selectionTimer == null || !_selectionTimer!.isActive;

          if (shouldAllowCollapse &&
              (!_hasCollapsedOnce || !_isCollapsed) &&
              (scrollInfo.direction == ScrollDirection.forward ||
                  scrollInfo.direction == ScrollDirection.reverse)) {
            Future.delayed(const Duration(milliseconds: 10), () {
              if (mounted && _hasFilesSelected) {
                setState(() {
                  _isCollapsed = true;
                  _hasCollapsedOnce = true;
                });
              }
            });
          }
        }
        return false;
      },
      child: Gallery(
        asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
          final FileLoadResult result =
              await FilesDB.instance.getFilesInCollection(
            widget.c.collection.id,
            creationStartTime,
            creationEndTime,
            limit: limit,
            asc: asc,
          );
          // hide ignored files from home page UI
          final ignoredIDs =
              await IgnoredFilesService.instance.idToIgnoreReasonMap;
          result.files.removeWhere(
            (f) =>
                f.uploadedFileID == null &&
                IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
          );
          return result;
        },
        reloadEvent: Bus.instance
            .on<CollectionUpdatedEvent>()
            .where((event) => event.collectionID == widget.c.collection.id),
        forceReloadEvents: [
          Bus.instance.on<CollectionMetaEvent>().where(
                (event) =>
                    event.id == widget.c.collection.id &&
                    event.type == CollectionMetaEventType.sortChanged,
              ),
        ],
        removalEventTypes: const {
          EventType.deletedFromRemote,
          EventType.deletedFromEverywhere,
          EventType.hide,
        },
        tagPrefix: widget.tagPrefix,
        selectedFiles: _selectedFiles,
        initialFiles: initialFiles,
        albumName: widget.c.collection.displayName,
        sortAsyncFn: () => widget.c.collection.pubMagicMetadata.asc ?? false,
        addHeaderOrFooterEmptyState: false,
        showSelectAll: galleryType != GalleryType.sharedCollection,
        emptyState: galleryType == GalleryType.ownedCollection
            ? EmptyAlbumState(
                widget.c.collection,
                isFromCollectPhotos: widget.isFromCollectPhotos,
                onAddPhotos: () {
                  Bus.instance.fire(
                    CollectionMetaEvent(
                      widget.c.collection.id,
                      CollectionMetaEventType.autoAddPeople,
                    ),
                  );
                },
              )
            : const EmptyState(),
        footer: widget.isFromCollectPhotos
            ? const SizedBox(height: 20)
            : const SizedBox(height: 212),
      ),
    );

    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: SearchFilterDataProvider(
          initialGalleryFilter: AlbumFilter(
            collectionID: widget.c.collection.id,
            albumName: widget.c.collection.displayName,
            occurrence: kMostRelevantFilter,
          ),
        ),
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              galleryType,
              widget.c.collection.displayName,
              _selectedFiles,
              collection: widget.c.collection,
              isFromCollectPhotos: widget.isFromCollectPhotos,
            ),
          ),
          bottomNavigationBar: widget.isFromCollectPhotos
              ? CollectPhotosBottomButtons(
                  widget.c.collection,
                  selectedFiles: _selectedFiles,
                )
              : null,
          body: SelectionState(
            selectedFiles: _selectedFiles,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Builder(
                  builder: (context) {
                    return ValueListenableBuilder(
                      valueListenable: InheritedSearchFilterData.of(context)
                          .searchFilterDataProvider!
                          .isSearchingNotifier,
                      builder: (context, value, _) {
                        return value
                            ? HierarchicalSearchGallery(
                                tagPrefix: widget.tagPrefix,
                                selectedFiles: _selectedFiles,
                              )
                            : gallery;
                      },
                    );
                  },
                ),
                SmartAlbumsStatusWidget(
                  collection: widget.c.collection,
                ),
                FileSelectionOverlayBar(
                  galleryType,
                  _selectedFiles,
                  collection: widget.c.collection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
