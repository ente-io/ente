import 'package:flutter/material.dart';
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

class CollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final bool? hasVerifiedLock;
  final bool isFromCollectPhotos;

  CollectionPage(
    this.c, {
    this.tagPrefix = "collection",
    this.hasVerifiedLock = false,
    this.isFromCollectPhotos = false,
    super.key,
  });

  final _selectedFiles = SelectedFiles();

  @override
  Widget build(BuildContext context) {
    if (hasVerifiedLock == false && c.collection.isHidden()) {
      return const EmptyState();
    }

    final galleryType = getGalleryType(
      c.collection,
      Configuration.instance.getUserID()!,
    );
    final List<EnteFile>? initialFiles =
        c.thumbnail != null ? [c.thumbnail!] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final FileLoadResult result =
            await FilesDB.instance.getFilesInCollection(
          c.collection.id,
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
          .where((event) => event.collectionID == c.collection.id),
      forceReloadEvents: [
        Bus.instance.on<CollectionMetaEvent>().where(
              (event) =>
                  event.id == c.collection.id &&
                  event.type == CollectionMetaEventType.sortChanged,
            ),
      ],
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.hide,
      },
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: initialFiles,
      albumName: c.collection.displayName,
      sortAsyncFn: () => c.collection.pubMagicMetadata.asc ?? false,
      addHeaderOrFooterEmptyState: false,
      showSelectAll: galleryType != GalleryType.sharedCollection,
      emptyState: galleryType == GalleryType.ownedCollection
          ? EmptyAlbumState(
              c.collection,
              isFromCollectPhotos: isFromCollectPhotos,
              onAddPhotos: () {
                Bus.instance.fire(
                  CollectionMetaEvent(
                    c.collection.id,
                    CollectionMetaEventType.autoAddPeople,
                  ),
                );
              },
            )
          : const EmptyState(),
      footer: isFromCollectPhotos
          ? const SizedBox(height: 20)
          : const SizedBox(height: 212),
    );

    return GalleryFilesState(
      child: InheritedSearchFilterDataWrapper(
        searchFilterDataProvider: SearchFilterDataProvider(
          initialGalleryFilter: AlbumFilter(
            collectionID: c.collection.id,
            albumName: c.collection.displayName,
            occurrence: kMostRelevantFilter,
          ),
        ),
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(90.0),
            child: GalleryAppBarWidget(
              galleryType,
              c.collection.displayName,
              _selectedFiles,
              collection: c.collection,
              isFromCollectPhotos: isFromCollectPhotos,
            ),
          ),
          bottomNavigationBar: isFromCollectPhotos
              ? CollectPhotosBottomButtons(
                  c.collection,
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
                                tagPrefix: tagPrefix,
                                selectedFiles: _selectedFiles,
                              )
                            : gallery;
                      },
                    );
                  },
                ),
                SmartAlbumsStatusWidget(
                  collection: c.collection,
                ),
                FileSelectionOverlayBar(
                  galleryType,
                  _selectedFiles,
                  collection: c.collection,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
