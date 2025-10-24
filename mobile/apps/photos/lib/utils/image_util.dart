import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:image/image.dart' as img;

Future<ImageInfo> getImageInfo(ImageProvider imageProvider) {
  final completer = Completer<ImageInfo>();
  final imageStream = imageProvider.resolve(const ImageConfiguration());
  final listener = ImageStreamListener(
    ((imageInfo, _) {
      completer.complete(imageInfo);
    }),
  );
  imageStream.addListener(listener);
  completer.future.whenComplete(() => imageStream.removeListener(listener));
  return completer.future;
}

Future<ui.Image> convertImageToFlutterUi(img.Image image) async {
  if (image.format != img.Format.uint8 || image.numChannels != 4) {
    final cmd = img.Command()
      ..image(image)
      ..convert(format: img.Format.uint8, numChannels: 4);
    final rgba8 = await cmd.getImageThread();
    if (rgba8 != null) {
      image = rgba8;
    }
  }

  final ui.ImmutableBuffer buffer =
      await ui.ImmutableBuffer.fromUint8List(image.toUint8List());

  final ui.ImageDescriptor id = ui.ImageDescriptor.raw(
    buffer,
    height: image.height,
    width: image.width,
    pixelFormat: ui.PixelFormat.rgba8888,
  );

  final ui.Codec codec = await id.instantiateCodec(
    targetHeight: image.height,
    targetWidth: image.width,
  );

  final ui.FrameInfo fi = await codec.getNextFrame();
  final ui.Image uiImage = fi.image;

  return uiImage;
}

/// Returns decoded width/height for image bytes, or null if decoding fails.
({int width, int height})? decodeImageDimensions(Uint8List bytes) {
  try {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    return (width: decoded.width, height: decoded.height);
  } catch (_) {
    return null;
  }
}

/// Resizes [srcBytes] so that the longer dimension is at most [maxDimension],
/// encoding the result as JPEG with [quality]. If decoding fails, returns null.
({Uint8List bytes, int width, int height})? resizeImageToJpeg({
  required Uint8List srcBytes,
  required double maxDimension,
  int quality = 80,
}) {
  try {
    final decoded = img.decodeImage(srcBytes);
    if (decoded == null) {
      return null;
    }

    img.Image output = decoded;
    final int maxDim =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    if (maxDim > maxDimension) {
      final double scale = maxDimension / maxDim;
      final int targetWidth = (decoded.width * scale).round();
      final int targetHeight = (decoded.height * scale).round();
      output = img.copyResize(
        decoded,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    final Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(output, quality: quality),
    );

    return (bytes: encoded, width: output.width, height: output.height);
  } catch (_) {
    return null;
  }
}

/// Resizes [srcBytes] so that the shorter dimension is at most [minShortSide].
/// The longer side is scaled proportionally. If the shorter side is already
/// below [minShortSide], the image is returned unchanged (apart from baked EXIF
/// orientation) encoded as JPEG at [quality].
({Uint8List bytes, int width, int height})? resizeImageToFitShortSide({
  required Uint8List srcBytes,
  required double minShortSide,
  int quality = 80,
}) {
  try {
    final decoded = img.decodeImage(srcBytes);
    if (decoded == null) {
      return null;
    }

    img.Image output = img.bakeOrientation(decoded);
    final int shortSide = math.min(output.width, output.height);

    if (shortSide > minShortSide) {
      final double scale = minShortSide / shortSide;
      final int targetWidth = (output.width * scale).round();
      final int targetHeight = (output.height * scale).round();
      output = img.copyResize(
        output,
        width: targetWidth,
        height: targetHeight,
        interpolation: img.Interpolation.linear,
      );
    }

    final Uint8List encoded = Uint8List.fromList(
      img.encodeJpg(output, quality: quality),
    );

    return (bytes: encoded, width: output.width, height: output.height);
  } catch (_) {
    return null;
  }
}
