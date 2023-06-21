import "dart:async";
import "dart:isolate";
import "dart:math";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong2/latlong.dart";
import "package:logging/logging.dart";
import "package:photos/models/file.dart";
import "package:photos/models/location/location.dart";
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
  List<ImageMarker> imageMarkers = [];
  List<File> allImages = [];
  StreamController<List<File>> visibleImages =
      StreamController<List<File>>.broadcast();
  MapController mapController = MapController();
  bool isLoading = true;
  double initialZoom = 4.0;
  double maxZoom = 18.0;
  double minZoom = 0.0;
  int debounceDuration = 500;
  LatLng center = LatLng(46.7286, 4.8614);
  final Logger _logger = Logger("_MapScreenState");
  StreamSubscription? _mapMoveSubscription;
  Isolate? isolate;

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
    late double minLat, maxLat, minLon, maxLon;
    final List<ImageMarker> tempMarkers = [];
    bool hasAnyLocation = false;
    for (var file in files) {
      if (kDebugMode && !file.hasLocation) {
        final rand = Random();
        file.location = Location(
          latitude: 46.7286 + rand.nextDouble() * 0.1,
          longitude: 4.8614 + rand.nextDouble() * 0.1,
        );
      }
      if (file.hasLocation && file.location != null) {
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
                        child: StreamBuilder<List<File>>(
                          stream: visibleImages.stream,
                          builder: (
                            BuildContext context,
                            AsyncSnapshot<List<File>> snapshot,
                          ) {
                            if (!snapshot.hasData) {
                              return const Text("Loading...");
                            }
                            final images = snapshot.data!;
                            _logger.info("Visible images: ${images.length}");
                            if (images.isEmpty) {
                              return Column(
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
                              );
                            }
                            return ListView.builder(
                              itemCount: images.length,
                              scrollDirection: Axis.horizontal,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 2),
                              physics: const BouncingScrollPhysics(),
                              itemBuilder: (context, index) {
                                final image = images[index];
                                return ImageTile(
                                  image: image,
                                  visibleImages: images,
                                  index: index,
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ),
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
