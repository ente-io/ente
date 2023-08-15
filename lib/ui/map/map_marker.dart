import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/marker_image.dart";

Marker mapMarker(ImageMarker imageMarker, String key) {
  return Marker(
    key: Key(key),
    width: 75,
    height: 75,
    point: LatLng(
      imageMarker.latitude,
      imageMarker.longitude,
    ),
    builder: (context) => MarkerImage(
      file: imageMarker.imageFile,
      seperator: 85,
    ),
  );
}
