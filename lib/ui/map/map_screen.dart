import "dart:async";
import "dart:isolate";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:interactive_bottom_sheet/interactive_bottom_sheet.dart";
import "package:latlong2/latlong.dart";
import "package:logging/logging.dart";
import "package:photos/models/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/map/image_marker.dart";
import 'package:photos/ui/map/image_tile.dart';
import "package:photos/ui/map/map_isolate.dart";
import "package:photos/ui/map/map_view.dart";
import "package:photos/utils/toast_util.dart";

class MapScreen extends StatefulWidget {
  // Add a function parameter where the function returns a Future<List<File>>

  final Future<List<File>> Function() filesFutureFn;

  const MapScreen({
    super.key,
    required this.filesFutureFn,
  });

  @override
  State<StatefulWidget> createState() {
    return _MapScreenState();
  }
}

class _MapScreenState extends State<MapScreen> {
  GlobalKey bottomSheetKey = GlobalKey();
  List<ImageMarker> imageMarkers = [];
  List<File> allImages = [];
  StreamController<List<File>> visibleImages =
      StreamController<List<File>>.broadcast();
  MapController mapController = MapController();
  bool isLoading = true;
  double initialZoom = 4.5;
  double maxZoom = 18.0;
  double minZoom = 2.8;
  int debounceDuration = 500;
  LatLng center = LatLng(46.7286, 4.8614);
  final Logger _logger = Logger("_MapScreenState");
  StreamSubscription? _mapMoveSubscription;
  Isolate? isolate;
  double heightOfBottomSheetContent = 100;
  static const gridCrossAxisSpacing = 4.0;
  static const gridMainAxisSpacing = 4.0;
  static const gridPadding = 2.0;
  static const gridCrossAxisCount = 4;
  static const bottomSheetDraggableAreaHeight = 32.0;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  void dispose() {
    super.dispose();
    visibleImages.close();
    _mapMoveSubscription?.cancel();
  }

  Future<void> initialize() async {
    try {
      allImages = await widget.filesFutureFn();
      processFiles(allImages);
    } catch (e, s) {
      _logger.severe("Error initializing map screen", e, s);
    }
  }

  Future<void> processFiles(List<File> files) async {
    final List<ImageMarker> tempMarkers = [];
    bool hasAnyLocation = false;
    File? mostRecentFile;
    for (var file in files) {
      if (file.hasLocation && file.location != null) {
        hasAnyLocation = true;

        if (mostRecentFile == null) {
          mostRecentFile = file;
        } else {
          if ((mostRecentFile.creationTime ?? 0) < (file.creationTime ?? 0)) {
            mostRecentFile = file;
          }
        }

        tempMarkers.add(
          ImageMarker(
            latitude: file.location!.latitude!,
            longitude: file.location!.longitude!,
            imageFile: file,
          ),
        );
      }
    }

    if (hasAnyLocation) {
      center = LatLng(
        mostRecentFile!.location!.latitude!,
        mostRecentFile.location!.longitude!,
      );

      if (kDebugMode) {
        debugPrint("Info for map: center $center, initialZoom $initialZoom");
      }
    } else {
      showShortToast(context, "No images with location");
    }

    setState(() {
      imageMarkers = tempMarkers;
    });

    mapController.move(
      center,
      initialZoom,
    );

    Timer(Duration(milliseconds: debounceDuration), () {
      calculateVisibleMarkers(mapController.bounds!);
      setState(() {
        isLoading = false;
      });
    });
  }

  void calculateVisibleMarkers(LatLngBounds bounds) async {
    final ReceivePort receivePort = ReceivePort();
    isolate = await Isolate.spawn<MapIsolate>(
      _calculateMarkersIsolate,
      MapIsolate(
        bounds: bounds,
        imageMarkers: imageMarkers,
        sendPort: receivePort.sendPort,
      ),
    );

    _mapMoveSubscription = receivePort.listen((dynamic message) async {
      if (message is List<File>) {
        visibleImages.sink.add(message);
      } else {
        _mapMoveSubscription?.cancel();
        isolate?.kill();
      }
    });
  }

  @pragma('vm:entry-point')
  static void _calculateMarkersIsolate(MapIsolate message) async {
    final bounds = message.bounds;
    final imageMarkers = message.imageMarkers;
    final SendPort sendPort = message.sendPort;
    try {
      final List<File> visibleFiles = [];
      for (var imageMarker in imageMarkers) {
        final point = LatLng(imageMarker.latitude, imageMarker.longitude);
        if (bounds.contains(point)) {
          visibleFiles.add(imageMarker.imageFile);
        }
      }
      sendPort.send(visibleFiles);
    } catch (e) {
      sendPort.send(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      color: colorScheme.backgroundBase,
      child: SafeArea(
        top: false,
        child: Theme(
          data: Theme.of(context).copyWith(
            bottomSheetTheme: const BottomSheetThemeData(
              backgroundColor: Colors.transparent,
            ),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                LayoutBuilder(
                  builder: (context, constrains) {
                    return SizedBox(
                      height: constrains.maxHeight * 0.75 +
                          bottomSheetDraggableAreaHeight,
                      child: MapView(
                        key: ValueKey(
                          'image-marker-count-${imageMarkers.length}',
                        ),
                        controller: mapController,
                        imageMarkers: imageMarkers,
                        updateVisibleImages: calculateVisibleMarkers,
                        center: center,
                        initialZoom: initialZoom,
                        minZoom: minZoom,
                        maxZoom: maxZoom,
                        debounceDuration: debounceDuration,
                        bottomSheetDraggableAreaHeight:
                            bottomSheetDraggableAreaHeight,
                      ),
                    );
                  },
                ),
                isLoading
                    ? EnteLoadingWidget(
                        size: 28,
                        color: getEnteColorScheme(context).primary700,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
            bottomSheet: InteractiveBottomSheet(
              options: InteractiveBottomSheetOptions(
                backgroundColor: colorScheme.backgroundElevated,
                maxSize: 0.8,
              ),
              draggableAreaOptions: DraggableAreaOptions(
                topBorderRadius: 12,
                backgroundColor: colorScheme.backgroundElevated2,
                indicatorColor: colorScheme.fillBase,
                height: bottomSheetDraggableAreaHeight,
                indicatorHeight: 4,
              ),
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
                    _logger.info("Visible images: ${images.length}");
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
                    //Be very careful when changing the height of the grid. It
                    //the height should be exactly how much the grid occupies.
                    //Do not add padding around the grid.
                    //Doing these will cause unexpected scroll behaviour. This
                    //is an issue with the package that is used here
                    //(InteractiveBottomSheet)
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: maxHeightOfGrid(images.length),
                      ),
                      child: GridView.builder(
                        itemCount: images.length,
                        scrollDirection: Axis.vertical,
                        padding:
                            const EdgeInsets.symmetric(horizontal: gridPadding),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          crossAxisSpacing: gridCrossAxisSpacing,
                          mainAxisSpacing: gridMainAxisSpacing,
                        ),
                        // shrinkWrap: true,
                        itemBuilder: (context, index) {
                          final image = images[index];
                          return ImageTile(
                            image: image,
                            visibleImages: images,
                            index: index,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double maxHeightOfGrid(int imageCount) {
    final rowHeight = ((MediaQuery.of(context).size.width -
                (gridPadding * 2 +
                    gridCrossAxisSpacing * (gridCrossAxisCount - 1))) /
            gridCrossAxisCount) +
        gridMainAxisSpacing;
    final rowCount = (imageCount / gridCrossAxisCount).ceilToDouble();

    return rowCount * rowHeight;
  }
}
