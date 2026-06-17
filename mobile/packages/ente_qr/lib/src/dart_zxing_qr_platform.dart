import 'dart:io';

import 'package:ente_qr/ente_qr_platform_interface.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

final class DartZxingQrPlatform extends EnteQrPlatform {
  @override
  Future<String?> getPlatformVersion() async {
    return 'Dart zxing2';
  }

  @override
  Future<QrScanResult> scanQrFromImage(
    String imagePath, {
    bool tryOriginalResolution = false,
  }) async {
    try {
      final content = await _decodeQrFromImagePath(imagePath);
      return QrScanResult.success(content);
    } catch (e) {
      return QrScanResult.error(e.toString());
    }
  }

  @override
  Future<QrScanResults> scanAllQrFromImage(String imagePath) async {
    final result = await scanQrFromImage(imagePath);
    final content = result.content;
    if (!result.success || content == null) {
      return QrScanResults.error(result.error ?? 'No QR code found in image');
    }
    return QrScanResults.fromDetections([
      QrDetection(content: content, x: 0, y: 0, width: 1, height: 1),
    ]);
  }
}

Future<String> _decodeQrFromImagePath(String imagePath) async {
  final file = File(imagePath);
  if (!await file.exists()) {
    throw StateError('Image file not found: $imagePath');
  }

  final bytes = await file.readAsBytes();
  final image = img.decodeImage(bytes);
  if (image == null) {
    throw StateError('Unable to decode image file');
  }

  return _decodeImage(image).text;
}

Result _decodeImage(img.Image source) {
  final maxDimension = source.width > source.height
      ? source.width
      : source.height;
  final attempts = <img.Image>[
    source,
    img.invert(img.Image.from(source)),
    if (maxDimension < 600)
      img.copyResize(
        source,
        width: source.width * 2,
        height: source.height * 2,
        interpolation: img.Interpolation.linear,
      ),
    if (source.width > 1200 || source.height > 1200)
      img.copyResize(
        source,
        width: source.width >= source.height ? 1200 : null,
        height: source.height > source.width ? 1200 : null,
      ),
  ];

  Object? lastError;
  for (final attempt in attempts) {
    final converted = attempt.convert(numChannels: 4);
    final pixels = converted
        .getBytes(order: img.ChannelOrder.abgr)
        .buffer
        .asInt32List();
    final luminanceSource = RGBLuminanceSource(
      converted.width,
      converted.height,
      pixels,
    );

    final hints = DecodeHints()..put(DecodeHintType.tryHarder);
    for (final bitmap in [
      BinaryBitmap(GlobalHistogramBinarizer(luminanceSource)),
      BinaryBitmap(HybridBinarizer(luminanceSource)),
    ]) {
      try {
        return QRCodeReader().decode(bitmap, hints: hints);
      } catch (error) {
        lastError = error;
      }
    }
  }
  throw StateError(lastError?.toString() ?? 'No QR code found in image');
}
