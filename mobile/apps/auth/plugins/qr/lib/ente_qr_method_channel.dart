import 'package:ente_qr/ente_qr_platform_interface.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// An implementation of [EnteQrPlatform] that uses method channels.
class MethodChannelEnteQr extends EnteQrPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ente_qr');

  @override
  Future<String?> getPlatformVersion() async {
    final version =
        await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }

  @override
  Future<QrScanResult> scanQrFromImage(String imagePath) async {
    try {
      final dynamic result = await methodChannel.invokeMethod(
        'scanQrFromImage',
        {'imagePath': imagePath},
      );

      if (result == null) {
        return QrScanResult.error('Failed to scan QR code');
      }

      // Convert to Map<String, dynamic> safely
      final Map<String, dynamic> resultMap =
          Map<String, dynamic>.from(result as Map);

      final bool success = resultMap['success'] as bool? ?? false;
      if (success) {
        final String? content = resultMap['content'] as String?;
        if (content != null && content.isNotEmpty) {
          return QrScanResult.success(content);
        } else {
          return QrScanResult.error('No QR code found in image');
        }
      } else {
        final String? error = resultMap['error'] as String?;
        return QrScanResult.error(error ?? 'Unknown error occurred');
      }
    } on PlatformException catch (e) {
      return QrScanResult.error('Platform error: ${e.message}');
    } catch (e) {
      return QrScanResult.error('Unexpected error: $e');
    }
  }
}
