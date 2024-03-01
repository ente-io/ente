import "package:flutter/material.dart";
import "package:flutter_map/flutter_map.dart";
import "package:latlong2/latlong.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/map_view.dart";
import "package:photos/ui/map/marker_image.dart";

Marker mapMarker(
  ImageMarker imageMarker,
  String key, {
  Size markerSize = MapView.defaultMarkerSize,
}) {
  return Marker(
    //-6.5 is for taking in the height of the MarkerPointer
    anchorPos: AnchorPos.exactly(Anchor(markerSize.height / 2, -6.5)),
    key: Key(key),
    width: markerSize.width,
    height: markerSize.height,
    point: LatLng(
      imageMarker.latitude,
      imageMarker.longitude,
    ),
    builder: (context) => MarkerImage(
      file: imageMarker.imageFile,
      seperator: (MapView.defaultMarkerSize.height + 10) -
          (MapView.defaultMarkerSize.height - markerSize.height),
    ),
  );
}
