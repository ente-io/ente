import "dart:async";
import 'dart:developer' as dev;

import "package:flutter/material.dart";
import "package:intl/intl.dart";
import "package:photos/core/constants.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/filter/db_filters.dart";
import "package:photos/services/location_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/title_bar_title_widget.dart";
import "package:photos/ui/components/title_bar_widget.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";
import "package:photos/ui/viewer/gallery/state/selection_state.dart";
import "package:photos/ui/viewer/location/edit_location_sheet.dart";
import "package:photos/utils/dialog_util.dart";

class LocationScreen extends StatelessWidget {
  final String tagPrefix;
  const LocationScreen({this.tagPrefix = "", super.key});

  @override
  Widget build(BuildContext context) {
    final heightOfStatusBar = MediaQuery.of(context).viewPadding.top;
    const heightOfAppBar = 48.0;
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size(double.infinity, heightOfAppBar),
        child: TitleBarWidget(
          isSliver: false,
          isFlexibleSpaceDisabled: true,
          actionIcons: [LocationScreenPopUpMenu()],
        ),
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height -
                (heightOfAppBar + heightOfStatusBar),
            width: double.infinity,
            child: LocationGalleryWidget(
              tagPrefix: tagPrefix,
            ),
          ),
        ],
      ),
    );
  }
}

class LocationScreenPopUpMenu extends StatelessWidget {
  const LocationScreenPopUpMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          highlightColor: Colors.transparent,
          splashColor: Colors.transparent,
        ),
        child: PopupMenuButton(
          elevation: 2,
          offset: const Offset(10, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          color: colorScheme.backgroundElevated2,
          child: const IconButtonWidget(
            icon: Icons.more_horiz,
            iconButtonType: IconButtonType.primary,
            disableGestureDetector: true,
          ),
          itemBuilder: (context) {
            return [
              PopupMenuItem(
                value: "edit",
                child: Text(
                  S.of(context).edit,
                  style: textTheme.bodyBold,
                ),
              ),
              PopupMenuItem(
                onTap: () {},
                value: "delete",
                child: Text(
                  S.of(context).deleteLocation,
                  style: textTheme.bodyBold.copyWith(color: warning500),
                ),
              ),
            ];
          },
          onSelected: (value) async {
            if (value == "edit") {
              showEditLocationSheet(
                context,
                InheritedLocationScreenState.of(context).locationTagEntity,
              );
            } else if (value == "delete") {
              try {
                await LocationService.instance.deleteLocationTag(
                  InheritedLocationScreenState.of(context).locationTagEntity.id,
                );
                Navigator.of(context).pop();
              } catch (e) {
                await showGenericErrorDialog(context: context, error: e);
              }
            }
          },
        ),
      ),
    );
  }
}

class LocationGalleryWidget extends StatefulWidget {
  final String tagPrefix;
  const LocationGalleryWidget({required this.tagPrefix, super.key});

  @override
  State<LocationGalleryWidget> createState() => _LocationGalleryWidgetState();
}

class _LocationGalleryWidgetState extends State<LocationGalleryWidget> {
  late final Future<FileLoadResult> fileLoadResult;
  late final List<EnteFile> allFilesWithLocation;

  late Widget galleryHeaderWidget;
  final _selectedFiles = SelectedFiles();
  late final StreamSubscription<LocalPhotosUpdatedEvent> _filesUpdateEvent;
  @override
  void initState() {
    super.initState();

    final collectionsToHide =
        CollectionsService.instance.archivedOrHiddenCollectionIds();
    fileLoadResult = FilesDB.instance
        .fetchAllUploadedAndSharedFilesWithLocation(
      galleryLoadStartTime,
      galleryLoadEndTime,
      limit: null,
      asc: false,
      filterOptions: DBFilterOptions(
        ignoredCollectionIDs: collectionsToHide,
        hideIgnoredForUpload: true,
      ),
    )
        .then((value) {
      allFilesWithLocation = value.files;
      _filesUpdateEvent =
          Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
        if (event.type == EventType.deletedFromDevice ||
            event.type == EventType.deletedFromEverywhere ||
            event.type == EventType.deletedFromRemote ||
            event.type == EventType.hide) {
          for (var updatedFile in event.updatedFiles) {
            allFilesWithLocation.remove(updatedFile);
          }
          if (mounted) {
            setState(() {});
          }
        }
      });
      return value;
    });

    galleryHeaderWidget = const GalleryHeaderWidget();
  }

  @override
  void dispose() {
    InheritedLocationScreenState.memoryCountNotifier.value = null;
    _filesUpdateEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedRadius =
        InheritedLocationScreenState.of(context).locationTagEntity.item.radius;
    final centerPoint = InheritedLocationScreenState.of(context)
        .locationTagEntity
        .item
        .centerPoint;

    Future<FileLoadResult> filterFiles() async {
      //waiting for allFilesWithLocation to be initialized
      await fileLoadResult;
      final stopWatch = Stopwatch()..start();
      final filesInLocation = allFilesWithLocation;
      filesInLocation.removeWhere((f) {
        return !isFileInsideLocationTag(
          centerPoint,
          f.location!,
          selectedRadius,
        );
      });
      dev.log(
        "Time taken to get all files in a location tag: ${stopWatch.elapsedMilliseconds} ms",
      );
      stopWatch.stop();
      InheritedLocationScreenState.memoryCountNotifier.value =
          filesInLocation.length;

      return Future.value(
        FileLoadResult(
          filesInLocation,
          false,
        ),
      );
    }

    return FutureBuilder(
      //rebuild gallery only when there is change in radius or center point
      key: ValueKey("$centerPoint$selectedRadius"),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SelectionState(
            selectedFiles: _selectedFiles,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Gallery(
                  loadingWidget: Column(
                    children: [
                      galleryHeaderWidget,
                      EnteLoadingWidget(
                        color: getEnteColorScheme(context).strokeMuted,
                      ),
                    ],
                  ),
                  header: galleryHeaderWidget,
                  asyncLoader: (
                    creationStartTime,
                    creationEndTime, {
                    limit,
                    asc,
                  }) async {
                    return snapshot.data as FileLoadResult;
                  },
                  reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
                  removalEventTypes: const {
                    EventType.deletedFromRemote,
                    EventType.deletedFromEverywhere,
                  },
                  selectedFiles: _selectedFiles,
                  tagPrefix: widget.tagPrefix,
                ),
                FileSelectionOverlayBar(
                  GalleryType.locationTag,
                  _selectedFiles,
                ),
              ],
            ),
          );
        } else {
          return Column(
            children: [
              galleryHeaderWidget,
              const Expanded(
                child: EnteLoadingWidget(),
              ),
            ],
          );
        }
      },
      future: filterFiles(),
    );
  }
}

class GalleryHeaderWidget extends StatefulWidget {
  const GalleryHeaderWidget({super.key});

  @override
  State<GalleryHeaderWidget> createState() => _GalleryHeaderWidgetState();
}

class _GalleryHeaderWidgetState extends State<GalleryHeaderWidget> {
  @override
  Widget build(BuildContext context) {
    final locationName =
        InheritedLocationScreenState.of(context).locationTagEntity.item.name;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              key: ValueKey(locationName),
              width: double.infinity,
              child: TitleBarTitleWidget(
                title: locationName,
                onTap: () {
                  showEditLocationSheet(
                    context,
                    InheritedLocationScreenState.of(context).locationTagEntity,
                  );
                },
              ),
            ),
            ValueListenableBuilder(
              valueListenable: InheritedLocationScreenState.memoryCountNotifier,
              builder: (context, int? value, _) {
                if (value == null) {
                  return RepaintBoundary(
                    child: EnteLoadingWidget(
                      size: 12,
                      color: getEnteColorScheme(context).strokeMuted,
                      alignment: Alignment.centerLeft,
                      padding: 2.5,
                    ),
                  );
                } else {
                  return Text(
                    S
                        .of(context)
                        .memoryCount(value, NumberFormat().format(value)),
                    style: getEnteTextTheme(context).smallMuted,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
