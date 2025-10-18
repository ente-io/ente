import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_meta_event.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/search/hierarchical/album_filter.dart";
import "package:photos/models/search/hierarchical/hierarchical_search_filter.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/hierarchical_search_gallery.dart";
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/gallery/state/search_filter_data_provider.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class UnCategorizedPage extends StatefulWidget {
  final String tagPrefix;
  final Collection collection;
  final GalleryType appBarType;
  final GalleryType overlayType;

  const UnCategorizedPage(
    this.collection, {
    this.tagPrefix = "Uncategorized_page",
    this.appBarType = GalleryType.uncategorized,
    this.overlayType = GalleryType.uncategorized,
    super.key,
  });

  @override
  State<UnCategorizedPage> createState() => _UnCategorizedPageState();
}

class _UnCategorizedPageState extends State<UnCategorizedPage> {
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
            widget.collection.id,
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
            .where((event) => event.collectionID == widget.collection.id),
        removalEventTypes: const {
          EventType.deletedFromRemote,
          EventType.deletedFromEverywhere,
          EventType.hide,
        },
        forceReloadEvents: [
          Bus.instance.on<CollectionMetaEvent>().where(
                (event) =>
                    event.id == widget.collection.id &&
                    event.type == CollectionMetaEventType.sortChanged,
              ),
        ],
        tagPrefix: widget.tagPrefix,
        selectedFiles: _selectedFiles,
        sortAsyncFn: () => widget.collection.pubMagicMetadata.asc ?? false,
        initialFiles: null,
        albumName: AppLocalizations.of(context).uncategorized,
      ),
    );
    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: SearchFilterDataProvider(
          initialGalleryFilter: AlbumFilter(
            collectionID: widget.collection.id,
            albumName: widget.collection.displayName,
            occurrence: kMostRelevantFilter,
          ),
        ),
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              widget.appBarType,
              AppLocalizations.of(context).uncategorized,
              _selectedFiles,
              collection: widget.collection,
            ),
          ),
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
                      builder: (context, isSearching, _) {
                        return isSearching
                            ? HierarchicalSearchGallery(
                                tagPrefix: widget.tagPrefix,
                                selectedFiles: _selectedFiles,
                              )
                            : gallery;
                      },
                    );
                  },
                ),
                FileSelectionOverlayBar(
                  widget.overlayType,
                  _selectedFiles,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
