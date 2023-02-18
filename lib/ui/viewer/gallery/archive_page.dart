import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/models/collection_items.dart";
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/ui/collections/collection_item_widget.dart";
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';

class ArchivePage extends StatelessWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  final _selectedFiles = SelectedFiles();
  final Logger _logger = Logger("ArchivePage");

  ArchivePage({
    this.tagPrefix = "archived_page",
    this.appBarType = GalleryType.archive,
    this.overlayType = GalleryType.archive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(Object context) {
    final Set<int> hiddenCollectionIDs =
        CollectionsService.instance.getHiddenCollections();
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getAllPendingOrUploadedFiles(
          creationStartTime,
          creationEndTime,
          Configuration.instance.getUserID()!,
          visibility: visibilityArchive,
          limit: limit,
          asc: asc,
          ignoredCollectionIDs: hiddenCollectionIDs,
        );
      },
      reloadEvent: Bus.instance.on<FilesUpdatedEvent>().where(
            (event) =>
                event.updatedFiles.firstWhereOrNull(
                  (element) => element.uploadedFileID != null,
                ) !=
                null,
          ),
      removalEventTypes: const {EventType.unarchived},
      forceReloadEvents: [
        Bus.instance.on<FilesUpdatedEvent>().where(
              (event) =>
                  event.updatedFiles.firstWhereOrNull(
                    (element) => element.uploadedFileID != null,
                  ) !=
                  null,
            ),
      ],
      tagPrefix: tagPrefix,
      selectedFiles: _selectedFiles,
      initialFiles: null,
      emptyState: const EmptyState(
        text: "You don't have any archived items.",
      ),
      header: FutureBuilder(
        future: CollectionsService.instance.getArchivedCollectionWithThumb(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            _logger.severe("failed to fetch archived albums", snapshot.error);
            return const Text("Something went wrong");
          } else if (snapshot.hasData) {
            final collectionsWithThumbnail =
                snapshot.data as List<CollectionWithThumbnail>;
            return SizedBox(
              height: 200,
              child: ListView.builder(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                itemCount: collectionsWithThumbnail.length,
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                itemBuilder: (context, index) {
                  final item = collectionsWithThumbnail[index];
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {},
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: CollectionItem(
                        item,
                        120,
                        shouldRender: true,
                      ),
                    ),
                  );
                },
              ),
            );
          } else {
            return const EnteLoadingWidget();
          }
        },
      ),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          "Archive",
          _selectedFiles,
        ),
      ),
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          FileSelectionOverlayBar(
            overlayType,
            _selectedFiles,
          ),
        ],
      ),
    );
  }
}
