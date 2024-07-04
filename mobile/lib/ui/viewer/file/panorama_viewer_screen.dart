import "dart:io";

import "package:flutter/material.dart";
import "package:panorama_viewer/panorama_viewer.dart";

class PanoramaViewerScreen extends StatelessWidget {
  const PanoramaViewerScreen({
    super.key,
    required this.file,
  });

  final File file;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PanoramaViewer(
        child: Image.file(
          file,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
