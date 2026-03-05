import "dart:async";
import "dart:io";

import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";

class QrCodeDetectionHelper {
  static final Map<String, String?> _cache = {};
  static const _debounceDuration = Duration(milliseconds: 1500);

  final Logger _logger = Logger("QrCodeDetectionHelper");
  final EnteQr _enteQr = EnteQr();

  /// null = no QR found, non-null = QR content string
  final ValueNotifier<String?> qrContentNotifier = ValueNotifier<String?>(null);

  int _requestId = 0;
  bool _disposed = false;
  Timer? _debounceTimer;

  Future<void> evaluateFile(EnteFile file) async {
    _debounceTimer?.cancel();

    final bool isEligible = _isFileEligible(file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      qrContentNotifier.value = null;
      return;
    }

    // Return cached results immediately without debounce
    final String cacheKey = _cacheKey(file);
    if (_cache.containsKey(cacheKey)) {
      if (_disposed || requestId != _requestId) return;
      qrContentNotifier.value = _cache[cacheKey];
      return;
    }

    qrContentNotifier.value = null;

    // Debounce uncached scans so swiping doesn't trigger work
    _debounceTimer = Timer(_debounceDuration, () {
      _scanFile(file, cacheKey, requestId);
    });
  }

  Future<void> _scanFile(
    EnteFile file,
    String cacheKey,
    int requestId,
  ) async {
    if (_disposed || requestId != _requestId) return;

    try {
      final File? localFile = await getFile(file);
      if (_disposed || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        _cache[cacheKey] = null;
        qrContentNotifier.value = null;
        return;
      }

      String? content;
      try {
        final result = await _enteQr.scanQrFromImage(localFile.path);
        if (result.success && result.content != null) {
          content = result.content;
        }
      } catch (error, stackTrace) {
        _logger.severe("Failed to scan QR code", error, stackTrace);
      }

      if (_disposed || requestId != _requestId) return;

      _cache[cacheKey] = content;
      qrContentNotifier.value = content;
    } catch (error, stackTrace) {
      _logger.severe("QR code detection failed", error, stackTrace);
      if (_disposed || requestId != _requestId) return;
      _cache[cacheKey] = null;
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
    _debounceTimer?.cancel();
    qrContentNotifier.dispose();
  }
}
