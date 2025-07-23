import "dart:async";
import "dart:io" show File, Platform;
import "dart:math" show max, min;
import "dart:typed_data" show Float32List, Uint8List;
import "dart:ui";

import "package:exif_reader/exif_reader.dart";
import 'package:flutter/painting.dart' as paint show decodeImageFromList;
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:logging/logging.dart";
import 'package:ml_linalg/linalg.dart';
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/dimension.dart";
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_alignment/similarity_transform.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/blur_detection_service.dart';

/// All of the functions in this file are helper functions for using inside an isolate.
/// Don't use them outside of a isolate, unless you are okay with UI jank!!!!

final _logger = Logger("ImageMlUtil");

/// These are 8 bit unsigned integers in range 0-255 for each RGB channel
typedef RGB = (int, int, int);

const List<String> supportedRustImageFormats = [
  'bmp',
  'dds',
  'farbfeld',
  'gif',
  'hdr',
  'ico',
  'jpg',
  'jpeg',
  'exr',
  'png',
  'pnm',
  'qoi',
  'tga',
  'tiff',
  'webp',
];

// Face thumbnail compression constants
const int _faceThumbnailCompressionQuality = 90;
const int _faceThumbnailMinDimension = 512;

class DecodedImage {
  final Image image;
  final Uint8List? rawRgbaBytes;

  const DecodedImage(this.image, [this.rawRgbaBytes]);
}

Future<DecodedImage> decodeImageFromPath(
  String imagePath, {
  required bool includeRgbaBytes,
}) async {
  final imageData = await File(imagePath).readAsBytes();

  final Map<String, IfdTag> exifData = await readExifFromBytes(imageData);
  final int orientation =
      exifData['Image Orientation']?.values.firstAsInt() ?? 1;
  if (orientation > 1 && includeRgbaBytes) {
    _logger.severe("Image EXIF orientation $orientation is not supported");
    throw Exception(
      'UnhandledExifOrientation: exif orientation $orientation',
    );
  }

  late Image image;
  try {
    image = await decodeImageFromData(imageData);
  } catch (e, s) {
    final format = imagePath.split('.').last;
    _logger.info(
      'Cannot decode $format on ${Platform.isAndroid ? "Android" : "iOS"}, converting to jpeg',
    );
    try {
      final Uint8List? convertedData =
          await FlutterImageCompress.compressWithFile(
        imagePath,
        format: CompressFormat.jpeg,
        minWidth: 20000, // High value to ensure image is not scaled down
        minHeight: 20000, // High value to ensure image is not scaled down
      );
      image = await decodeImageFromData(convertedData!);
      _logger.info('Conversion successful, jpeg decoded');
      if (image.width >= 20000 || image.height >= 20000) {
        // Failing and storing empty result when the image dimensions are higher than max compression limits
        _logger
            .severe('Image res too high, W:${image.width} H:${image.height}');
        throw Exception('Res too high W:${image.width} H:${image.height}');
      }
    } catch (e) {
      _logger.severe(
        'Error decoding image of format $format on ${Platform.isAndroid ? "Android" : "iOS"}',
        e,
        s,
      );
      throw Exception(
        'InvalidImageFormatException: Error decoding image of format $format',
      );
    }
  }
  if (!includeRgbaBytes) {
    return DecodedImage(image);
  }
  final rawRgbaBytes = await _getRawRgbaBytes(image);
  return DecodedImage(image, rawRgbaBytes);
}

bool canRustDecodeImage(String imagePath) {
  final format = imagePath.split('.').last;
  return supportedRustImageFormats.contains(format);
}

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
}

Future<Uint8List> _getRawRgbaBytes(Image image) async {
  return await _getByteDataFromImage(image, format: ImageByteFormat.rawRgba);
}

/// Encodes an [Image] object to a [Uint8List], in the png format.
/// Can be used with `Image.memory()`.
Future<Uint8List> _encodeImageToPng(Image image) async {
  return await _getByteDataFromImage(image, format: ImageByteFormat.png);
}

/// Returns the [ByteData] object of the image, in rawRgba format.
///
/// Throws an exception if the image could not be converted to ByteData.
Future<Uint8List> _getByteDataFromImage(
  Image image, {
  required ImageByteFormat format,
}) async {
  final byteData = await image.toByteData(format: format);
  if (byteData == null) {
    _logger.severe('Failed to get byte data in $format from image');
    throw Exception('Failed to get byte data in $format from image');
  }
  return byteData.buffer.asUint8List();
}

/// Generates a face thumbnail from [imageData] and [faceBoxes].
///
/// Returns a [Uint8List] image, in png format.
Future<List<Uint8List>> generateFaceThumbnailsUsingCanvas(
  String imagePath,
  List<FaceBox> faceBoxes,
) async {
  int i = 0; // Index of the faceBox, initialized here for logging purposes
  try {
    final decodedImage = await decodeImageFromPath(
      imagePath,
      includeRgbaBytes: false,
    );
    final Image img = decodedImage.image;
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
  } catch (e, s) {
    _logger.severe(
      'Error generating face thumbnails. cropImage problematic input argument: ${i}th facebox: ${faceBoxes[i].toString()}',
      e,
      s,
    );
    return [];
  }
}

Future<Float32List> resizedToPreprocessedYoloFace(
  Uint8List rgbBytes,
  int rgbWidth,
  int rgbHeight,
) async {
  const requiredWidth = 640;
  const requiredHeight = 640;
  final int letterboxWidth = requiredWidth - rgbWidth;
  final int letterboxHeight = requiredHeight - rgbHeight;
  final int letterboxWidthHalf = letterboxWidth ~/ 2;
  final int letterboxHeightHalf = letterboxHeight ~/ 2;

  final processedBytes = Float32List(3 * requiredHeight * requiredWidth);
  final buffer = Float32List.view(processedBytes.buffer);
  int pixelIndex = 0;
  const int channelOffsetGreen = requiredHeight * requiredWidth;
  const int channelOffsetBlue = 2 * requiredHeight * requiredWidth;
  for (var h = 0; h < requiredHeight; h++) {
    for (var w = 0; w < requiredWidth; w++) {
      late RGB pixel;
      if (w < letterboxWidthHalf ||
          w >= rgbWidth + letterboxWidthHalf ||
          h < letterboxHeightHalf ||
          h >= rgbHeight + letterboxHeightHalf) {
        pixel = const (114, 114, 114);
      } else {
        final int byteIndex = 3 *
            (rgbWidth * (h - letterboxHeightHalf) + (w - letterboxWidthHalf));
        pixel = (
          rgbBytes[byteIndex],
          rgbBytes[byteIndex + 1],
          rgbBytes[byteIndex + 2]
        );
      }
      buffer[pixelIndex] = pixel.$1 / 255;
      buffer[pixelIndex + channelOffsetGreen] = pixel.$2 / 255;
      buffer[pixelIndex + channelOffsetBlue] = pixel.$3 / 255;
      pixelIndex++;
    }
  }

  return processedBytes;
}

Future<Float32List> resizedToPreprocessedClip(
  Uint8List rgbBytes,
  int rgbWidth,
  int rgbHeight,
) async {
  const requiredWidth = 256;
  const requiredHeight = 256;

  final processedBytes = Float32List(3 * requiredHeight * requiredWidth);
  final buffer = Float32List.view(processedBytes.buffer);
  int pixelIndex = 0;
  const int channelOffsetGreen = requiredHeight * requiredWidth;
  const int channelOffsetBlue = 2 * requiredHeight * requiredWidth;
  final widthOffset = max(0, rgbWidth - requiredWidth) ~/ 2;
  final heightOffset = max(0, rgbHeight - requiredHeight) ~/ 2;
  for (var h = 0 + heightOffset; h < heightOffset + requiredHeight; h++) {
    for (var w = 0 + widthOffset; w < widthOffset + requiredWidth; w++) {
      final int byteIndex = 3 * (rgbWidth * h + w);
      final RGB pixel = (
        rgbBytes[byteIndex],
        rgbBytes[byteIndex + 1],
        rgbBytes[byteIndex + 2]
      );
      buffer[pixelIndex] = pixel.$1 / 255;
      buffer[pixelIndex + channelOffsetGreen] = pixel.$2 / 255;
      buffer[pixelIndex + channelOffsetBlue] = pixel.$3 / 255;
      pixelIndex++;
    }
  }

  return processedBytes;
}

Future<(Float32List, List<AlignmentResult>, List<bool>, List<double>, Size)>
    preprocessToMobileFaceNetFloat32List(
  Dimensions imageDimensions,
  Uint8List rawRgbaBytes,
  List<FaceDetectionRelative> relativeFaces, {
  int width = 112,
  int height = 112,
}) async {
  final Size originalSize =
      Size(imageDimensions.width.toDouble(), imageDimensions.height.toDouble());

  final List<FaceDetectionAbsolute> absoluteFaces =
      relativeToAbsoluteDetections(
    relativeDetections: relativeFaces,
    imageWidth: imageDimensions.width,
    imageHeight: imageDimensions.height,
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
      _logger.severe(
        'Face alignment failed because not able to estimate SimilarityTransform, for face: $face',
      );
      throw Exception(
        'Face alignment failed because not able to estimate SimilarityTransform',
      );
    }
    alignmentResults.add(alignmentResult);

    _warpAffineFloat32List(
      imageDimensions,
      rawRgbaBytes,
      alignmentResult.affineMatrix,
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    final faceGrayMatrix = _createGrayscaleIntMatrixFromNormalized2List(
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    alignedImageIndex += 3 * width * height;
    final (isBlur, blurValue) =
        await BlurDetectionService.predictIsBlurGrayLaplacian(
      faceGrayMatrix,
      faceDirection: face.getFaceDirection(),
    );
    isBlurs.add(isBlur);
    blurValues.add(blurValue);
  }
  return (
    alignedImagesFloat32List,
    alignmentResults,
    isBlurs,
    blurValues,
    originalSize
  );
}

/// Reads the pixel color at the specified coordinates.
RGB _readPixelColor(
  int x,
  int y,
  Dimensions image,
  Uint8List rgbaBytes,
) {
  if (y < 0 || y >= image.height || x < 0 || x >= image.width) {
    if (y < -2 || y >= image.height + 2 || x < -2 || x >= image.width + 2) {
      _logger.severe(
        '`readPixelColor`: Invalid pixel coordinates, out of bounds. x: $x, y: $y',
      );
    }
    return const (114, 114, 114);
  }

  assert(rgbaBytes.lengthInBytes == 4 * image.width * image.height);

  final int byteOffset = 4 * (image.width * y + x);
  return (
    rgbaBytes[byteOffset], // red
    rgbaBytes[byteOffset + 1], // green
    rgbaBytes[byteOffset + 2] // blue
  );
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
        return (0.299 * ((imageList[pixelIndex] + 1) * 127.5) +
                0.587 * ((imageList[pixelIndex + 1] + 1) * 127.5) +
                0.114 * ((imageList[pixelIndex + 2] + 1) * 127.5))
            .round()
            .clamp(0, 255);
      },
    ),
  );
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
  Dimensions inputImageDimensions,
  Uint8List rawRgbaBytes,
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

      final RGB pixel = _getPixelBicubic(
        xOrigin,
        yOrigin,
        inputImageDimensions,
        rawRgbaBytes,
      );

      // Set the new pixel
      outputList[startIndex + 3 * (yTrans * width + xTrans)] =
          (pixel.$1 / 127.5) - 1;
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 1] =
          (pixel.$2 / 127.5) - 1;
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 2] =
          (pixel.$3 / 127.5) - 1;
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
  return await _encodeImageToPng(croppedImage);
}

Future<List<Uint8List>> compressFaceThumbnails(Map args) async {
  final listPngBytes = args['listPngBytes'] as List<Uint8List>;
  final List<Future<Uint8List>> compressedBytesList = [];
  try {
    for (final pngBytes in listPngBytes) {
      final compressedBytes = FlutterImageCompress.compressWithList(
        pngBytes,
        quality: _faceThumbnailCompressionQuality,
        format: CompressFormat.jpeg,
        minWidth: _faceThumbnailMinDimension,
        minHeight: _faceThumbnailMinDimension,
      );
      compressedBytesList.add(compressedBytes);
    }
    return await Future.wait(compressedBytesList);
  } catch (e, s) {
    _logger.warning(
      'Failed to compress face thumbnail, using original. Size: ${listPngBytes.map((e) => e.length).toList()} bytes',
      e,
      s,
    );
    rethrow;
  }
}

RGB _getPixelBicubic(
  num fx,
  num fy,
  Dimensions imageDimensions,
  Uint8List rawRgbaBytes,
) {
  fx = fx.clamp(0, imageDimensions.width - 1);
  fy = fy.clamp(0, imageDimensions.height - 1);

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

  final icc = _readPixelColor(x, y, imageDimensions, rawRgbaBytes);

  final ipp = px < 0 || py < 0
      ? icc
      : _readPixelColor(px, py, imageDimensions, rawRgbaBytes);
  final icp =
      px < 0 ? icc : _readPixelColor(x, py, imageDimensions, rawRgbaBytes);
  final inp = py < 0 || nx >= imageDimensions.width
      ? icc
      : _readPixelColor(nx, py, imageDimensions, rawRgbaBytes);
  final iap = ax >= imageDimensions.width || py < 0
      ? icc
      : _readPixelColor(ax, py, imageDimensions, rawRgbaBytes);

  final ip0 = cubic(dx, ipp.$1, icp.$1, inp.$1, iap.$1);
  final ip1 = cubic(dx, ipp.$2, icp.$2, inp.$2, iap.$2);
  final ip2 = cubic(dx, ipp.$3, icp.$3, inp.$3, iap.$3);
  // final ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

  final ipc =
      px < 0 ? icc : _readPixelColor(px, y, imageDimensions, rawRgbaBytes);
  final inc = nx >= imageDimensions.width
      ? icc
      : _readPixelColor(nx, y, imageDimensions, rawRgbaBytes);
  final iac = ax >= imageDimensions.width
      ? icc
      : _readPixelColor(ax, y, imageDimensions, rawRgbaBytes);

  final ic0 = cubic(dx, ipc.$1, icc.$1, inc.$1, iac.$1);
  final ic1 = cubic(dx, ipc.$2, icc.$2, inc.$2, iac.$2);
  final ic2 = cubic(dx, ipc.$3, icc.$3, inc.$3, iac.$3);
  // final ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

  final ipn = px < 0 || ny >= imageDimensions.height
      ? icc
      : _readPixelColor(px, ny, imageDimensions, rawRgbaBytes);
  final icn = ny >= imageDimensions.height
      ? icc
      : _readPixelColor(x, ny, imageDimensions, rawRgbaBytes);
  final inn = nx >= imageDimensions.width || ny >= imageDimensions.height
      ? icc
      : _readPixelColor(nx, ny, imageDimensions, rawRgbaBytes);
  final ian = ax >= imageDimensions.width || ny >= imageDimensions.height
      ? icc
      : _readPixelColor(ax, ny, imageDimensions, rawRgbaBytes);

  final in0 = cubic(dx, ipn.$1, icn.$1, inn.$1, ian.$1);
  final in1 = cubic(dx, ipn.$2, icn.$2, inn.$2, ian.$2);
  final in2 = cubic(dx, ipn.$3, icn.$3, inn.$3, ian.$3);
  // final in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

  final ipa = px < 0 || ay >= imageDimensions.height
      ? icc
      : _readPixelColor(px, ay, imageDimensions, rawRgbaBytes);
  final ica = ay >= imageDimensions.height
      ? icc
      : _readPixelColor(x, ay, imageDimensions, rawRgbaBytes);
  final ina = nx >= imageDimensions.width || ay >= imageDimensions.height
      ? icc
      : _readPixelColor(nx, ay, imageDimensions, rawRgbaBytes);
  final iaa = ax >= imageDimensions.width || ay >= imageDimensions.height
      ? icc
      : _readPixelColor(ax, ay, imageDimensions, rawRgbaBytes);

  final ia0 = cubic(dx, ipa.$1, ica.$1, ina.$1, iaa.$1);
  final ia1 = cubic(dx, ipa.$2, ica.$2, ina.$2, iaa.$2);
  final ia2 = cubic(dx, ipa.$3, ica.$3, ina.$3, iaa.$3);
  // final ia3 = cubic(dx, ipa.a, ica.a, ina.a, iaa.a);

  final c0 = cubic(dy, ip0, ic0, in0, ia0).clamp(0, 255).toInt();
  final c1 = cubic(dy, ip1, ic1, in1, ia1).clamp(0, 255).toInt();
  final c2 = cubic(dy, ip2, ic2, in2, ia2).clamp(0, 255).toInt();
  // final c3 = cubic(dy, ip3, ic3, in3, ia3);

  return (c0, c1, c2); // (red, green, blue)
}
