import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/collection_meta_event.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class SharedPublicCollectionPage extends StatelessWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final List<EnteFile>? files;

  SharedPublicCollectionPage(
    this.c, {
    this.tagPrefix = "shared_public_collection",
    super.key,
    this.files,
  }) : assert(
          !(files == null),
          'sharedLinkFiles cannot be empty',
        );

  final _selectedFiles = SelectedFiles();

  @override
  Widget build(BuildContext context) {
    final bool isPublicDownload = c.collection.isPublicDownload();
    final bool isisEnableCollect = c.collection.isEnableCollect();
    final galleryType = getGalleryType(
      c.collection,
      Configuration.instance.getUserID()!,
    );
    final List<EnteFile>? initialFiles =
        c.thumbnail != null ? [c.thumbnail!] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        return FileLoadResult(files!, false);
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
      showSelectAllByDefault: galleryType != GalleryType.sharedPublicCollection,
    );

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          galleryType,
          c.collection.displayName,
          _selectedFiles,
          collection: c.collection,
          files: files,
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            !isPublicDownload && !isisEnableCollect
                ? const SizedBox.shrink()
                : FileSelectionOverlayBar(
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
