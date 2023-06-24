import "dart:async";

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

class MapPullUpGallery extends StatelessWidget {
  final _selectedFiles = SelectedFiles();
  final StreamController<List<File>> visibleImages;
  final double bottomSheetDraggableAreaHeight;
  static const gridCrossAxisSpacing = 4.0;
  static const gridMainAxisSpacing = 4.0;
  static const gridPadding = 2.0;
  static const gridCrossAxisCount = 4;
  MapPullUpGallery(
    this.visibleImages,
    this.bottomSheetDraggableAreaHeight, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Logger logger = Logger("_MapPullUpGalleryState");
    const double initialChildSize = 0.25;

    Widget? cachedScrollableContent;

    return DraggableScrollableSheet(
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
            bottomSheetDraggableAreaHeight: bottomSheetDraggableAreaHeight,
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOutExpo,
              switchOutCurve: Curves.easeInOutExpo,
              child: StreamBuilder<List<File>>(
                stream: visibleImages.stream,
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

                  return Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      Gallery(
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
                      ),
                      FileSelectionOverlayBar(
                        GalleryType.searchResults,
                        _selectedFiles,
                        backgroundColor: colorScheme.backgroundElevated2,
                      )
                    ],
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
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      controller: scrollController,
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: bottomSheetDraggableAreaHeight / 2 - indicatorHeight / 2,
          ),
          child: Container(
            height: indicatorHeight,
            width: 72,
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).fillBase,
              borderRadius: const BorderRadius.all(Radius.circular(2)),
            ),
          ),
        ),
      ),
    );
  }
}
