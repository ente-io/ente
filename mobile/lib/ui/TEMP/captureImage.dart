// import "dart:typed_data";
// import 'dart:ui' as ui;

// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

// class Captures {
//   static Future<Uint8List> capture(GlobalKey key) async {
//     final double pixelRatio =
//         MediaQuery.of(key.currentContext!).devicePixelRatio;
//     final RenderRepaintBoundary boundary =
//         key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
//     final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
//     final ByteData? byteData =
//         await image.toByteData(format: ui.ImageByteFormat.png);
//     final Uint8List pngBytes = byteData!.buffer.asUint8List();
//     print("PNG BYTES ====== ${pngBytes}");
//     return pngBytes;
//   }
// }
import "dart:io";
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import "package:path_provider/path_provider.dart";

class Captures {
  Future<Uint8List?> capture(GlobalKey key) async {
    try {
      final double pixelRatio =
          MediaQuery.of(key.currentContext!).devicePixelRatio;
      final RenderRepaintBoundary boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      print("PNG BYTES ====== ${pngBytes}");

      return pngBytes;
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<String> saveImage(GlobalKey key) async {
    String path = "";
    try {
      final Uint8List? bytes = await capture(key);
      final Directory root = await getTemporaryDirectory();
      final String directoryPath = '${root.path}/enteTempFiles';
      // Create the directory if it doesn't exist
      final DateTime timeStamp = DateTime.now();
      await Directory(directoryPath).create(recursive: true);
      final String filePath = '$directoryPath/$timeStamp.jpg';
      final file = await File(filePath).writeAsBytes(bytes!);
      path = file.path;
    } catch (e) {
      debugPrint(e.toString());
    }
    return path;
  }
}
