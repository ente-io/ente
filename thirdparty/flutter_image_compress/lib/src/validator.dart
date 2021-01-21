import 'dart:io';
import 'dart:async';

import 'package:flutter/services.dart';

import 'compress_format.dart';

class Validator {
  final MethodChannel channel;
  Validator(this.channel);

  bool ignoreCheckExtName = false;
  bool ignoreCheckSupportPlatform = false;

  void checkFileNameAndFormat(String name, CompressFormat format) {
    if (ignoreCheckExtName) {
      return;
    }
    name = name.toLowerCase();
    if (format == CompressFormat.jpeg) {
      assert((name.endsWith(".jpg") || name.endsWith(".jpeg")),
          "The jpeg format name must end with jpg or jpeg.");
    } else if (format == CompressFormat.png) {
      assert(name.endsWith(".png"), "The jpeg format name must end with png.");
    } else if (format == CompressFormat.heic) {
      assert(
          name.endsWith(".heic"), "The heic format name must end with heic.");
    } else if (format == CompressFormat.webp) {
      assert(
          name.endsWith(".webp"), "The webp format name must end with webp.");
    }
  }

  Future<bool> checkSupportPlatform(CompressFormat format) async {
    if (ignoreCheckSupportPlatform) {
      return true;
    }
    if (format == CompressFormat.heic) {
      if (Platform.isIOS) {
        final String version = await channel.invokeMethod("getSystemVersion");
        final firstVersion = version.split(".")[0];
        final result = int.parse(firstVersion) >= 11;
        final msg = "The heic format only support iOS 11.0+";
        assert(result, msg);
        _checkThrowError(result, msg);
        return result;
      } else if (Platform.isAndroid) {
        final int version = await channel.invokeMethod("getSystemVersion");
        final result = version >= 28;
        final msg = "The heic format only support android API 28+";
        assert(result, msg);
        _checkThrowError(result, msg);
        return result;
      } else {
        final msg = "The heic format only support android and iOS.";
        assert(Platform.isAndroid || Platform.isIOS, msg);
        _checkThrowError(false, msg);
        return false;
      }
    } else if (format == CompressFormat.webp) {
      if (Platform.isAndroid || Platform.isIOS) {
        return true;
      }

      var msg = "The webp format only support android and iOS.";

      _checkThrowError(false, msg);

      return false;
    }

    return true;
  }

  void _checkThrowError(bool result, String msg) {
    if (!result) {
      throw UnsupportedError(msg);
    }
  }
}
