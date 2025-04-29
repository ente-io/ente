import 'dart:async';
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
