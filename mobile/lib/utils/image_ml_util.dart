import "dart:async";
import "dart:developer" show log;
import "dart:io" show File;
import "dart:math" show min, max;
import "dart:typed_data" show Float32List, Uint8List, ByteData;
import "dart:ui";

// import 'package:flutter/material.dart'
//     show
//         ImageProvider,
//         ImageStream,
//         ImageStreamListener,
//         ImageInfo,
//         MemoryImage,
//         ImageConfiguration;
// import 'package:flutter/material.dart' as material show Image;
import 'package:flutter/painting.dart' as paint show decodeImageFromList;
import 'package:ml_linalg/linalg.dart';
import "package:photos/face/model/box.dart";
import "package:photos/face/model/dimension.dart";
import 'package:photos/models/ml/ml_typedefs.dart';
import 'package:photos/services/machine_learning/face_ml/face_alignment/alignment_result.dart';
import 'package:photos/services/machine_learning/face_ml/face_alignment/similarity_transform.dart';
import 'package:photos/services/machine_learning/face_ml/face_detection/detection.dart';
import 'package:photos/services/machine_learning/face_ml/face_filtering/blur_detection_service.dart';

/// All of the functions in this file are helper functions for the [ImageMlIsolate] isolate.
/// Don't use them outside of the isolate, unless you are okay with UI jank!!!!

/// Reads the pixel color at the specified coordinates.
Color readPixelColor(
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

void setPixelColor(
  Size imageSize,
  ByteData byteData,
  int x,
  int y,
  Color color,
) {
  if (x < 0 || x >= imageSize.width || y < 0 || y >= imageSize.height) {
    log('[WARNING] `setPixelColor`: Invalid pixel coordinates, out of bounds');
    return;
  }
  assert(byteData.lengthInBytes == 4 * imageSize.width * imageSize.height);

  final int byteOffset = 4 * (imageSize.width.toInt() * y + x);
  byteData.setUint32(byteOffset, _argbToRgba(color.value));
}

int _rgbaToArgb(int rgbaColor) {
  final int a = rgbaColor & 0xFF;
  final int rgb = rgbaColor >> 8;
  return rgb + (a << 24);
}

int _argbToRgba(int argbColor) {
  final int r = (argbColor >> 16) & 0xFF;
  final int g = (argbColor >> 8) & 0xFF;
  final int b = argbColor & 0xFF;
  final int a = (argbColor >> 24) & 0xFF;
  return (r << 24) + (g << 16) + (b << 8) + a;
}

@Deprecated('Used in TensorFlow Lite only, no longer needed')

/// Creates an empty matrix with the specified shape.
///
/// The `shape` argument must be a list of length 2 or 3, where the first
/// element represents the number of rows, the second element represents
/// the number of columns, and the optional third element represents the
/// number of channels. The function returns a matrix filled with zeros.
///
/// Throws an [ArgumentError] if the `shape` argument is invalid.
List createEmptyOutputMatrix(List<int> shape, [double fillValue = 0.0]) {
  if (shape.length > 5) {
    throw ArgumentError('Shape must have length 1-5');
  }

  if (shape.length == 1) {
    return List.filled(shape[0], fillValue);
  } else if (shape.length == 2) {
    return List.generate(shape[0], (_) => List.filled(shape[1], fillValue));
  } else if (shape.length == 3) {
    return List.generate(
      shape[0],
      (_) => List.generate(shape[1], (_) => List.filled(shape[2], fillValue)),
    );
  } else if (shape.length == 4) {
    return List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List.generate(shape[2], (_) => List.filled(shape[3], fillValue)),
      ),
    );
  } else if (shape.length == 5) {
    return List.generate(
      shape[0],
      (_) => List.generate(
        shape[1],
        (_) => List.generate(
          shape[2],
          (_) =>
              List.generate(shape[3], (_) => List.filled(shape[4], fillValue)),
        ),
      ),
    );
  } else {
    throw ArgumentError('Shape must have length 2 or 3');
  }
}

/// Creates an input matrix from the specified image, which can be used for inference
///
/// Returns a matrix with the shape [image.height, image.width, 3], where the third dimension represents the RGB channels, as [Num3DInputMatrix].
/// In fact, this is either a [Double3DInputMatrix] or a [Int3DInputMatrix] depending on the `normalize` argument.
/// If `normalize` is true, the pixel values are normalized doubles in range [-1, 1]. Otherwise, they are integers in range [0, 255].
///
/// The `image` argument must be an ui.[Image] object. The function returns a matrix
/// with the shape `[image.height, image.width, 3]`, where the third dimension
/// represents the RGB channels.
///
/// bool `normalize`: Normalize the image to range [-1, 1]
Num3DInputMatrix createInputMatrixFromImage(
  Image image,
  ByteData byteDataRgba, {
  double Function(num) normFunction = normalizePixelRange2,
}) {
  return List.generate(
    image.height,
    (y) => List.generate(
      image.width,
      (x) {
        final pixel = readPixelColor(image, byteDataRgba, x, y);
        return [
          normFunction(pixel.red),
          normFunction(pixel.green),
          normFunction(pixel.blue),
        ];
      },
    ),
  );
}

void addInputImageToFloat32List(
  Image image,
  ByteData byteDataRgba,
  Float32List float32List,
  int startIndex, {
  double Function(num) normFunction = normalizePixelRange2,
}) {
  int pixelIndex = startIndex;
  for (var h = 0; h < image.height; h++) {
    for (var w = 0; w < image.width; w++) {
      final pixel = readPixelColor(image, byteDataRgba, w, h);
      float32List[pixelIndex] = normFunction(pixel.red);
      float32List[pixelIndex + 1] = normFunction(pixel.green);
      float32List[pixelIndex + 2] = normFunction(pixel.blue);
      pixelIndex += 3;
    }
  }
  return;
}

List<List<int>> createGrayscaleIntMatrixFromImage(
  Image image,
  ByteData byteDataRgba,
) {
  return List.generate(
    image.height,
    (y) => List.generate(
      image.width,
      (x) {
        // 0.299 ∙ Red + 0.587 ∙ Green + 0.114 ∙ Blue
        final pixel = readPixelColor(image, byteDataRgba, x, y);
        return (0.299 * pixel.red + 0.587 * pixel.green + 0.114 * pixel.blue)
            .round()
            .clamp(0, 255);
      },
    ),
  );
}

List<List<int>> createGrayscaleIntMatrixFromNormalized2List(
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
        return (0.299 * unnormalizePixelRange2(imageList[pixelIndex]) +
                0.587 * unnormalizePixelRange2(imageList[pixelIndex + 1]) +
                0.114 * unnormalizePixelRange2(imageList[pixelIndex + 2]))
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

Float32List createFloat32ListFromImageChannelsFirst(
  Image image,
  ByteData byteDataRgba, {
  double Function(num) normFunction = normalizePixelRange2,
}) {
  final convertedBytes = Float32List(3 * image.height * image.width);
  final buffer = Float32List.view(convertedBytes.buffer);

  int pixelIndex = 0;
  final int channelOffsetGreen = image.height * image.width;
  final int channelOffsetBlue = 2 * image.height * image.width;
  for (var h = 0; h < image.height; h++) {
    for (var w = 0; w < image.width; w++) {
      final pixel = readPixelColor(image, byteDataRgba, w, h);
      buffer[pixelIndex] = normFunction(pixel.red);
      buffer[pixelIndex + channelOffsetGreen] = normFunction(pixel.green);
      buffer[pixelIndex + channelOffsetBlue] = normFunction(pixel.blue);
      pixelIndex++;
    }
  }
  return convertedBytes.buffer.asFloat32List();
}

/// Creates an input matrix from the specified image, which can be used for inference
///
/// Returns a matrix with the shape `[3, image.height, image.width]`, where the first dimension represents the RGB channels, as [Num3DInputMatrix].
/// In fact, this is either a [Double3DInputMatrix] or a [Int3DInputMatrix] depending on the `normalize` argument.
/// If `normalize` is true, the pixel values are normalized doubles in range [-1, 1]. Otherwise, they are integers in range [0, 255].
///
/// The `image` argument must be an ui.[Image] object. The function returns a matrix
/// with the shape `[3, image.height, image.width]`, where the first dimension
/// represents the RGB channels.
///
/// bool `normalize`: Normalize the image to range [-1, 1]
Num3DInputMatrix createInputMatrixFromImageChannelsFirst(
  Image image,
  ByteData byteDataRgba, {
  bool normalize = true,
}) {
  // Create an empty 3D list.
  final Num3DInputMatrix imageMatrix = List.generate(
    3,
    (i) => List.generate(
      image.height,
      (j) => List.filled(image.width, 0),
    ),
  );

  // Determine which function to use to get the pixel value.
  final pixelValue = normalize ? normalizePixelRange2 : (num value) => value;

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      // Get the pixel at (x, y).
      final pixel = readPixelColor(image, byteDataRgba, x, y);

      // Assign the color channels to the respective lists.
      imageMatrix[0][y][x] = pixelValue(pixel.red);
      imageMatrix[1][y][x] = pixelValue(pixel.green);
      imageMatrix[2][y][x] = pixelValue(pixel.blue);
    }
  }
  return imageMatrix;
}

/// Function normalizes the pixel value to be in range [-1, 1].
///
/// It assumes that the pixel value is originally in range [0, 255]
double normalizePixelRange2(num pixelValue) {
  return (pixelValue / 127.5) - 1;
}

/// Function unnormalizes the pixel value to be in range [0, 255].
///
/// It assumes that the pixel value is originally in range [-1, 1]
int unnormalizePixelRange2(double pixelValue) {
  return ((pixelValue + 1) * 127.5).round().clamp(0, 255);
}

/// Function normalizes the pixel value to be in range [0, 1].
///
/// It assumes that the pixel value is originally in range [0, 255]
double normalizePixelRange1(num pixelValue) {
  return (pixelValue / 255);
}

double normalizePixelNoRange(num pixelValue) {
  return pixelValue.toDouble();
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

  // // Decoding using the ImageProvider from material.Image. This is not faster than the above, and also the code below is not finished!
  // final materialImage = material.Image.memory(imageData);
  // final ImageProvider uiImage = await materialImage.image;
}

/// Decodes [Uint8List] RGBA bytes to an ui.[Image] object.
Future<Image> decodeImageFromRgbaBytes(
  Uint8List rgbaBytes,
  int width,
  int height,
) {
  final Completer<Image> completer = Completer();
  decodeImageFromPixels(
    rgbaBytes,
    width,
    height,
    PixelFormat.rgba8888,
    (Image image) {
      completer.complete(image);
    },
  );
  return completer.future;
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

/// Encodes an [Image] object to a [Uint8List], by default in the png format.
///
/// Note that the result can be used with `Image.memory()` only if the [format] is png.
Future<Uint8List> encodeImageToUint8List(
  Image image, {
  ImageByteFormat format = ImageByteFormat.png,
}) async {
  final ByteData byteDataPng =
      await getByteDataFromImage(image, format: format);
  final encodedImage = byteDataPng.buffer.asUint8List();

  return encodedImage;
}

/// Resizes the [image] to the specified [width] and [height].
/// Returns the resized image and its size as a [Size] object. Note that this size excludes any empty pixels, hence it can be different than the actual image size if [maintainAspectRatio] is true.
///
/// [quality] determines the interpolation quality. The default [FilterQuality.medium] works best for most cases, unless you're scaling by a factor of 5-10 or more
/// [maintainAspectRatio] determines whether to maintain the aspect ratio of the original image or not. Note that maintaining aspect ratio here does not change the size of the image, but instead often means empty pixels that have to be taken into account
Future<(Image, Size)> resizeImage(
  Image image,
  int width,
  int height, {
  FilterQuality quality = FilterQuality.medium,
  bool maintainAspectRatio = false,
}) async {
  if (image.width == width && image.height == height) {
    return (image, Size(width.toDouble(), height.toDouble()));
  }
  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(width.toDouble(), height.toDouble()),
    ),
  );
  // Pre-fill the canvas with RGB color (114, 114, 114)
  canvas.drawRect(
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(width.toDouble(), height.toDouble()),
    ),
    Paint()..color = const Color.fromARGB(255, 114, 114, 114),
  );

  double scaleW = width / image.width;
  double scaleH = height / image.height;
  if (maintainAspectRatio) {
    final scale = min(width / image.width, height / image.height);
    scaleW = scale;
    scaleH = scale;
  }
  final scaledWidth = (image.width * scaleW).round();
  final scaledHeight = (image.height * scaleH).round();

  canvas.drawImageRect(
    image,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(image.width.toDouble(), image.height.toDouble()),
    ),
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(scaledWidth.toDouble(), scaledHeight.toDouble()),
    ),
    Paint()..filterQuality = quality,
  );

  final picture = recorder.endRecording();
  final resizedImage = await picture.toImage(width, height);
  return (resizedImage, Size(scaledWidth.toDouble(), scaledHeight.toDouble()));
}

Future<Image> resizeAndCenterCropImage(
  Image image,
  int size, {
  FilterQuality quality = FilterQuality.medium,
}) async {
  if (image.width == size && image.height == size) {
    return image;
  }
  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(size.toDouble(), size.toDouble()),
    ),
  );

  final scale = max(size / image.width, size / image.height);
  final scaledWidth = (image.width * scale).round();
  final scaledHeight = (image.height * scale).round();

  canvas.drawImageRect(
    image,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(image.width.toDouble(), image.height.toDouble()),
    ),
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(scaledWidth.toDouble(), scaledHeight.toDouble()),
    ),
    Paint()..filterQuality = quality,
  );

  final picture = recorder.endRecording();
  final resizedImage = await picture.toImage(size, size);
  return resizedImage;
}

/// Crops an [image] based on the specified [x], [y], [width] and [height].
Future<Image> cropImage(
  Image image,
  ByteData imgByteData, {
  required int x,
  required int y,
  required int width,
  required int height,
}) async {
  final newByteData = ByteData(width * height * 4);
  for (var h = y; h < y + height; h++) {
    for (var w = x; w < x + width; w++) {
      final pixel = readPixelColor(image, imgByteData, w, h);
      setPixelColor(
        Size(width.toDouble(), height.toDouble()),
        newByteData,
        w - x,
        h - y,
        pixel,
      );
    }
  }
  final newImage = await decodeImageFromRgbaBytes(
    newByteData.buffer.asUint8List(),
    width,
    height,
  );

  return newImage;
}

Future<Image> cropImageWithCanvasSimple(
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

@Deprecated('Old image processing method, use `cropImage` instead!')
/// Crops an [image] based on the specified [x], [y], [width] and [height].
/// Optionally, the cropped image can be resized to comply with a [maxSize] and/or [minSize].
/// Optionally, the cropped image can be rotated from the center by [rotation] radians.
/// Optionally, the [quality] of the resizing interpolation can be specified.
Future<Image> cropImageWithCanvas(
  Image image, {
  required double x,
  required double y,
  required double width,
  required double height,
  Size? maxSize,
  Size? minSize,
  double rotation = 0.0, // rotation in radians
  FilterQuality quality = FilterQuality.medium,
}) async {
  // Calculate the scale for resizing based on maxSize and minSize
  double scaleX = 1.0;
  double scaleY = 1.0;
  if (maxSize != null) {
    final minScale = min(maxSize.width / width, maxSize.height / height);
    if (minScale < 1.0) {
      scaleX = minScale;
      scaleY = minScale;
    }
  }
  if (minSize != null) {
    final maxScale = max(minSize.width / width, minSize.height / height);
    if (maxScale > 1.0) {
      scaleX = maxScale;
      scaleY = maxScale;
    }
  }

  // Calculate the final dimensions
  final targetWidth = (width * scaleX).round();
  final targetHeight = (height * scaleY).round();

  // Create the canvas
  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(targetWidth.toDouble(), targetHeight.toDouble()),
    ),
  );

  // Apply rotation
  final center = Offset(targetWidth / 2, targetHeight / 2);
  canvas.translate(center.dx, center.dy);
  canvas.rotate(rotation);

  // Enlarge both the source and destination boxes to account for the rotation (i.e. avoid cropping the corners of the image)
  final List<double> enlargedSrc =
      getEnlargedAbsoluteBox([x, y, x + width, y + height], 1.5);
  final List<double> enlargedDst = getEnlargedAbsoluteBox(
    [
      -center.dx,
      -center.dy,
      -center.dx + targetWidth,
      -center.dy + targetHeight,
    ],
    1.5,
  );

  canvas.drawImageRect(
    image,
    Rect.fromPoints(
      Offset(enlargedSrc[0], enlargedSrc[1]),
      Offset(enlargedSrc[2], enlargedSrc[3]),
    ),
    Rect.fromPoints(
      Offset(enlargedDst[0], enlargedDst[1]),
      Offset(enlargedDst[2], enlargedDst[3]),
    ),
    Paint()..filterQuality = quality,
  );

  final picture = recorder.endRecording();

  return picture.toImage(targetWidth, targetHeight);
}

/// Adds padding around an [Image] object.
Future<Image> addPaddingToImage(
  Image image, [
  double padding = 0.5,
]) async {
  const Color paddingColor = Color.fromARGB(0, 0, 0, 0);
  final originalWidth = image.width;
  final originalHeight = image.height;

  final paddedWidth = (originalWidth + 2 * padding * originalWidth).toInt();
  final paddedHeight = (originalHeight + 2 * padding * originalHeight).toInt();

  final recorder = PictureRecorder();
  final canvas = Canvas(
    recorder,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(paddedWidth.toDouble(), paddedHeight.toDouble()),
    ),
  );

  final paint = Paint();
  paint.color = paddingColor;

  // Draw the padding
  canvas.drawRect(
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(paddedWidth.toDouble(), paddedHeight.toDouble()),
    ),
    paint,
  );

  // Draw the original image on top of the padding
  canvas.drawImageRect(
    image,
    Rect.fromPoints(
      const Offset(0, 0),
      Offset(image.width.toDouble(), image.height.toDouble()),
    ),
    Rect.fromPoints(
      Offset(padding * originalWidth, padding * originalHeight),
      Offset(
        (1 + padding) * originalWidth,
        (1 + padding) * originalHeight,
      ),
    ),
    Paint()..filterQuality = FilterQuality.none,
  );

  final picture = recorder.endRecording();
  return picture.toImage(paddedWidth, paddedHeight);
}

/// Preprocesses [imageData] for standard ML models.
/// Returns a [Num3DInputMatrix] image, ready for inference.
/// Also returns the original image size and the new image size, respectively.
///
/// The [imageData] argument must be a [Uint8List] object.
/// The [normalize] argument determines whether the image is normalized to range [-1, 1].
/// The [requiredWidth] and [requiredHeight] arguments determine the size of the output image.
/// The [quality] argument determines the quality of the resizing interpolation.
/// The [maintainAspectRatio] argument determines whether the aspect ratio of the image is maintained.
@Deprecated("Old method used in blazeface")
Future<(Num3DInputMatrix, Size, Size)> preprocessImageToMatrix(
  Uint8List imageData, {
  required int normalization,
  required int requiredWidth,
  required int requiredHeight,
  FilterQuality quality = FilterQuality.medium,
  maintainAspectRatio = true,
}) async {
  final normFunction = normalization == 2
      ? normalizePixelRange2
      : normalization == 1
          ? normalizePixelRange1
          : normalizePixelNoRange;
  final Image image = await decodeImageFromData(imageData);
  final originalSize = Size(image.width.toDouble(), image.height.toDouble());

  if (image.width == requiredWidth && image.height == requiredHeight) {
    final ByteData imgByteData = await getByteDataFromImage(image);
    return (
      createInputMatrixFromImage(
        image,
        imgByteData,
        normFunction: normFunction,
      ),
      originalSize,
      originalSize
    );
  }

  final (resizedImage, newSize) = await resizeImage(
    image,
    requiredWidth,
    requiredHeight,
    quality: quality,
    maintainAspectRatio: maintainAspectRatio,
  );

  final ByteData imgByteData = await getByteDataFromImage(resizedImage);
  final Num3DInputMatrix imageMatrix = createInputMatrixFromImage(
    resizedImage,
    imgByteData,
    normFunction: normFunction,
  );

  return (imageMatrix, originalSize, newSize);
}

Future<(Float32List, Dimensions, Dimensions)>
    preprocessImageToFloat32ChannelsFirst(
  Image image,
  ByteData imgByteData, {
  required int normalization,
  required int requiredWidth,
  required int requiredHeight,
  Color Function(num, num, Image, ByteData) getPixel = getPixelBilinear,
  maintainAspectRatio = true,
}) async {
  final normFunction = normalization == 2
      ? normalizePixelRange2
      : normalization == 1
          ? normalizePixelRange1
          : normalizePixelNoRange;
  final originalSize = Dimensions(width: image.width, height: image.height);

  if (image.width == requiredWidth && image.height == requiredHeight) {
    return (
      createFloat32ListFromImageChannelsFirst(
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

@Deprecated(
  'Replaced by `preprocessImageToFloat32ChannelsFirst` to avoid issue with iOS canvas',
)
Future<(Float32List, Size, Size)> preprocessImageToFloat32ChannelsFirstCanvas(
  Uint8List imageData, {
  required int normalization,
  required int requiredWidth,
  required int requiredHeight,
  FilterQuality quality = FilterQuality.medium,
  maintainAspectRatio = true,
}) async {
  final normFunction = normalization == 2
      ? normalizePixelRange2
      : normalization == 1
          ? normalizePixelRange1
          : normalizePixelNoRange;
  final stopwatch = Stopwatch()..start();
  final Image image = await decodeImageFromData(imageData);
  stopwatch.stop();
  log("Face Detection decoding ui image took: ${stopwatch.elapsedMilliseconds} ms");
  final originalSize = Size(image.width.toDouble(), image.height.toDouble());
  late final Image resizedImage;
  late final Size newSize;

  if (image.width == requiredWidth && image.height == requiredHeight) {
    resizedImage = image;
    newSize = originalSize;
  } else {
    (resizedImage, newSize) = await resizeImage(
      image,
      requiredWidth,
      requiredHeight,
      quality: quality,
      maintainAspectRatio: maintainAspectRatio,
    );
  }
  final ByteData imgByteData = await getByteDataFromImage(resizedImage);
  final Float32List imageFloat32List = createFloat32ListFromImageChannelsFirst(
    resizedImage,
    imgByteData,
    normFunction: normFunction,
  );

  return (imageFloat32List, originalSize, newSize);
}

/// Preprocesses [imageData] based on [faceLandmarks] to align the faces in the images.
///
/// Returns a list of [Uint8List] images, one for each face, in png format.
@Deprecated("Old method used in blazeface")
Future<List<Uint8List>> preprocessFaceAlignToUint8List(
  Uint8List imageData,
  List<List<List<double>>> faceLandmarks, {
  int width = 112,
  int height = 112,
}) async {
  final alignedImages = <Uint8List>[];
  final Image image = await decodeImageFromData(imageData);

  for (final faceLandmark in faceLandmarks) {
    final (alignmentResult, correctlyEstimated) =
        SimilarityTransform.instance.estimate(faceLandmark);
    if (!correctlyEstimated) {
      alignedImages.add(Uint8List(0));
      continue;
    }
    final alignmentBox = getAlignedFaceBox(alignmentResult);
    final Image alignedFace = await cropImageWithCanvas(
      image,
      x: alignmentBox[0],
      y: alignmentBox[1],
      width: alignmentBox[2] - alignmentBox[0],
      height: alignmentBox[3] - alignmentBox[1],
      maxSize: Size(width.toDouble(), height.toDouble()),
      minSize: Size(width.toDouble(), height.toDouble()),
      rotation: alignmentResult.rotation,
    );
    final Uint8List alignedFacePng = await encodeImageToUint8List(alignedFace);
    alignedImages.add(alignedFacePng);

    // final Uint8List alignedImageRGBA = await warpAffineToUint8List(
    //   image,
    //   imgByteData,
    //   alignmentResult.affineMatrix
    //       .map(
    //         (row) => row.map((e) {
    //           if (e != 1.0) {
    //             return e * 112;
    //           } else {
    //             return 1.0;
    //           }
    //         }).toList(),
    //       )
    //       .toList(),
    //   width: width,
    //   height: height,
    // );
    // final Image alignedImage =
    //     await decodeImageFromRgbaBytes(alignedImageRGBA, width, height);
    // final Uint8List alignedImagePng =
    //     await encodeImageToUint8List(alignedImage);

    // alignedImages.add(alignedImagePng);
  }
  return alignedImages;
}

/// Preprocesses [imageData] based on [faceLandmarks] to align the faces in the images
///
/// Returns a list of [Num3DInputMatrix] images, one for each face, ready for MobileFaceNet inference
@Deprecated("Old method used in TensorFlow Lite")
Future<
    (
      List<Num3DInputMatrix>,
      List<AlignmentResult>,
      List<bool>,
      List<double>,
      Size,
    )> preprocessToMobileFaceNetInput(
  Uint8List imageData,
  List<Map<String, dynamic>> facesJson, {
  int width = 112,
  int height = 112,
}) async {
  final Image image = await decodeImageFromData(imageData);
  final Size originalSize =
      Size(image.width.toDouble(), image.height.toDouble());

  final List<FaceDetectionRelative> relativeFaces =
      facesJson.map((face) => FaceDetectionRelative.fromJson(face)).toList();

  final List<FaceDetectionAbsolute> absoluteFaces =
      relativeToAbsoluteDetections(
    relativeDetections: relativeFaces,
    imageWidth: image.width,
    imageHeight: image.height,
  );

  final List<List<List<double>>> faceLandmarks =
      absoluteFaces.map((face) => face.allKeypoints).toList();

  final alignedImages = <Num3DInputMatrix>[];
  final alignmentResults = <AlignmentResult>[];
  final isBlurs = <bool>[];
  final blurValues = <double>[];

  for (final faceLandmark in faceLandmarks) {
    final (alignmentResult, correctlyEstimated) =
        SimilarityTransform.instance.estimate(faceLandmark);
    if (!correctlyEstimated) {
      alignedImages.add([]);
      alignmentResults.add(AlignmentResult.empty());
      continue;
    }
    final alignmentBox = getAlignedFaceBox(alignmentResult);
    final Image alignedFace = await cropImageWithCanvas(
      image,
      x: alignmentBox[0],
      y: alignmentBox[1],
      width: alignmentBox[2] - alignmentBox[0],
      height: alignmentBox[3] - alignmentBox[1],
      maxSize: Size(width.toDouble(), height.toDouble()),
      minSize: Size(width.toDouble(), height.toDouble()),
      rotation: alignmentResult.rotation,
      quality: FilterQuality.medium,
    );
    final alignedFaceByteData = await getByteDataFromImage(alignedFace);
    final alignedFaceMatrix = createInputMatrixFromImage(
      alignedFace,
      alignedFaceByteData,
      normFunction: normalizePixelRange2,
    );
    alignedImages.add(alignedFaceMatrix);
    alignmentResults.add(alignmentResult);
    final faceGrayMatrix = createGrayscaleIntMatrixFromImage(
      alignedFace,
      alignedFaceByteData,
    );
    final (isBlur, blurValue) = await BlurDetectionService.instance
        .predictIsBlurGrayLaplacian(faceGrayMatrix);
    isBlurs.add(isBlur);
    blurValues.add(blurValue);

    // final Double3DInputMatrix alignedImage = await warpAffineToMatrix(
    //   image,
    //   imgByteData,
    //   transformationMatrix,
    //   width: width,
    //   height: height,
    //   normalize: true,
    // );
    // alignedImages.add(alignedImage);
    // transformationMatrices.add(transformationMatrix);
  }
  return (alignedImages, alignmentResults, isBlurs, blurValues, originalSize);
}

@Deprecated("Old image manipulation that used canvas, causing issues on iOS")
Future<(Float32List, List<AlignmentResult>, List<bool>, List<double>, Size)>
    preprocessToMobileFaceNetFloat32ListCanvas(
  String imagePath,
  List<FaceDetectionRelative> relativeFaces, {
  int width = 112,
  int height = 112,
}) async {
  final Uint8List imageData = await File(imagePath).readAsBytes();
  final stopwatch = Stopwatch()..start();
  final Image image = await decodeImageFromData(imageData);
  stopwatch.stop();
  log("Face Alignment decoding ui image took: ${stopwatch.elapsedMilliseconds} ms");
  final Size originalSize =
      Size(image.width.toDouble(), image.height.toDouble());

  final List<FaceDetectionAbsolute> absoluteFaces =
      relativeToAbsoluteDetections(
    relativeDetections: relativeFaces,
    imageWidth: image.width,
    imageHeight: image.height,
  );

  final List<List<List<double>>> faceLandmarks =
      absoluteFaces.map((face) => face.allKeypoints).toList();

  final alignedImagesFloat32List =
      Float32List(3 * width * height * faceLandmarks.length);
  final alignmentResults = <AlignmentResult>[];
  final isBlurs = <bool>[];
  final blurValues = <double>[];

  int alignedImageIndex = 0;
  for (final faceLandmark in faceLandmarks) {
    final (alignmentResult, correctlyEstimated) =
        SimilarityTransform.instance.estimate(faceLandmark);
    if (!correctlyEstimated) {
      alignedImageIndex += 3 * width * height;
      alignmentResults.add(AlignmentResult.empty());
      continue;
    }
    final alignmentBox = getAlignedFaceBox(alignmentResult);
    final Image alignedFace = await cropImageWithCanvas(
      image,
      x: alignmentBox[0],
      y: alignmentBox[1],
      width: alignmentBox[2] - alignmentBox[0],
      height: alignmentBox[3] - alignmentBox[1],
      maxSize: Size(width.toDouble(), height.toDouble()),
      minSize: Size(width.toDouble(), height.toDouble()),
      rotation: alignmentResult.rotation,
      quality: FilterQuality.medium,
    );
    final alignedFaceByteData = await getByteDataFromImage(alignedFace);
    addInputImageToFloat32List(
      alignedFace,
      alignedFaceByteData,
      alignedImagesFloat32List,
      alignedImageIndex,
      normFunction: normalizePixelRange2,
    );
    alignedImageIndex += 3 * width * height;
    alignmentResults.add(alignmentResult);
    final blurDetectionStopwatch = Stopwatch()..start();
    final faceGrayMatrix = createGrayscaleIntMatrixFromImage(
      alignedFace,
      alignedFaceByteData,
    );
    final grascalems = blurDetectionStopwatch.elapsedMilliseconds;
    log('creating grayscale matrix took $grascalems ms');
    final (isBlur, blurValue) = await BlurDetectionService.instance
        .predictIsBlurGrayLaplacian(faceGrayMatrix);
    final blurms = blurDetectionStopwatch.elapsedMilliseconds - grascalems;
    log('blur detection took $blurms ms');
    log(
      'total blur detection took ${blurDetectionStopwatch.elapsedMilliseconds} ms',
    );
    blurDetectionStopwatch.stop();
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
        SimilarityTransform.instance.estimate(face.allKeypoints);
    if (!correctlyEstimated) {
      alignedImageIndex += 3 * width * height;
      alignmentResults.add(AlignmentResult.empty());
      continue;
    }
    alignmentResults.add(alignmentResult);

    warpAffineFloat32List(
      image,
      imageByteData,
      alignmentResult.affineMatrix,
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    final blurDetectionStopwatch = Stopwatch()..start();
    final faceGrayMatrix = createGrayscaleIntMatrixFromNormalized2List(
      alignedImagesFloat32List,
      alignedImageIndex,
    );

    alignedImageIndex += 3 * width * height;
    final grayscalems = blurDetectionStopwatch.elapsedMilliseconds;
    log('creating grayscale matrix took $grayscalems ms');
    final (isBlur, blurValue) =
        await BlurDetectionService.instance.predictIsBlurGrayLaplacian(
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

void warpAffineFloat32List(
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
          getPixelBicubic(xOrigin, yOrigin, inputImage, imgByteDataRgba);

      // Set the new pixel
      outputList[startIndex + 3 * (yTrans * width + xTrans)] =
          normalizePixelRange2(pixel.red);
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 1] =
          normalizePixelRange2(pixel.green);
      outputList[startIndex + 3 * (yTrans * width + xTrans) + 2] =
          normalizePixelRange2(pixel.blue);
    }
  }
}

Future<List<Uint8List>> generateFaceThumbnails(
  Uint8List imageData,
  List<FaceBox> faceBoxes,
) async {
  final stopwatch = Stopwatch()..start();

  final Image img = await decodeImageFromData(imageData);
  final ByteData imgByteData = await getByteDataFromImage(img);

  try {
    final List<Uint8List> faceThumbnails = [];

    for (final faceBox in faceBoxes) {
      // Note that the faceBox values are relative to the image size, so we need to convert them to absolute values first
      final double xMinAbs = faceBox.xMin * img.width;
      final double yMinAbs = faceBox.yMin * img.height;
      final double widthAbs = faceBox.width * img.width;
      final double heightAbs = faceBox.height * img.height;

      final int xCrop = (xMinAbs - widthAbs / 2).round().clamp(0, img.width);
      final int yCrop = (yMinAbs - heightAbs / 2).round().clamp(0, img.height);
      final int widthCrop = min((widthAbs * 2).round(), img.width - xCrop);
      final int heightCrop = min((heightAbs * 2).round(), img.height - yCrop);
      final Image faceThumbnail = await cropImage(
        img,
        imgByteData,
        x: xCrop,
        y: yCrop,
        width: widthCrop,
        height: heightCrop,
      );
      final Uint8List faceThumbnailPng = await encodeImageToUint8List(
        faceThumbnail,
        format: ImageByteFormat.png,
      );
      faceThumbnails.add(faceThumbnailPng);
    }
    stopwatch.stop();
    log('Face thumbnail generation took: ${stopwatch.elapsedMilliseconds} ms');

    return faceThumbnails;
  } catch (e, s) {
    log('[ImageMlUtils] Error generating face thumbnails: $e, \n stackTrace: $s');
    rethrow;
  }
}

/// Generates a face thumbnail from [imageData] and a [faceDetection].
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
      final double xMinAbs = faceBox.xMin * img.width;
      final double yMinAbs = faceBox.yMin * img.height;
      final double widthAbs = faceBox.width * img.width;
      final double heightAbs = faceBox.height * img.height;

      // Prevent the face from going out of image bounds
      final num xCrop = (xMinAbs - widthAbs / 2).clamp(0, img.width);
      final num yCrop = (yMinAbs - heightAbs / 2).clamp(0, img.height);
      final num widthCrop = min((widthAbs * 2), img.width - xCrop);
      final num heightCrop = min((heightAbs * 2), img.height - yCrop);

      futureFaceThumbnails.add(
        cropAndEncodeCanvas(
          img,
          x: xCrop.toDouble(),
          y: yCrop.toDouble(),
          width: widthCrop.toDouble(),
          height: heightCrop.toDouble(),
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

Future<Uint8List> cropAndEncodeCanvas(
  Image image, {
  required double x,
  required double y,
  required double width,
  required double height,
}) async {
  final croppedImage = await cropImageWithCanvasSimple(
    image,
    x: x,
    y: y,
    width: width,
    height: height,
  );
  return await encodeImageToUint8List(
    croppedImage,
    format: ImageByteFormat.png,
  );
}

@Deprecated('For second pass of BlazeFace, no longer used')

/// Generates cropped and padded image data from [imageData] and a [faceBox].
///
/// The steps are:
/// 1. Crop the image to the face bounding box
/// 2. Resize this cropped image to a square that is half the BlazeFace input size
/// 3. Pad the image to the BlazeFace input size
///
/// Note that [faceBox] is a list of the following values: [xMinBox, yMinBox, xMaxBox, yMaxBox].
Future<Uint8List> cropAndPadFaceData(
  Uint8List imageData,
  List<double> faceBox,
) async {
  final Image image = await decodeImageFromData(imageData);

  final Image faceCrop = await cropImageWithCanvas(
    image,
    x: (faceBox[0] * image.width),
    y: (faceBox[1] * image.height),
    width: ((faceBox[2] - faceBox[0]) * image.width),
    height: ((faceBox[3] - faceBox[1]) * image.height),
    maxSize: const Size(128, 128),
    minSize: const Size(128, 128),
  );

  final Image facePadded = await addPaddingToImage(
    faceCrop,
    0.5,
  );

  return await encodeImageToUint8List(facePadded);
}

Color getPixelBilinear(num fx, num fy, Image image, ByteData byteDataRgba) {
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
  final Color pixel1 = readPixelColor(image, byteDataRgba, x0, y0);
  final Color pixel2 = readPixelColor(image, byteDataRgba, x1, y0);
  final Color pixel3 = readPixelColor(image, byteDataRgba, x0, y1);
  final Color pixel4 = readPixelColor(image, byteDataRgba, x1, y1);

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
Color getPixelBicubic(num fx, num fy, Image image, ByteData byteDataRgba) {
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

  final icc = readPixelColor(image, byteDataRgba, x, y);

  final ipp =
      px < 0 || py < 0 ? icc : readPixelColor(image, byteDataRgba, px, py);
  final icp = px < 0 ? icc : readPixelColor(image, byteDataRgba, x, py);
  final inp = py < 0 || nx >= image.width
      ? icc
      : readPixelColor(image, byteDataRgba, nx, py);
  final iap = ax >= image.width || py < 0
      ? icc
      : readPixelColor(image, byteDataRgba, ax, py);

  final ip0 = cubic(dx, ipp.red, icp.red, inp.red, iap.red);
  final ip1 = cubic(dx, ipp.green, icp.green, inp.green, iap.green);
  final ip2 = cubic(dx, ipp.blue, icp.blue, inp.blue, iap.blue);
  // final ip3 = cubic(dx, ipp.a, icp.a, inp.a, iap.a);

  final ipc = px < 0 ? icc : readPixelColor(image, byteDataRgba, px, y);
  final inc =
      nx >= image.width ? icc : readPixelColor(image, byteDataRgba, nx, y);
  final iac =
      ax >= image.width ? icc : readPixelColor(image, byteDataRgba, ax, y);

  final ic0 = cubic(dx, ipc.red, icc.red, inc.red, iac.red);
  final ic1 = cubic(dx, ipc.green, icc.green, inc.green, iac.green);
  final ic2 = cubic(dx, ipc.blue, icc.blue, inc.blue, iac.blue);
  // final ic3 = cubic(dx, ipc.a, icc.a, inc.a, iac.a);

  final ipn = px < 0 || ny >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, px, ny);
  final icn =
      ny >= image.height ? icc : readPixelColor(image, byteDataRgba, x, ny);
  final inn = nx >= image.width || ny >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, nx, ny);
  final ian = ax >= image.width || ny >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, ax, ny);

  final in0 = cubic(dx, ipn.red, icn.red, inn.red, ian.red);
  final in1 = cubic(dx, ipn.green, icn.green, inn.green, ian.green);
  final in2 = cubic(dx, ipn.blue, icn.blue, inn.blue, ian.blue);
  // final in3 = cubic(dx, ipn.a, icn.a, inn.a, ian.a);

  final ipa = px < 0 || ay >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, px, ay);
  final ica =
      ay >= image.height ? icc : readPixelColor(image, byteDataRgba, x, ay);
  final ina = nx >= image.width || ay >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, nx, ay);
  final iaa = ax >= image.width || ay >= image.height
      ? icc
      : readPixelColor(image, byteDataRgba, ax, ay);

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

@Deprecated('Old method only used in other deprecated methods')
List<double> getAlignedFaceBox(AlignmentResult alignment) {
  final List<double> box = [
    // [xMinBox, yMinBox, xMaxBox, yMaxBox]
    alignment.center[0] - alignment.size / 2,
    alignment.center[1] - alignment.size / 2,
    alignment.center[0] + alignment.size / 2,
    alignment.center[1] + alignment.size / 2,
  ];
  box.roundBoxToDouble();
  return box;
}

/// Returns an enlarged version of the [box] by a factor of [factor].
/// The [box] is in absolute coordinates: [xMinBox, yMinBox, xMaxBox, yMaxBox].
List<double> getEnlargedAbsoluteBox(List<double> box, [double factor = 2]) {
  final boxCopy = List<double>.from(box, growable: false);
  // The four values of the box in order are: [xMinBox, yMinBox, xMaxBox, yMaxBox].

  final width = boxCopy[2] - boxCopy[0];
  final height = boxCopy[3] - boxCopy[1];

  boxCopy[0] -= width * (factor - 1) / 2;
  boxCopy[1] -= height * (factor - 1) / 2;
  boxCopy[2] += width * (factor - 1) / 2;
  boxCopy[3] += height * (factor - 1) / 2;

  return boxCopy;
}
