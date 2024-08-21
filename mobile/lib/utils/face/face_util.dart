import "dart:math";
import "dart:typed_data";

import "package:computer/computer.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:image/image.dart" as img;
import "package:logging/logging.dart";
import "package:photos/models/ml/face/box.dart";

/// Bounding box of a face.
///
/// [xMin] and [yMin] are the coordinates of the top left corner of the box, and
/// [width] and [height] are the width and height of the box.
///
/// One unit is equal to one pixel in the original image.
class FaceBoxImage {
  final int xMin;
  final int yMin;
  final int width;
  final int height;

  FaceBoxImage({
    required this.xMin,
    required this.yMin,
    required this.width,
    required this.height,
  });
}

final _logger = Logger("FaceUtil");
final _computer = Computer.shared();
const _faceImageBufferFactor = 0.2;

///Convert img.Image to ui.Image and use RawImage to display.
Future<List<img.Image>> generateImgFaceThumbnails(
  String imagePath,
  List<FaceBox> faceBoxes,
) async {
  final faceThumbnails = <img.Image>[];

  final image = await decodeToImgImage(imagePath);

  for (FaceBox faceBox in faceBoxes) {
    final croppedImage = cropFaceBoxFromImage(image, faceBox);
    faceThumbnails.add(croppedImage);
  }

  return faceThumbnails;
}

Future<List<Uint8List>> generateJpgFaceThumbnails(
  String imagePath,
  List<FaceBox> faceBoxes,
) async {
  final image = await decodeToImgImage(imagePath);
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
  final squareFaceBox = _getSquareFaceBoxImage(image, faceBox);
  final squareFaceBoxWithBuffer =
      _addBufferAroundFaceBox(squareFaceBox, _faceImageBufferFactor);
  return img.copyCrop(
    image,
    x: squareFaceBoxWithBuffer.xMin,
    y: squareFaceBoxWithBuffer.yMin,
    width: squareFaceBoxWithBuffer.width,
    height: squareFaceBoxWithBuffer.height,
    antialias: false,
  );
}

/// Returns a square face box image from the original image with
/// side length equal to the maximum of the width and height of the face box in
/// the OG image.
FaceBoxImage _getSquareFaceBoxImage(img.Image image, FaceBox faceBox) {
  final width = (image.width * faceBox.width).round();
  final height = (image.height * faceBox.height).round();
  final side = max(width, height);
  final xImage = (image.width * faceBox.x).round();
  final yImage = (image.height * faceBox.y).round();

  if (height >= width) {
    final xImageAdj = (xImage - (height - width) / 2).round();
    return FaceBoxImage(
      xMin: xImageAdj,
      yMin: yImage,
      width: side,
      height: side,
    );
  } else {
    final yImageAdj = (yImage - (width - height) / 2).round();
    return FaceBoxImage(
      xMin: xImage,
      yMin: yImageAdj,
      width: side,
      height: side,
    );
  }
}

///To add some buffer around the face box so that the face isn't cropped
///too close to the face.
FaceBoxImage _addBufferAroundFaceBox(
  FaceBoxImage faceBoxImage,
  double bufferFactor,
) {
  final heightBuffer = faceBoxImage.height * bufferFactor;
  final widthBuffer = faceBoxImage.width * bufferFactor;
  final xMinWithBuffer = faceBoxImage.xMin - widthBuffer;
  final yMinWithBuffer = faceBoxImage.yMin - heightBuffer;
  final widthWithBuffer = faceBoxImage.width + 2 * widthBuffer;
  final heightWithBuffer = faceBoxImage.height + 2 * heightBuffer;
  //Do not add buffer if the top left edge of the image is out of bounds
  //after adding the buffer.
  if (xMinWithBuffer < 0 || yMinWithBuffer < 0) {
    return faceBoxImage;
  }
  //Another similar case that can be handled is when the bottom right edge
  //of the image is out of bounds after adding the buffer. But the
  //the visual difference is not as significant as when the top left edge
  //is out of bounds, so we are not handling that case.
  return FaceBoxImage(
    xMin: xMinWithBuffer.round(),
    yMin: yMinWithBuffer.round(),
    width: widthWithBuffer.round(),
    height: heightWithBuffer.round(),
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
