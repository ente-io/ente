import "package:flutter/material.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/marker_image.dart";

class MapGalleryTile extends StatelessWidget {
  final ImageMarker imageMarker;

  const MapGalleryTile({super.key, required this.imageMarker});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(8),
      child: MarkerImage(
        key: super.key,
        file: imageMarker.imageFile,
        seperator: 69,
      ),
    );
  }
}
