import "dart:async";
import "dart:io";

import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";

class QrCodeDetectionHelper {
  static final Map<String, _DetectionResult> _cache = {};
  static const _debounceDuration = Duration(milliseconds: 500);

  final Logger _logger = Logger("QrCodeDetectionHelper");
  final EnteQr _enteQr = EnteQr();

  final ValueNotifier<List<QrDetection>> qrDetectionsNotifier =
      ValueNotifier<List<QrDetection>>(const []);

  int _requestId = 0;
  bool _disposed = false;
  Timer? _debounceTimer;

  Future<void> evaluateFile(EnteFile file) async {
    _debounceTimer?.cancel();

    final bool isEligible = _isFileEligible(file);
    final int requestId = ++_requestId;

    if (!isEligible) {
      qrDetectionsNotifier.value = const [];
      return;
    }

    // Return cached results immediately without debounce
    final String cacheKey = _cacheKey(file);
    final _DetectionResult? cachedResult = _cache[cacheKey];
    if (cachedResult != null) {
      if (_disposed || requestId != _requestId) return;
      qrDetectionsNotifier.value = cachedResult.detections;
      return;
    }

    qrDetectionsNotifier.value = const [];

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
        _cache[cacheKey] = const _DetectionResult(detections: []);
        qrDetectionsNotifier.value = const [];
        return;
      }

      List<QrDetection> detections = const [];
      try {
        final result = await _enteQr.scanAllQrFromImage(localFile.path);
        if (result.success && result.detections.isNotEmpty) {
          detections = result.detections;
        }
      } catch (error, stackTrace) {
        _logger.severe("Failed to scan QR codes", error, stackTrace);
      }

      if (_disposed || requestId != _requestId) return;

      final detectionResult = _DetectionResult(detections: detections);
      _cache[cacheKey] = detectionResult;
      qrDetectionsNotifier.value = detectionResult.detections;
    } catch (error, stackTrace) {
      _logger.severe("QR code detection failed", error, stackTrace);
      if (_disposed || requestId != _requestId) return;
      _cache[cacheKey] = const _DetectionResult(detections: []);
      qrDetectionsNotifier.value = const [];
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
    qrDetectionsNotifier.dispose();
  }
}

class _DetectionResult {
  final List<QrDetection> detections;

  const _DetectionResult({required this.detections});
}
