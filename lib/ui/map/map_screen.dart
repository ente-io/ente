import "dart:async";
import "dart:math";

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import "package:latlong2/latlong.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/services/ignored_files_service.dart";
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

  @override
  void initState() {
    super.initState();
    initialize();
  }

  void initialize() async {
    await getFiles();
    processFiles(allImages);
  }

  Future<void> getFiles() async {
    final ignoredIDs = await IgnoredFilesService.instance.ignoredIDs;
    final ignoredIntIDs = <int>{};
    for (var element in ignoredIDs) {
      ignoredIntIDs.add(int.parse(element));
    }
    allImages = await FilesDB.instance.getAllFilesFromDB(ignoredIntIDs);
  }

  void processFiles(List<File> files) {
    final List<ImageMarker> tempMarkers = [];
    for (var file in files) {
      // if (file.hasLocation && location != null) {
      final rand = Random();
      tempMarkers.add(
        ImageMarker(
          latitude: 10.786985 + rand.nextDouble() / 10,
          longitude: 78.6882166 + rand.nextDouble() / 10,
          imageFile: file,
        ),
      );
      // }
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
