import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'main.dart' as m;

main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;
  FlutterImageCompress.validator.ignoreCheckSupportPlatform = true;
  m.main();
}
