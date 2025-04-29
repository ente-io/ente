import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import "package:logging/logging.dart";

class PreloadImage {
  static final _logger = Logger((PreloadImage).toString());
  static Future<void> loadImage(ImageProvider provider) {
    final config = ImageConfiguration(
      bundle: rootBundle,
      devicePixelRatio: 1,
      platform: defaultTargetPlatform,
    );
    final Completer<void> completer = Completer();
    final ImageStream stream = provider.resolve(config);

    late final ImageStreamListener listener;

    listener = ImageStreamListener(
      (ImageInfo image, bool sync) {
        _logger.info("Image ${image.debugLabel} finished loading");
        completer.complete();
        stream.removeListener(listener);
      },
      onError: (dynamic exception, StackTrace? stackTrace) {
        completer.complete();
        stream.removeListener(listener);
        _logger.warning("Image failed to load");
        FlutterError.reportError(
          FlutterErrorDetails(
            context: ErrorDescription('image failed to load'),
            library: 'image resource service',
            exception: exception,
            stack: stackTrace,
            silent: true,
          ),
        );
      },
    );

    stream.addListener(listener);
    return completer.future;
  }
}
