import "dart:async";
import "dart:developer" show log;
import "dart:math" show min;
import "dart:typed_data" show Float32List, Uint8List, ByteData;
import "dart:ui";

import 'package:flutter/painting.dart' as paint show decodeImageFromList;
import 'package:ml_linalg/linalg.dart';
import "package:photos/face/model/box.dart";
import "package:photos/face/model/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_alignment/similarity_transform.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/blur_detection_service.dart';

/// All of the functions in this file are helper functions for using inside an isolate.
/// Don't use them outside of a isolate, unless you are okay with UI jank!!!!

/// Decodes [Uint8List] image data to an ui.[Image] object.
Future<Image> decodeImageFromData(Uint8List imageData) async {
  // Decoding using flutter paint. This is the fastest and easiest method.
  final Image image = await paint.decodeImageFromList(imageData);
  return image;

  // // Similar decoding as above, but without using flutter paint. This is not faster than the above.
  // final Codec codec = await instantiateImageCodecFromBuffer(
  //   await ImmutableBuffer.fromUint8List(imageData),
  // );
  // final FrameInfo frameInfo = await codec.getNextFrame();
  // return frameInfo.image;

  // Decoding using the ImageProvider, same as `image_pixels` package. This is not faster than the above.
  // final Completer<Image> completer = Completer<Image>();
  // final ImageProvider provider = MemoryImage(imageData);
  // final ImageStream stream = provider.resolve(const ImageConfiguration());
  // final ImageStreamListener listener =
  //     ImageStreamListener((ImageInfo info, bool _) {
  //   completer.complete(info.image);
  // });
  // stream.addListener(listener);
  // final Image image = await completer.future;
  // stream.removeListener(listener);
  // return image;

  // // Decoding using the ImageProvider from material.Image. This is not faster than the above, and also the code below is not finished!
  // final materialImage = material.Image.memory(imageData);
  // final ImageProvider uiImage = await materialImage.image;
}

/// Returns the [ByteData] object of the image, in rawRgba format.
///
/// Throws an exception if the image could not be converted to ByteData.
Future<ByteData> getByteDataFromImage(
  Image image, {
  ImageByteFormat format = ImageByteFormat.rawRgba,
}) async {
  final ByteData? byteDataRgba = await image.toByteData(format: format);
  if (byteDataRgba == null) {
    log('[ImageMlUtils] Could not convert image to ByteData');
    throw Exception('Could not convert image to ByteData');
  }
  return byteDataRgba;
}

/// Generates a face thumbnail from [imageData] and [faceBoxes].
///
/// Returns a [Uint8List] image, in png format.
Future<List<Uint8List>> generateFaceThumbnailsUsingCanvas(
  Uint8List imageData,
  List<FaceBox> faceBoxes,
) async {
  final Image img = await decodeImageFromData(imageData);
  int i = 0;

  try {
    final futureFaceThumbnails = <Future<Uint8List>>[];
    for (final faceBox in faceBoxes) {
      // Note that the faceBox values are relative to the image size, so we need to convert them to absolute values first
      final double xMinAbs = faceBox.x * img.width;
      final double yMinAbs = faceBox.y * img.height;
      final double widthAbs = faceBox.width * img.width;
      final double heightAbs = faceBox.height * img.height;

      // Calculate the crop values by adding some padding around the face and making sure it's centered
      const regularPadding = 0.4;
      const minimumPadding = 0.1;
      final num xCrop = (xMinAbs - widthAbs * regularPadding);
      final num xOvershoot = min(0, xCrop).abs() / widthAbs;
      final num widthCrop = widthAbs * (1 + 2 * regularPadding) -
          2 * min(xOvershoot, regularPadding - minimumPadding) * widthAbs;
      final num yCrop = (yMinAbs - heightAbs * regularPadding);
      final num yOvershoot = min(0, yCrop).abs() / heightAbs;
      final num heightCrop = heightAbs * (1 + 2 * regularPadding) -
          2 * min(yOvershoot, regularPadding - minimumPadding) * heightAbs;

      // Prevent the face from going out of image bounds
      final xCropSafe = xCrop.clamp(0, img.width);
      final yCropSafe = yCrop.clamp(0, img.height);
      final widthCropSafe = widthCrop.clamp(0, img.width - xCropSafe);
      final heightCropSafe = heightCrop.clamp(0, img.height - yCropSafe);

      futureFaceThumbnails.add(
        _cropAndEncodeCanvas(
          img,
          x: xCropSafe.toDouble(),
          y: yCropSafe.toDouble(),
          width: widthCropSafe.toDouble(),
          height: heightCropSafe.toDouble(),
        ),
      );
      i++;
    }
    final List<Uint8List> faceThumbnails =
        await Future.wait(futureFaceThumbnails);
    return faceThumbnails;
  } catch (e) {
    log('[ImageMlUtils] Error generating face thumbnails: $e');
    log('[ImageMlUtils] cropImage problematic input argument: ${faceBoxes[i]}');
    return [];
  }
}

Future<(Float32List, Dimensions, Dimensions)>
    preprocessImageToFloat32ChannelsFirst(
  Image image,
  ByteData imgByteData, {
  required int normalization,
  required int requiredWidth,
  required int requiredHeight,
  Color Function(num, num, Image, ByteData) getPixel = _getPixelBilinear,
  maintainAspectRatio = true,
}) async {
  final normFunction = normalization == 2
      ? _normalizePixelRange2
      : normalization == 1
          ? _normalizePixelRange1
          : _normalizePixelNoRange;
  final originalSize = Dimensions(width: image.width, height: image.height);

  if (image.width == requiredWidth && image.height == requiredHeight) {
    return (
      _createFloat32ListFromImageChannelsFirst(
        image,
        imgByteData,
        normFunction: normFunction,
      ),
      originalSize,
      originalSize
    );
  }

  double scaleW = requiredWidth / image.width;
  double scaleH = requiredHeight / image.height;
  if (maintainAspectRatio) {
    final scale =
        min(requiredWidth / image.width, requiredHeight / image.height);
    scaleW = scale;
    scaleH = scale;
  }
  final scaledWidth = (image.width * scaleW).round().clamp(0, requiredWidth);
  final scaledHeight = (image.height * scaleH).round().clamp(0, requiredHeight);

  final processedBytes = Float32List(3 * requiredHeight * requiredWidth);

  final buffer = Float32List.view(processedBytes.buffer);
  int pixelIndex = 0;
  final int channelOffsetGreen = requiredHeight * requiredWidth;
  final int channelOffsetBlue = 2 * requiredHeight * requiredWidth;
  for (var h = 0; h < requiredHeight; h++) {
    for (var w = 0; w < requiredWidth; w++) {
      late Color pixel;
      if (w >= scaledWidth || h >= scaledHeight) {
        pixel = const Color.fromRGBO(114, 114, 114, 1.0);
      } else {
        pixel = getPixel(
          w / scaleW,
          h / scaleH,
          image,
          imgByteData,
        );
      }
      buffer[pixelIndex] = normFunction(pixel.red);
      buffer[pixelIndex + channelOffsetGreen] = normFunction(pixel.green);
      buffer[pixelIndex + channelOffsetBlue] = normFunction(pixel.blue);
      pixelIndex++;
    }
  }

  return (
    processedBytes,
    originalSize,
    Dimensions(width: scaledWidth, height: scaledHeight)
  );
}

Future<(Float32List, List<AlignmentResult>, List<bool>, List<double>, Size)>
    preprocessToMobileFaceNetFloat32List(
  Image image,
  ByteData imageByteData,
  List<FaceDetectionRelative> relativeFaces, {
  int width = 112,
  int height = 112,
}) async {
  final stopwatch = Stopwatch()..start();

  final Size originalSize =
      Size(image.width.toDouble(), image.height.toDouble());

  final List<FaceDetectionAbsolute> absoluteFaces =
      relativeToAbsoluteDetections(
    relativeDetections: relativeFaces,
    imageWidth: image.width,
    imageHeight: image.height,
  );

  final alignedImagesFloat32List =
      Float32List(3 * width * height * absoluteFaces.length);
  final alignmentResults = <AlignmentResult>[];
  final isBlurs = <bool>[];
  final blurValues = <double>[];

  int alignedImageIndex = 0;
  for (final face in absoluteFaces) {
    final (alignmentResult, correctlyEstimated) =
        SimilarityTransform.estimate(face.allKeypoints);
    if (!correctlyEstimated) {
      log('Face alignment failed because not able to estimate SimilarityTransform, for face: $face');
      throw Exception('Face alignment failed because not able to estimate SimilarityTransform');
    }
    alignmentResults.add(alignmentResult);

    _warpAffineFloat32List(
      image,
      imageByteData,
      alignmentResult.affineMatrix,
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    final blurDetectionStopwatch = Stopwatch()..start();
    final faceGrayMatrix = _createGrayscaleIntMatrixFromNormalized2List(
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    alignedImageIndex += 3 * width * height;
    final grayscalems = blurDetectionStopwatch.elapsedMilliseconds;
    log('creating grayscale matrix took $grayscalems ms');
    final (isBlur, blurValue) =
        await BlurDetectionService.predictIsBlurGrayLaplacian(
      faceGrayMatrix,
      faceDirection: face.getFaceDirection(),
    );
    final blurms = blurDetectionStopwatch.elapsedMilliseconds - grayscalems;
    log('blur detection took $blurms ms');
    log(
      'total blur detection took ${blurDetectionStopwatch.elapsedMilliseconds} ms',
    );
    blurDetectionStopwatch.stop();
    isBlurs.add(isBlur);
    blurValues.add(blurValue);
  }
  stopwatch.stop();
  log("Face Alignment took: ${stopwatch.elapsedMilliseconds} ms");
  return (
    alignedImagesFloat32List,
    alignmentResults,
    isBlurs,
    blurValues,
    originalSize
  );
}

/// Reads the pixel color at the specified coordinates.
Color _readPixelColor(
  Image image,
  ByteData byteData,
  int x,
  int y,
) {
  if (x < 0 || x >= image.width || y < 0 || y >= image.height) {
    // throw ArgumentError('Invalid pixel coordinates.');
    if (y != -1) {
      log('[WARNING] `readPixelColor`: Invalid pixel coordinates, out of bounds');
    }
    return const Color.fromARGB(0, 0, 0, 0);
  }
  assert(byteData.lengthInBytes == 4 * image.width * image.height);

  final int byteOffset = 4 * (image.width * y + x);
  return Color(_rgbaToArgb(byteData.getUint32(byteOffset)));
}

int _rgbaToArgb(int rgbaColor) {
  final int a = rgbaColor & 0xFF;
  final int rgb = rgbaColor >> 8;
  return rgb + (a << 24);
}

List<List<int>> _createGrayscaleIntMatrixFromNormalized2List(
  Float32List imageList,
  int startIndex, {
  int width = 112,
  int height = 112,
}) {
  return List.generate(
    height,
    (y) => List.generate(
      width,
      (x) {
        // 0.299 ∙ Red + 0.587 ∙ Green + 0.114 ∙ Blue
        final pixelIndex = startIndex + 3 * (y * width + x);
        return (0.299 * _unnormalizePixelRange2(imageList[pixelIndex]) +
                0.587 * _unnormalizePixelRange2(imageList[pixelIndex + 1]) +
                0.114 * _unnormalizePixelRange2(imageList[pixelIndex + 2]))
            .round()
            .clamp(0, 255);
        // return unnormalizePixelRange2(
        //   (0.299 * imageList[pixelIndex] +
        //       0.587 * imageList[pixelIndex + 1] +
        //       0.114 * imageList[pixelIndex + 2]),
        // ).round().clamp(0, 255);
      },
    ),
  );
}

Float32List _createFloat32ListFromImageChannelsFirst(
  Image image,
  ByteData byteDataRgba, {
  double Function(num) normFunction = _normalizePixelRange2,
}) {
  final convertedBytes = Float32List(3 * image.height * image.width);
  final buffer = Float32List.view(convertedBytes.buffer);

  int pixelIndex = 0;
  final int channelOffsetGreen = image.height * image.width;
  final int channelOffsetBlue = 2 * image.height * image.width;
  for (var h = 0; h < image.height; h++) {
    for (var w = 0; w < image.width; w++) {
      final pixel = _readPixelColor(image, byteDataRgba, w, h);
      buffer[pixelIndex] = normFunction(pixel.red);
      buffer[pixelIndex + channelOffsetGreen] = normFunction(pixel.green);
      buffer[pixelIndex + channelOffsetBlue] = normFunction(pixel.blue);
      pixelIndex++;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

/// Function normalizes the pixel value to be in range [-1, 1].
///
/// It assumes that the pixel value is originally in range [0, 255]
double _normalizePixelRange2(num pixelValue) {
  return (pixelValue / 127.5) - 1;
}

/// Function unnormalizes the pixel value to be in range [0, 255].
///
/// It assumes that the pixel value is originally in range [-1, 1]
int _unnormalizePixelRange2(double pixelValue) {
  return ((pixelValue + 1) * 127.5).round().clamp(0, 255);
}

/// Function normalizes the pixel value to be in range [0, 1].
///
/// It assumes that the pixel value is originally in range [0, 255]
double _normalizePixelRange1(num pixelValue) {
  return (pixelValue / 255);
}

double _normalizePixelNoRange(num pixelValue) {
  return pixelValue.toDouble();
}

/// Encodes an [Image] object to a [Uint8List], by default in the png format.
///
/// Note that the result can be used with `Image.memory()` only if the [format] is png.
Future<Uint8List> _encodeImageToUint8List(
  Image image, {
  ImageByteFormat format = ImageByteFormat.png,
}) async {
  final ByteData byteDataPng =
      await getByteDataFromImage(image, format: format);
  final encodedImage = byteDataPng.buffer.asUint8List();

  return encodedImage;
}

Future<Image> _cropImage(
  Image image, {
  required double x,
  required double y,
  required double width,
  required double height,
}) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(width, height),
    ),
  );

  canvas.drawImageRect(
    image,
    Rect.fromPoints(
      Offset(x, y),
      Offset(x + width, y + height),
    ),
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(width, height),
    ),
    Paint()..filterQuality = FilterQuality.medium,
  );

  final picture = recorder.endRecording();
  return picture.toImage(width.toInt(), height.toInt());
}

void _warpAffineFloat32List(
  Image inputImage,
  ByteData imgByteDataRgba,
  List<List<double>> affineMatrix,
  Float32List outputList,
  int startIndex, {
  int width = 112,
  int height = 112,
}) {
  if (width != 112 || height != 112) {
    throw Exception(
      'Width and height must be 112, other transformations are not supported yet.',
    );
  }

  final transformationMatrix = affineMatrix
      .map(
        (row) => row.map((e) {
          if (e != 1.0) {
            return e * 112;
          } else {
            return 1.0;
          }
        }).toList(),
      )
      .toList();

  final A = Matrix.fromList([
    [transformationMatrix[0][0], transformationMatrix[0][1]],
    [transformationMatrix[1][0], transformationMatrix[1][1]],
  ]);
  final aInverse = A.inverse();
  // final aInverseMinus = aInverse * -1;
  final B = Vector.fromList(
    [transformationMatrix[0][2], transformationMatrix[1][2]],
  );
  final b00 = B[0];
  final b10 = B[1];
  final a00Prime = aInverse[0][0];
  final a01Prime = aInverse[0][1];
  final a10Prime = aInverse[1][0];
  final a11Prime = aInverse[1][1];

  for (int yTrans = 0; yTrans < height; ++yTrans) {
    for (int xTrans = 0; xTrans < width; ++xTrans) {
      // Perform inverse affine transformation (original implementation, intuitive but slow)
      // final X = aInverse * (Vector.fromList([xTrans, yTrans]) - B);
      // final X = aInverseMinus * (B - [xTrans, yTrans]);
      // final xList = X.asFlattenedList;
      // num xOrigin = xList[0];
      // num yOrigin = xList[1];

      // Perform inverse affine transformation (fast implementation, less intuitive)
      final num xOrigin = (xTrans - b00) * a00Prime + (yTrans - b10) * a01Prime;
      final num yOrigin = (xTrans - b00) * a10Prime + (yTrans - b10) * a11Prime;

      final Color pixel =
          _getPixelBicubic(xOrigin, yOrigin, inputImage, imgByteDataRgba);

      // Set the new pixel
      outputList[startIndex + 3 * (yTrans * width + xTrans)] =
          _normalizePixelRange2(pixel.red);
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 1] =
          _normalizePixelRange2(pixel.green);
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 2] =
          _normalizePixelRange2(pixel.blue);
    }
  }
}

Future<Uint8List> _cropAndEncodeCanvas(
  Image image, {
  required double x,
  required double y,
  required double width,
  required double height,
}) async {
  final croppedImage = await _cropImage(
    image,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  return await _encodeImageToUint8List(
    croppedImage,
    format: ImageByteFormat.png,
  );
}

Color _getPixelBilinear(num fx, num fy, Image image, ByteData byteDataRgba) {
  // Clamp to image boundaries
  fx = fx.clamp(0, image.width - 1);
  fy = fy.clamp(0, image.height - 1);

  // Get the surrounding coordinates and their weights
  final int x0 = fx.floor();
  final int x1 = fx.ceil();
  final int y0 = fy.floor();
  final int y1 = fy.ceil();
  final dx = fx - x0;
  final dy = fy - y0;
  final dx1 = 1.0 - dx;
  final dy1 = 1.0 - dy;

  // Get the original pixels
  final Color pixel1 = _readPixelColor(image, byteDataRgba, x0, y0);
  final Color pixel2 = _readPixelColor(image, byteDataRgba, x1, y0);
  final Color pixel3 = _readPixelColor(image, byteDataRgba, x0, y1);
  final Color pixel4 = _readPixelColor(image, byteDataRgba, x1, y1);

  int bilinear(
    num val1,
    num val2,
    num val3,
    num val4,
  ) =>
      (val1 * dx1 * dy1 + val2 * dx * dy1 + val3 * dx1 * dy + val4 * dx * dy)
          .round();

  // Calculate the weighted sum of pixels
  final int r = bilinear(pixel1.red, pixel2.red, pixel3.red, pixel4.red);
  final int g =
      bilinear(pixel1.green, pixel2.green, pixel3.green, pixel4.green);
  final int b = bilinear(pixel1.blue, pixel2.blue, pixel3.blue, pixel4.blue);

  return Color.fromRGBO(r, g, b, 1.0);
}

/// Get the pixel value using Bicubic Interpolation. Code taken mainly from https://github.com/brendan-duncan/image/blob/6e407612752ffdb90b28cd5863c7f65856349348/lib/src/image/image.dart#L697
Color _getPixelBicubic(num fx, num fy, Image image, ByteData byteDataRgba) {
  fx = fx.clamp(0, image.width - 1);
  fy = fy.clamp(0, image.height - 1);

  final x = fx.toInt() - (fx >= 0.0 ? 0 : 1);
  final px = x - 1;
  final nx = x + 1;
  final ax = x + 2;
  final y = fy.toInt() - (fy >= 0.0 ? 0 : 1);
  final py = y - 1;
  final ny = y + 1;
  final ay = y + 2;
  final dx = fx - x;
  final dy = fy - y;
  num cubic(num dx, num ipp, num icp, num inp, num iap) =>
      icp +
      0.5 *
          (dx * (-ipp + inp) +
              dx * dx * (2 * ipp - 5 * icp + 4 * inp - iap) +
              dx * dx * dx * (-ipp + 3 * icp - 3 * inp + iap));

  final icc = _readPixelColor(image, byteDataRgba, x, y);

  final ipp =
      px < 0 || py < 0 ? icc : _readPixelColor(image, byteDataRgba, px, py);
  final icp = px < 0 ? icc : _readPixelColor(image, byteDataRgba, x, py);
  final inp = py < 0 || nx >= image.width
      ? icc
      : _readPixelColor(image, byteDataRgba, nx, py);
  final iap = ax >= image.width || py < 0
      ? icc
      : _readPixelColor(image, byteDataRgba, ax, py);

  final ip0 = cubic(dx, ipp.red, icp.red, inp.red, iap.red);
  final ip1 = cubic(dx, ipp.green, icp.green, inp.green, iap.green);
  final ip2 = cubic(dx, ipp.blue, icp.blue, inp.blue, iap.blue);
  // final ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

  final ipc = px < 0 ? icc : _readPixelColor(image, byteDataRgba, px, y);
  final inc =
      nx >= image.width ? icc : _readPixelColor(image, byteDataRgba, nx, y);
  final iac =
      ax >= image.width ? icc : _readPixelColor(image, byteDataRgba, ax, y);

  final ic0 = cubic(dx, ipc.red, icc.red, inc.red, iac.red);
  final ic1 = cubic(dx, ipc.green, icc.green, inc.green, iac.green);
  final ic2 = cubic(dx, ipc.blue, icc.blue, inc.blue, iac.blue);
  // final ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

  final ipn = px < 0 || ny >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, px, ny);
  final icn =
      ny >= image.height ? icc : _readPixelColor(image, byteDataRgba, x, ny);
  final inn = nx >= image.width || ny >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, nx, ny);
  final ian = ax >= image.width || ny >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, ax, ny);

  final in0 = cubic(dx, ipn.red, icn.red, inn.red, ian.red);
  final in1 = cubic(dx, ipn.green, icn.green, inn.green, ian.green);
  final in2 = cubic(dx, ipn.blue, icn.blue, inn.blue, ian.blue);
  // final in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

  final ipa = px < 0 || ay >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, px, ay);
  final ica =
      ay >= image.height ? icc : _readPixelColor(image, byteDataRgba, x, ay);
  final ina = nx >= image.width || ay >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, nx, ay);
  final iaa = ax >= image.width || ay >= image.height
      ? icc
      : _readPixelColor(image, byteDataRgba, ax, ay);

  final ia0 = cubic(dx, ipa.red, ica.red, ina.red, iaa.red);
  final ia1 = cubic(dx, ipa.green, ica.green, ina.green, iaa.green);
  final ia2 = cubic(dx, ipa.blue, ica.blue, ina.blue, iaa.blue);
  // final ia3 = cubic(dx, ipa.a, ica.a, ina.a, iaa.a);

  final c0 = cubic(dy, ip0, ic0, in0, ia0).clamp(0, 255).toInt();
  final c1 = cubic(dy, ip1, ic1, in1, ia1).clamp(0, 255).toInt();
  final c2 = cubic(dy, ip2, ic2, in2, ia2).clamp(0, 255).toInt();
  // final c3 = cubic(dy, ip3, ic3, in3, ia3);

  return Color.fromRGBO(c0, c1, c2, 1.0);
}