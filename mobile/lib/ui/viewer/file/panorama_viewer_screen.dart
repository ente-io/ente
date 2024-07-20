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
      appBar: AppBar(
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 18,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: PanoramaViewer(
        child: Image.file(
          file,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
