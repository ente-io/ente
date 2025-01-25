import "dart:async";

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import "package:photos/events/hide_shared_items_from_home_gallery_event.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import "package:photos/services/filter/db_filters.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/debouncer.dart";

class HomeGalleryWidget extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final SelectedFiles selectedFiles;

  const HomeGalleryWidget({
    super.key,
    this.header,
    this.footer,
    required this.selectedFiles,
  });

  @override
  State<HomeGalleryWidget> createState() => _HomeGalleryWidgetState();
}

class _HomeGalleryWidgetState extends State<HomeGalleryWidget> {
  late final StreamSubscription<HideSharedItemsFromHomeGalleryEvent>
      _hideSharedFilesFromHomeSubscription;
  bool _shouldHideSharedItems = localSettings.hideSharedItemsFromHomeGallery;

  /// This deboucner is to delay the UI update of the shared items toggle
  /// since it's expensive (a new differnt key is used for the gallery
  /// widget when hide is toggled), without which, causes the toggle button used
  /// for it in settings to have janky animation.
  final _hideSharedItemsToggleDebouncer = Debouncer(
    const Duration(milliseconds: 500),
  );

  @override
  void initState() {
    super.initState();
    _hideSharedFilesFromHomeSubscription =
        Bus.instance.on<HideSharedItemsFromHomeGalleryEvent>().listen((event) {
      localSettings.setHideSharedItemsFromHomeGallery(event.shouldHide);
      _hideSharedItemsToggleDebouncer.run(() async {
        setState(() {
          _shouldHideSharedItems = event.shouldHide;
        });
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _hideSharedFilesFromHomeSubscription.cancel();
    _hideSharedItemsToggleDebouncer.cancelDebounceTimer();
  }

  @override
  Widget build(BuildContext context) {
    final double bottomSafeArea = MediaQuery.paddingOf(context).bottom;
    final gallery = Gallery(
      key: ValueKey(_shouldHideSharedItems),
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
            ownerID!,
            limit: limit,
            asc: asc,
            filterOptions: filterOptions,
            ignoreSharedFiles: _shouldHideSharedItems,
          );
        } else {
          result = await FilesDB.instance.getAllPendingOrUploadedFiles(
            creationStartTime,
            creationEndTime,
            ownerID!,
            limit: limit,
            asc: asc,
            filterOptions: filterOptions,
            ignoreSharedFiles: _shouldHideSharedItems,
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
      selectedFiles: widget.selectedFiles,
      header: widget.header,
      footer: widget.footer,
      // scrollSafe area -> SafeArea + Preserver more + Nav Bar buttons
      scrollBottomSafeArea: bottomSafeArea + 180,
      reloadDebounceTime: const Duration(seconds: 2),
      reloadDebounceExecutionInterval: const Duration(seconds: 5),
    );
    return GalleryFilesState(
      child: SelectionState(
        selectedFiles: widget.selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            FileSelectionOverlayBar(GalleryType.homepage, widget.selectedFiles),
          ],
        ),
      ),
    );
  }
}
