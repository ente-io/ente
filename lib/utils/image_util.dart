import 'dart:async';

import 'package:flutter/widgets.dart';

Future<ImageInfo> getImageInfo(ImageProvider imageProvider) {
  final completer = Completer<ImageInfo>();
  final imageStream = imageProvider.resolve(const ImageConfiguration());
  final imageStreamListener = ImageStreamListener(
    ((imageInfo, _) {
      completer.complete(imageInfo);
    }),
  );
  imageStream.addListener(imageStreamListener);
  completer.future
      .whenComplete(() => imageStream.removeListener(imageStreamListener));
  return completer.future;
}
