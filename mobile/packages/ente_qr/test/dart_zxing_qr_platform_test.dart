import 'dart:io';

import 'package:ente_qr/src/dart_zxing_qr_platform.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:zxing2/qrcode.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ente_qr_test_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('scanQrFromImage decodes a QR PNG', () async {
    const payload =
        'otpauth://totp/Example:alice@example.com?secret=JBSWY3DPEHPK3PXP&issuer=Example';
    final imagePath = '${tempDir.path}/qr.png';
    await File(imagePath).writeAsBytes(img.encodePng(_qrImage(payload)));

    final result = await DartZxingQrPlatform().scanQrFromImage(imagePath);

    expect(result.success, true);
    expect(result.content, payload);
  });

  test('scanQrFromImage returns an error when no QR is present', () async {
    final imagePath = '${tempDir.path}/blank.png';
    final blank = img.Image(width: 320, height: 320)
      ..clear(img.ColorRgb8(255, 255, 255));
    await File(imagePath).writeAsBytes(img.encodePng(blank));

    final result = await DartZxingQrPlatform().scanQrFromImage(imagePath);

    expect(result.success, false);
    expect(result.error, isNotEmpty);
  });
}

img.Image _qrImage(String payload) {
  final qrcode = Encoder.encode(payload, ErrorCorrectionLevel.h);
  final matrix = qrcode.matrix!;
  const pixelsPerModule = 8;
  const quietZoneModules = 4;
  final size = (matrix.width + quietZoneModules * 2) * pixelsPerModule;
  final image = img.Image(width: size, height: size)
    ..clear(img.ColorRgb8(255, 255, 255));

  for (var y = 0; y < matrix.height; y++) {
    for (var x = 0; x < matrix.width; x++) {
      if (matrix.get(x, y) != 1) {
        continue;
      }
      final left = (x + quietZoneModules) * pixelsPerModule;
      final top = (y + quietZoneModules) * pixelsPerModule;
      img.fillRect(
        image,
        x1: left,
        y1: top,
        x2: left + pixelsPerModule - 1,
        y2: top + pixelsPerModule - 1,
        color: img.ColorRgb8(0, 0, 0),
      );
    }
  }
  return image;
}
