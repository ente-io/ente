import "dart:io";

import "package:flutter/painting.dart";

Future<bool> checkIfPanorama(File file) async {
  final image = await decodeImageFromList(await file.readAsBytes());
  final width = image.width.toDouble();
  final height = image.height.toDouble();

  if (height > width) {
    return height / width >= 2.0;
  }
  return width / height >= 2.0;
}
