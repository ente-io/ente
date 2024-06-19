import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/selection_state.dart";

class HomeGalleryWidget extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final SelectedFiles selectedFiles;

  const HomeGalleryWidget({
    Key? key,
    this.header,
    this.footer,
    required this.selectedFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final gallery = Gallery(
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final ownerID = Configuration.instance.getUserID();
        final hasSelectedAllForBackup =
            Configuration.instance.hasSelectedAllFoldersForBackup();
        final collectionsToHide =
            CollectionsService.instance.archivedOrHiddenCollectionIds();
        FileLoadResult result;
        final DBFilterOptions filterOptions = DBFilterOptions(
          hideIgnoredForUpload: true,
          dedupeUploadID: true,
          ignoredCollectionIDs: collectionsToHide,
          ignoreSavedFiles: true,
        );
        if (hasSelectedAllForBackup) {
          result = await FilesDB.instance.getAllLocalAndUploadedFiles(
            creationStartTime,
            creationEndTime,
            limit: limit,
            asc: asc,
            filterOptions: filterOptions,
          );
        } else {
          result = await FilesDB.instance.getAllPendingOrUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            filterOptions: filterOptions,
          );
        }

        return result;
      },
      reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
      removalEventTypes: const {
        EventType.deletedFromRemote,
        EventType.deletedFromEverywhere,
        EventType.archived,
        EventType.hide,
      },
      forceReloadEvents: [
        Bus.instance.on<BackupFoldersUpdatedEvent>(),
        Bus.instance.on<ForceReloadHomeGalleryEvent>(),
      ],
      tagPrefix: "home_gallery",
      selectedFiles: selectedFiles,
      header: header,
      footer: footer,
      // scrollSafe area -> SafeArea + Preserver more + Nav Bar buttons
      scrollBottomSafeArea: bottomSafeArea + 180,
      reloadDebounceTime: const Duration(seconds: 2),
      reloadDebounceExecutionInterval: const Duration(seconds: 5),
    );
    return SelectionState(
      selectedFiles: selectedFiles,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          gallery,
          FileSelectionOverlayBar(GalleryType.homepage, selectedFiles),
        ],
      ),
    );
  }
}
