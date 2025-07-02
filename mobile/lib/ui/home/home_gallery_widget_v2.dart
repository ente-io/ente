import "dart:async";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/db/local/schema.dart";
import "package:photos/db/remote/schema.dart";
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/files_updated_event.dart';
import 'package:photos/events/force_reload_home_gallery_event.dart';
import "package:photos/events/hide_shared_items_from_home_gallery_event.dart";
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/file.dart";
import 'package:photos/models/file_load_result.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import "package:photos/services/remote/localMapper/merge.dart";
import 'package:photos/ui/viewer/actions/file_selection_overlay_bar.dart';
import 'package:photos/ui/viewer/gallery/gallery.dart';
import "package:photos/ui/viewer/gallery/state/gallery_files_inherited_widget.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/utils/standalone/debouncer.dart";

class HomeGalleryWidgetV2 extends StatefulWidget {
  final Widget? header;
  final Widget? footer;
  final SelectedFiles selectedFiles;

  const HomeGalleryWidgetV2({
    super.key,
    this.header,
    this.footer,
    required this.selectedFiles,
  });

  @override
  State<HomeGalleryWidgetV2> createState() => _HomeGalleryWidgetV2State();
}

class _HomeGalleryWidgetV2State extends State<HomeGalleryWidgetV2> {
  late final StreamSubscription<HideSharedItemsFromHomeGalleryEvent>
      _hideSharedFilesFromHomeSubscription;
  bool _shouldHideSharedItems = localSettings.hideSharedItemsFromHomeGallery;
  final Logger _logger = Logger("HomeGalleryWidgetV2State");

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
        _logger.info("Loading home gallery files v1");
        final TimeLogger tl = TimeLogger();

        final localFiles = await localDB.getAssets(
          params: LocalAssertsParam(
            limit: null,
            isAsc: asc ?? false,
            createAtRange: (creationStartTime, creationEndTime),
          ),
        );
        _logger.info("Loaded local files: ${localFiles.length} files $tl");

        final enteFiles = await remoteCache.getCollectionFiles(
          FilterQueryParam(
            limit: limit,
            isAsc: asc ?? false,
            createAtRange: (creationStartTime, creationEndTime),
          ),
        );
        _logger.info("Loaded remote files: ${enteFiles.length} files $tl");

        final List<EnteFile> allFiles = await merge(
          localFiles: localFiles,
          remoteFiles: enteFiles,
          filterOptions: homeGalleryFilters,
        );
        _logger.info(
            "Merged files: ${allFiles.length} (local: ${localFiles.length}, remote: ${enteFiles.length}) files $tl, total ${tl.elapsed}");
        // merge
        return FileLoadResult(
          allFiles,
          limit != null &&
              (enteFiles.length <= limit || localFiles.length <= limit),
        );
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
