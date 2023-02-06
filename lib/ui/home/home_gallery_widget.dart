import 'package:flutter/material.dart';
import 'package:media_extension/media_extension_action_types.dart';
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
import 'package:photos/services/ignored_files_service.dart';
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';

class HomeGalleryWidget extends StatelessWidget {
  final Widget? header;
  final Widget? footer;
  final SelectedFiles selectedFiles;
  final IntentAction intentAction;

  const HomeGalleryWidget({
    Key? key,
    this.header,
    this.footer,
    required this.intentAction,
    required this.selectedFiles,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final gallery = Gallery(
      intentAction: intentAction,
      asyncLoader: (creationStartTime, creationEndTime, {limit, asc}) async {
        final ownerID = Configuration.instance.getUserID();
        final hasSelectedAllForBackup =
            Configuration.instance.hasSelectedAllFoldersForBackup();
        final collectionsToHide =
            CollectionsService.instance.collectionsHiddenFromTimeline();
        FileLoadResult result;
        if (hasSelectedAllForBackup) {
          result = await FilesDB.instance.getAllLocalAndUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            ignoredCollectionIDs: collectionsToHide,
          );
        } else {
          result = await FilesDB.instance.getAllPendingOrUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            ignoredCollectionIDs: collectionsToHide,
          );
        }

        // hide ignored files from home page UI
        final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
        result.files.removeWhere(
          (f) =>
              f.uploadedFileID == null &&
              IgnoredFilesService.instance.shouldSkipUpload(ignoredIDs, f),
        );
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
    );
    return Stack(
      children: [
        gallery,
        FileSelectionOverlayBar(GalleryType.homepage, selectedFiles)
      ],
    );
    // return gallery;
  }
}
