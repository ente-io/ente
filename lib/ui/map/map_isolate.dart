import "dart:isolate";

import "package:flutter_map/flutter_map.dart";
import "package:photos/ui/map/image_marker.dart";

class MapIsolate {
  final LatLngBounds bounds;
  final List<ImageMarker> imageMarkers;
  final SendPort sendPort;

  MapIsolate({
    required this.bounds,
    required this.imageMarkers,
    required this.sendPort,
  });
}
