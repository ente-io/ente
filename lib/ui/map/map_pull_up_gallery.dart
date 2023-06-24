import "dart:async";

import "package:defer_pointer/defer_pointer.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/models/gallery_type.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/actions/file_selection_overlay_bar.dart";
import "package:photos/ui/viewer/gallery/gallery.dart";

class MapPullUpGallery extends StatefulWidget {
  final StreamController<List<File>> visibleImages;
  final double bottomUnsafeArea;
  final double bottomSheetDraggableAreaHeight;
  static const gridCrossAxisSpacing = 4.0;
  static const gridMainAxisSpacing = 4.0;
  static const gridPadding = 2.0;
  static const gridCrossAxisCount = 4;
  const MapPullUpGallery(
    this.visibleImages,
    this.bottomSheetDraggableAreaHeight,
    this.bottomUnsafeArea, {
    Key? key,
  }) : super(key: key);

  @override
  State<MapPullUpGallery> createState() => _MapPullUpGalleryState();
}

class _MapPullUpGalleryState extends State<MapPullUpGallery> {
  final _selectedFiles = SelectedFiles();

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger("_MapPullUpGalleryState");
    final screenHeight = MediaQuery.of(context).size.height;
    final unsafeAreaProportion = widget.bottomUnsafeArea / screenHeight;
    final double initialChildSize = 0.25 + unsafeAreaProportion;

    Widget? cachedScrollableContent;

    return DeferredPointerHandler(
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          DraggableScrollableSheet(
            expand: false,
            initialChildSize: initialChildSize,
            minChildSize: initialChildSize,
            maxChildSize: 0.8,
            snap: true,
            snapSizes: const [0.5],
            builder: (context, scrollController) {
              //Must use cached widget here to avoid rebuilds when DraggableScrollableSheet
              //is snapped to it's initialChildSize
              cachedScrollableContent ??=
                  cacheScrollableContent(scrollController, context, logger);
              return cachedScrollableContent!;
            },
          ),
          DeferPointer(
            child: FileSelectionOverlayBar(
              GalleryType.searchResults,
              _selectedFiles,
              backgroundColor: getEnteColorScheme(context).backgroundElevated2,
            ),
          ),
        ],
      ),
    );
  }

  Widget cacheScrollableContent(
    ScrollController scrollController,
    BuildContext context,
    logger,
  ) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        color: colorScheme.backgroundElevated,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          DraggableHeader(
            scrollController: scrollController,
            bottomSheetDraggableAreaHeight:
                widget.bottomSheetDraggableAreaHeight,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOutExpo,
              switchOutCurve: Curves.easeInOutExpo,
              child: StreamBuilder<List<File>>(
                stream: widget.visibleImages.stream,
                builder: (
                  BuildContext context,
                  AsyncSnapshot<List<File>> snapshot,
                ) {
                  if (!snapshot.hasData) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: const EnteLoadingWidget(),
                    );
                  }

                  final images = snapshot.data!;
                  logger.info("Visible images: ${images.length}");
                  //To retain only selected files that are in view (visible)
                  _selectedFiles.files.retainAll(images.toSet());

                  if (images.isEmpty) {
                    return SizedBox(
                      height: MediaQuery.of(context).size.height * 0.2,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "No photos found here",
                              style: textTheme.large,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Zoom out to see photos",
                              style: textTheme.smallFaint,
                            )
                          ],
                        ),
                      ),
                    );
                  }

                  return Gallery(
                    asyncLoader: (
                      creationStartTime,
                      creationEndTime, {
                      limit,
                      asc,
                    }) async {
                      FileLoadResult result;
                      result = FileLoadResult(images, false);
                      return result;
                    },
                    reloadEvent: Bus.instance.on<LocalPhotosUpdatedEvent>(),
                    tagPrefix: "map_gallery",
                    showSelectAllByDefault: true,
                    selectedFiles: _selectedFiles,
                    isScrollablePositionedList: false,
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

class DraggableHeader extends StatelessWidget {
  const DraggableHeader({
    Key? key,
    required this.scrollController,
    required this.bottomSheetDraggableAreaHeight,
  }) : super(key: key);
  static const indicatorHeight = 4.0;
  final ScrollController scrollController;
  final double bottomSheetDraggableAreaHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      controller: scrollController,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          color: colorScheme.backgroundElevated2,
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical:
                  bottomSheetDraggableAreaHeight / 2 - indicatorHeight / 2,
            ),
            child: Container(
              height: indicatorHeight,
              width: 72,
              decoration: BoxDecoration(
                color: colorScheme.fillBase,
                borderRadius: const BorderRadius.all(Radius.circular(2)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
