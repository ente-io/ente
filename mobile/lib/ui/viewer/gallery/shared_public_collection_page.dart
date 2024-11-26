import "package:flutter/material.dart";
import "package:logging/logging.dart";
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
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class SharedPublicCollectionPage extends StatefulWidget {
  final CollectionWithThumbnail c;
  final String tagPrefix;
  final List<EnteFile>? files;

  const SharedPublicCollectionPage(
    this.c, {
    this.tagPrefix = "shared_public_collection",
    super.key,
    this.files,
  }) : assert(
          !(files == null),
          'sharedLinkFiles cannot be empty',
        );

  @override
  State<SharedPublicCollectionPage> createState() =>
      _SharedPublicCollectionPageState();
}

class _SharedPublicCollectionPageState
    extends State<SharedPublicCollectionPage> {
  final _selectedFiles = SelectedFiles();
  final galleryType = GalleryType.sharedPublicCollection;

  @override
  void dispose() {
    _selectedFiles.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logger = Logger("SharedPublicCollectionPage");
    logger.info("Building SharedPublicCollectionPage");
    final bool isPublicDownload =
        widget.c.collection.isDownloadEnabledForPublicLink();
    final bool isisEnableCollect =
        widget.c.collection.isCollectEnabledForPublicLink();
    final List<EnteFile>? initialFiles =
        widget.c.thumbnail != null ? [widget.c.thumbnail!] : null;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        widget.files!.sort(
          (a, b) => a.creationTime!.compareTo(b.creationTime!),
        );

        return FileLoadResult(widget.files!, false);
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
    );

    return GalleryFilesState(
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(50.0),
          child: GalleryAppBarWidget(
            galleryType,
            widget.c.collection.displayName,
            _selectedFiles,
            collection: widget.c.collection,
            files: widget.files,
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
                      collection: widget.c.collection,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}