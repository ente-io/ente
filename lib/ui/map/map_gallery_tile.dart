
import "package:flutter/material.dart";
import "package:photos/ui/map/image_marker.dart";
import "package:photos/ui/map/marker_image.dart";

class MapGalleryTile extends StatelessWidget {
  final ImageMarker imageMarker;

  const MapGalleryTile({super.key, required this.imageMarker});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.black,
      ),
      child: MarkerImage(
        key: key,
        file: imageMarker.imageFile,
        seperator: 65,
      ),
    );
  }
}
