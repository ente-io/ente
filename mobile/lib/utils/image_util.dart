import 'dart:async';

import 'package:flutter/widgets.dart';

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
