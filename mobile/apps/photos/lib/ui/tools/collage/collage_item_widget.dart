import "package:flutter/material.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/ui/viewer/file/zoomable_image.dart";

class CollageItemWidget extends StatelessWidget {
  const CollageItemWidget(
    this.file, {
    super.key,
  });

  final EnteFile file;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      child: ZoomableImage(
        file,
        backgroundDecoration: const BoxDecoration(
          color: Colors.transparent,
        ),
        tagPrefix: "collage_",
        shouldCover: true,
      ),
    );
  }
}
