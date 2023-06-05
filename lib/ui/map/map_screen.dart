import "dart:async";
import "dart:math";

import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong2/latlong.dart";
import "package:logging/logging.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/map_credits.dart";
import "package:photos/ui/map/map_view.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

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
  double initialZoom = 2.0;
  LatLng center = LatLng(10.732951, 78.405635);
  final Logger _logger = Logger("_MapScreenState");

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      await getFiles();
      processFiles(allImages);
    } catch (e, s) {
      _logger.severe("Error initializing map screen", e, s);
    }
  }

  Future<void> getFiles() async {
    allImages = await SearchService.instance.getAllFiles();
  }

  // Simple function to estimate zoom level
  double estimateZoomLevel(
    double range,
    double maxRange,
    double minZoom,
    double maxZoom,
  ) {
    if (range >= maxRange) return minZoom;
    return maxZoom - ((range / maxRange) * (maxZoom - minZoom));
  }

  void processFiles(List<File> files) {
    late double minLat, maxLat, minLon, maxLon;
    final List<ImageMarker> tempMarkers = [];
    bool hasAnyLocation = false;
    for (var file in files) {
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
      final double latZoom = estimateZoomLevel(maxLat - minLat, 90, 0, 19);
      final double lonZoom = estimateZoomLevel(maxLon - minLon, 180, 0, 19);
      initialZoom = min(latZoom, lonZoom);
      if (kDebugMode) {
        debugPrint("Info for map: center $center, initialZoom $initialZoom");
        debugPrint("Info for map: minLat $minLat, maxLat $maxLat");
        debugPrint("Info for map: minLon $minLon, maxLon $maxLon");
      }
    }

    setState(() {
      imageMarkers = tempMarkers;
      isLoading = false;
    });
    updateVisibleImages(mapController.bounds!);
  }

  void updateVisibleImages(LatLngBounds bounds) async {
    final images = imageMarkers
        .where((imageMarker) {
          final point = LatLng(imageMarker.latitude, imageMarker.longitude);
          return bounds.contains(point);
        })
        .map((imageMarker) => imageMarker.imageFile)
        .toList();

    setState(() {
      visibleImages = images;
    });
  }

  String formatNumber(int number) {
    if (number <= 99) {
      return number.toString();
    } else if (number <= 999) {
      return '${(number / 100).toStringAsFixed(0)}00+';
    } else if (number >= 1000 && number < 2000) {
      return '1K+';
    } else {
      final int thousands = ((number - 1) ~/ 1000);
      return '${thousands}K+';
    }
  }

  void onTap(File image, int index) {
    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable(visibleImages),
        (
          creationStartTime,
          creationEndTime, {
          limit,
          asc,
        }) async {
          final result = FileLoadResult(allImages, false);
          return result;
        },
        index,
        'Map',
      ),
    );

    routeToPage(
      context,
      page,
      forceCustomPageRoute: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    _logger.info('Building with Zoom $initialZoom');
    return SafeArea(
      child: Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: MapView(
                    updateVisibleImages: updateVisibleImages,
                    controller: mapController,
                    imageMarkers: imageMarkers,
                    initialZoom: initialZoom,
                    center: center,
                  ),
                ),
                const SizedBox(
                  child: MapCredits(),
                ),
                SizedBox(
                  height: 120,
                  child: Center(
                    child: ListView.builder(
                      itemCount: visibleImages.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final image = visibleImages[index];
                        return InkWell(
                          onTap: () => onTap(image, index),
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            width: 100,
                            height: 100,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: ThumbnailWidget(image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                )
              ],
            ),
            isLoading
                ? Container(
                    color: Colors.black87,
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.green),
                    ),
                  )
                : const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
