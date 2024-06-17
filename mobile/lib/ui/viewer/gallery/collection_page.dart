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
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/gallery/empty_album_state.dart";
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class CollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final bool? hasVerifiedLock;

  CollectionPage(
    this.c, {
    this.tagPrefix = "collection",
    this.hasVerifiedLock = false,
    Key? key,
  }) : super(key: key);

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
      showSelectAllByDefault: galleryType != GalleryType.sharedCollection,
      emptyState: galleryType == GalleryType.ownedCollection
          ? EmptyAlbumState(c.collection)
          : const EmptyState(),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          galleryType,
          c.collection.displayName,
          _selectedFiles,
          collection: c.collection,
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            FileSelectionOverlayBar(
              galleryType,
              _selectedFiles,
              collection: c.collection,
            ),
          ],
        ),
      ),
    );
  }
}
