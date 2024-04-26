import "dart:typed_data";

import "package:computer/computer.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:image/image.dart" as img;
import "package:logging/logging.dart";
import "package:photos/face/model/box.dart";

final _logger = Logger("FaceUtil");
final _computer = Computer.shared();

///Convert img.Image to ui.Image and use RawImage to display.
Future<List<img.Image>> generateImgFaceThumbnails(
  String imagePath,
  List<FaceBox> faceBoxes, {
  ///Pass decodedImage decoded by [decodeToImgImage] to avoid decoding image
  ///multiple times if all faces are from the same image (eg: File info).
  img.Image? decodedImage,
}) async {
  final faceThumbnails = <img.Image>[];

  final image = decodedImage ?? await decodeToImgImage(imagePath);

  for (FaceBox faceBox in faceBoxes) {
    final croppedImage = cropFaceBoxFromImage(image, faceBox);
    faceThumbnails.add(croppedImage);
  }

  return faceThumbnails;
}

Future<List<Uint8List>> generateJpgFaceThumbnails(
  String imagePath,
  List<FaceBox> faceBoxes, {
  ///Pass decodedImage decoded by [decodeToImgImage] to avoid decoding image
  ///multiple times if all faces are from the same image (eg: File info).
  img.Image? decodedImage,
}) async {
  final image = decodedImage ?? await decodeToImgImage(imagePath);
  final croppedImages = <img.Image>[];
  for (FaceBox faceBox in faceBoxes) {
    final croppedImage = cropFaceBoxFromImage(image, faceBox);
    croppedImages.add(croppedImage);
  }

  return await _computer
      .compute(_encodeImagesToJpg, param: {"images": croppedImages});
}

Future<img.Image> decodeToImgImage(String imagePath) async {
  img.Image? image =
      await _computer.compute(_decodeImageFile, param: {"filePath": imagePath});

  if (image == null) {
    _logger.info(
      "Failed to decode image. Compressing to jpg and decoding",
    );
    final compressedJPGImage =
        await FlutterImageCompress.compressWithFile(imagePath);
    image = await _computer.compute(
      _decodeJpg,
      param: {"image": compressedJPGImage},
    );

    if (image == null) {
      throw Exception("Failed to decode image");
    } else {
      return image;
    }
  } else {
    return image;
  }
}

/// Returns an Image from 'package:image/image.dart'
img.Image cropFaceBoxFromImage(img.Image image, FaceBox faceBox) {
  return img.copyCrop(
    image,
    x: (image.width * faceBox.xMin).round(),
    y: (image.height * faceBox.yMin).round(),
    width: (image.width * faceBox.width).round(),
    height: (image.height * faceBox.height).round(),
    antialias: false,
  );
}

List<Uint8List> _encodeImagesToJpg(Map args) {
  final images = args["images"] as List<img.Image>;
  return images.map((img.Image image) => img.encodeJpg(image)).toList();
}

Future<img.Image?> _decodeImageFile(Map args) async {
  return await img.decodeImageFile(args["filePath"]);
}

img.Image? _decodeJpg(Map args) {
  return img.decodeJpg(args["image"])!;
}
