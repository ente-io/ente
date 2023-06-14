import "dart:async";
import "dart:isolate";
import "dart:math";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong2/latlong.dart";
import "package:logging/logging.dart";
import "package:photos/models/file.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/map/image_marker.dart";
import 'package:photos/ui/map/image_tile.dart';
import "package:photos/ui/map/map_view.dart";
import "package:photos/utils/toast_util.dart";

class IsolateModel {
  final LatLngBounds bounds;
  final List<ImageMarker> imageMarkers;
  final SendPort sendPort;

  IsolateModel({
    required this.bounds,
    required this.imageMarkers,
    required this.sendPort,
  });
}

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
  List<ImageMarker> imageMarkers = [];
  List<File> allImages = [];
  List<File> visibleImages = [];
  MapController mapController = MapController();
  bool isLoading = true;
  double initialZoom = 4.0;
  double maxZoom = 19.0;
  double minZoom = 0.0;
  int debounceDuration = 500;
  LatLng center = LatLng(46.7286, 4.8614);
  final Logger _logger = Logger("_MapScreenState");

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      allImages = await widget.filesFutureFn();
      processFiles(allImages);
    } catch (e, s) {
      _logger.severe("Error initializing map screen", e, s);
    }
  }

  void processFiles(List<File> files) async {
    late double minLat, maxLat, minLon, maxLon;
    final List<ImageMarker> tempMarkers = [];
    bool hasAnyLocation = false;
    for (final file in files) {
      if (file.hasLocation) {
        if (!hasAnyLocation) {
          minLat = file.location!.latitude!;
          minLon = file.location!.longitude!;
          maxLat = file.location!.latitude!;
          maxLon = file.location!.longitude!;
          hasAnyLocation = true;
        } else {
          minLat = min(minLat, file.location!.latitude!);
          minLon = min(minLon, file.location!.longitude!);
          maxLat = max(maxLat, file.location!.latitude!);
          maxLon = max(maxLon, file.location!.longitude!);
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
        minLat + (maxLat - minLat) / 2,
        minLon + (maxLon - minLon) / 2,
      );
      final latRange = maxLat - minLat;
      final lonRange = maxLon - minLon;

      final latZoom = log(360.0 / latRange) / log(2);
      final lonZoom = log(180.0 / lonRange) / log(2);

      initialZoom = min(latZoom, lonZoom);
      if (initialZoom <= minZoom) initialZoom = minZoom + 1;
      if (initialZoom >= (maxZoom - 1)) initialZoom = maxZoom - 1;
      if (kDebugMode) {
        debugPrint("Info for map: center $center, initialZoom $initialZoom");
        debugPrint("Info for map: minLat $minLat, maxLat $maxLat");
        debugPrint("Info for map: minLon $minLon, maxLon $maxLon");
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
      updateVisibleImages(mapController.bounds!);
      setState(() {
        isLoading = false;
      });
    });
  }

  Future<List<File>> calculateVisibleMarkers(LatLngBounds bounds) async {
    final ReceivePort receivePort = ReceivePort();
    final isolate = await Isolate.spawn<IsolateModel>(
      _calculateMarkersIsolate,
      IsolateModel(
        bounds: bounds,
        imageMarkers: imageMarkers,
        sendPort: receivePort.sendPort,
      ),
    );

    final completer = Completer<List<File>>();
    receivePort.listen((dynamic message) {
      if (message is List<File>) {
        completer.complete(message);
      } else {
        completer.completeError(message);
      }
      isolate.kill();
    });

    return completer.future;
  }

  @pragma('vm:entry-point')
  static void _calculateMarkersIsolate(IsolateModel message) async {
    final bounds = message.bounds;
    final imageMarkers = message.imageMarkers;
    final SendPort sendPort = message.sendPort;
    try {
      final List<File> images = [];
      for (var imageMarker in imageMarkers) {
        final point = LatLng(imageMarker.latitude, imageMarker.longitude);
        if (bounds.contains(point)) {
          images.add(imageMarker.imageFile);
        }
      }
      sendPort.send(images);
    } catch (e) {
      sendPort.send(e.toString());
    }
  }

  void updateVisibleImages(LatLngBounds bounds) async {
    final images = await calculateVisibleMarkers(bounds);
    setState(() {
      visibleImages = images;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Container(
      color: colorScheme.backgroundBase,
      child: SafeArea(
        top: false,
        child: Scaffold(
          body: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                      child: MapView(
                        controller: mapController,
                        imageMarkers: imageMarkers,
                        updateVisibleImages: updateVisibleImages,
                        center: center,
                        initialZoom: initialZoom,
                        minZoom: minZoom,
                        maxZoom: maxZoom,
                        debounceDuration: debounceDuration,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(2),
                      topRight: Radius.circular(2),
                    ),
                    child: SizedBox(
                      height: 116,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        switchInCurve: Curves.easeInOutExpo,
                        switchOutCurve: Curves.easeInOutExpo,
                        child: visibleImages.isNotEmpty
                            ? ListView.builder(
                                itemCount: visibleImages.length,
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                physics: const BouncingScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final image = visibleImages[index];
                                  return ImageTile(
                                    image: image,
                                    allImages: allImages,
                                    visibleImages: visibleImages,
                                    index: index,
                                  );
                                },
                              )
                            : Column(
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
                    ),
                  )
                ],
              ),
              isLoading
                  ? EnteLoadingWidget(
                      size: 28,
                      color: getEnteColorScheme(context).primary700,
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}
