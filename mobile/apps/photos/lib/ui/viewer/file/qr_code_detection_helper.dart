import "dart:io";

import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";

class QrCodeDetectionHelper {
  static final Map<String, _DetectionResult> _cache = {};
  final Logger _logger = Logger("QrCodeDetectionHelper");
  final EnteQr _enteQr = EnteQr();

  final ValueNotifier<String?> qrContentNotifier = ValueNotifier<String?>(null);

  int _requestId = 0;
  bool _disposed = false;

  Future<void> evaluateFile(EnteFile file) async {
    final bool isEligible = _isFileEligible(file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      qrContentNotifier.value = null;
      return;
    }

    final String cacheKey = _cacheKey(file);
    final _DetectionResult? cachedResult = _cache[cacheKey];
    if (cachedResult != null) {
      if (_disposed || requestId != _requestId) return;
      qrContentNotifier.value = cachedResult.content;
      return;
    }

    qrContentNotifier.value = null;

    try {
      final File? localFile = await getFile(file);
      if (_disposed || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        _cache[cacheKey] = const _DetectionResult(hasQr: false);
        qrContentNotifier.value = null;
        return;
      }

      bool hasQr = false;
      String? qrContent;
      try {
        final result = await _enteQr.scanQrFromImage(localFile.path);
        if (result.success && result.content != null) {
          hasQr = true;
          qrContent = result.content;
        }
      } catch (error, stackTrace) {
        _logger.severe("Failed to scan QR code", error, stackTrace);
      }

      if (_disposed || requestId != _requestId) return;

      final detectionResult = _DetectionResult(
        hasQr: hasQr,
        content: hasQr ? qrContent : null,
      );
      _cache[cacheKey] = detectionResult;
      qrContentNotifier.value = detectionResult.content;
    } catch (error, stackTrace) {
      _logger.severe("QR code detection failed", error, stackTrace);
      if (_disposed || requestId != _requestId) return;
      _cache[cacheKey] = const _DetectionResult(hasQr: false);
      qrContentNotifier.value = null;
    }
  }

  bool _isFileEligible(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  String _cacheKey(EnteFile file) {
    if (file.uploadedFileID != null) {
      return "qr_uploaded_${file.uploadedFileID}";
    }
    if (file.localID != null) {
      return "qr_local_${file.localID}";
    }
    return "qr_generated_${file.generatedID}";
  }

  void dispose() {
    _disposed = true;
    qrContentNotifier.dispose();
  }
}

class _DetectionResult {
  final bool hasQr;
  final String? content;

  const _DetectionResult({required this.hasQr, this.content});
}
