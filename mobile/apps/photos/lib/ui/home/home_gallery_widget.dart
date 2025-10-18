import "dart:async";

import 'package:flutter/material.dart';
import "package:flutter/rendering.dart";
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
import "package:photos/ui/viewer/gallery/component/group/type.dart";
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/standalone/debouncer.dart";

class HomeGalleryWidget extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final SelectedFiles selectedFiles;
  final GroupType? groupType;

  const HomeGalleryWidget({
    super.key,
    this.header,
    this.footer,
    this.groupType,
    required this.selectedFiles,
  });

  @override
  State<HomeGalleryWidget> createState() => _HomeGalleryWidgetState();
}

class _HomeGalleryWidgetState extends State<HomeGalleryWidget> {
  late final StreamSubscription<HideSharedItemsFromHomeGalleryEvent>
      _hideSharedFilesFromHomeSubscription;
  bool _shouldHideSharedItems = localSettings.hideSharedItemsFromHomeGallery;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  /// This debouncer is to delay the UI update of the shared items toggle
  /// since it's expensive (a new different key is used for the gallery
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
    widget.selectedFiles.addListener(_onSelectionChanged);
  }

  void _onSelectionChanged() {
    if (widget.selectedFiles.files.isNotEmpty) {
      if (_sheetController.isAttached) {
        _sheetController.animateTo(
          0.40,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _hideSharedFilesFromHomeSubscription.cancel();
    _hideSharedItemsToggleDebouncer.cancelDebounceTimer();
    widget.selectedFiles.removeListener(_onSelectionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gallery = NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (scrollInfo is UserScrollNotification && scrollInfo.depth == 0) {
          if (widget.selectedFiles.files.isNotEmpty &&
              _sheetController.isAttached &&
              _sheetController.size > 0.25) {
            _sheetController.animateTo(
              0.25,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }
        }
        return false;
      },
      child: Gallery(
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
            ignoreSharedItems: _shouldHideSharedItems,
          );
          if (hasSelectedAllForBackup) {
            result = await FilesDB.instance.getAllLocalAndUploadedFiles(
              creationStartTime,
              creationEndTime,
              ownerID!,
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
        selectedFiles: widget.selectedFiles,
        header: widget.header,
        footer: widget.footer,
        reloadDebounceTime: const Duration(seconds: 2),
        reloadDebounceExecutionInterval: const Duration(seconds: 5),
        galleryType: GalleryType.homepage,
        groupType: widget.groupType,
        showGallerySettingsCTA: true,
      ),
    );

    return GalleryFilesState(
      child: SelectionState(
        selectedFiles: widget.selectedFiles,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            gallery,
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.40,
              minChildSize: 0.25,
              maxChildSize: 0.40,
              snap: true,
              snapSizes: const [0.25, 0.40],
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: FileSelectionOverlayBar(
                      GalleryType.homepage,
                      widget.selectedFiles,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
