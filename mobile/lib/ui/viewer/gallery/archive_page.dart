import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/files_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import "package:photos/ui/collections/album/horizontal_list.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import "package:photos/ui/viewer/gallery/empty_state.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import 'package:photos/ui/viewer/gallery/gallery_app_bar_widget.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class ArchivePage extends StatelessWidget {
  final String tagPrefix;
  final GalleryType appBarType;
  final GalleryType overlayType;
  final _selectedFiles = SelectedFiles();

  ArchivePage({
    this.tagPrefix = "archived_page",
    this.appBarType = GalleryType.archive,
    this.overlayType = GalleryType.archive,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Set<int> hiddenCollectionIDs =
        CollectionsService.instance.getHiddenCollectionIds();
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) {
        return FilesDB.instance.getAllPendingOrUploadedFiles(
          creationStartTime,
          creationEndTime,
          Configuration.instance.getUserID()!,
          visibility: archiveVisibility,
          limit: limit,
          asc: asc,
          filterOptions: DBFilterOptions(
            hideIgnoredForUpload: true,
            dedupeUploadID: true,
            ignoredCollectionIDs: hiddenCollectionIDs,
          ),
          applyOwnerCheck: true,
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
      emptyState: EmptyState(
        text: S.of(context).youDontHaveAnyArchivedItems,
      ),
      header: AlbumHorizontalList(
        CollectionsService.instance.getArchivedCollection,
      ),
    );
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50.0),
        child: GalleryAppBarWidget(
          appBarType,
          S.of(context).archive,
          _selectedFiles,
        ),
      ),
      body: SelectionState(
        selectedFiles: _selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            FileSelectionOverlayBar(
              overlayType,
              _selectedFiles,
            ),
          ],
        ),
      ),
    );
  }
}
