import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/compress_format.dart';
import 'src/validator.dart';

export 'src/compress_format.dart';

/// Image Compress
///
/// static method will help you compress image
///
/// most method will return [Uint8List]
///
/// You can use `Image.memory` to display image
/// ```dart
/// Uint8List uint8List;
/// ImageProvider provider = MemoryImage(uint8List);
/// ```
///
/// or
///
/// ```dart
/// Uint8List uint8List;
/// Image.momory(uint8List)
/// ```
/// The returned image will retain the proportion of the original image.
///
/// Compress image will remove EXIF.
///
/// image result is jpeg format.
///
/// support rotate
///
class FlutterImageCompress {
  static const MethodChannel _channel =
      const MethodChannel('flutter_image_compress');

  static Validator _validator = Validator(_channel);

  static Validator get validator => _validator;

  static set showNativeLog(bool value) {
    _channel.invokeMethod("showLog", value);
  }

  /// Compress image from [Uint8List] to [Uint8List].
  static Future<Uint8List> compressWithList(
    Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    assert(
      image != null,
      "A non-null Uint8List must be provided to FlutterImageCompress.",
    );
    if (image == null) {
      throw "The image is null.";
    }
    if (image.isEmpty) {
      throw "The image is empty.";
    }

    final support = await _validator.checkSupportPlatform(format);
    if (!support) {
      throw "The image is not support.";
    }

    final result = await _channel.invokeMethod("compressWithList", [
      image,
      minWidth,
      minHeight,
      quality,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(format),
      keepExif,
      inSampleSize,
    ]);

    return result;
  }

  /// Compress file of [path] to [Uint8List].
  static Future<Uint8List> compressWithFile(
    String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    assert(
      path != null,
      "A non-null String must be provided to FlutterImageCompress.",
    );
    if (path == null || !File(path).existsSync()) {
      throw "Image file ($path) does not exist.";
    }

    final support = await _validator.checkSupportPlatform(format);
    if (!support) {
      return null;
    }

    final result = await _channel.invokeMethod("compressWithFile", [
      path,
      minWidth,
      minHeight,
      quality,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(format),
      keepExif,
      inSampleSize,
    ]);
    return result;
  }

  /// From [path] to [targetPath]
  static Future<File> compressAndGetFile(
    String path,
    String targetPath, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    assert(
      path != null,
      "A non-null String must be provided to FlutterImageCompress.",
    );
    if (path == null || !File(path).existsSync()) {
      throw "Image file does not exist";
    }
    assert(targetPath != null, "The target path must be null.");
    assert(
        targetPath != path, "Target path and source path cannot be the same.");

    _validator.checkFileNameAndFormat(targetPath, format);

    final support = await _validator.checkSupportPlatform(format);
    if (!support) {
      return null;
    }

    final String result =
        await _channel.invokeMethod("compressWithFileAndGetFile", [
      path,
      minWidth,
      minHeight,
      quality,
      targetPath,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(format),
      keepExif,
      inSampleSize,
    ]);

    if (result == null) {
      return null;
    }

    return File(result);
  }

  /// From [asset] to [Uint8List]
  static Future<Uint8List> compressAssetImage(
    String assetName, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    assert(
      assetName != null,
      "A non-null String must be provided to FlutterImageCompress.",
    );
    if (assetName == null) {
      return null;
    }

    final support = await _validator.checkSupportPlatform(format);
    if (!support) {
      return null;
    }

    final img = AssetImage(assetName);
    final config = ImageConfiguration();

    AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);

    final uint8List = data.buffer.asUint8List();

    if (uint8List == null || uint8List.isEmpty) {
      return null;
    }

    return compressWithList(
      uint8List,
      minHeight: minHeight,
      minWidth: minWidth,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      format: format,
      keepExif: keepExif,
    );
  }
}

int _convertTypeToInt(CompressFormat format) => format.index;
