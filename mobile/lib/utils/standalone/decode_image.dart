import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';

Future<ui.Image?> decodeImageInIsolate(String imagePath) {
  return compute(_decodeImage, imagePath);
}

Future<ui.Image?> _decodeImage(String imagePath) async {
  try {
    final imageData = await File(imagePath).readAsBytes();
    final codec = await ui.instantiateImageCodec(imageData);
    final frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  } catch (e, s) {
    debugPrint("Failed to decode image at $imagePath: $e\n$s");
    return null;
  }
}
