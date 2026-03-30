import "dart:async";
import "dart:collection";
import "dart:io";

import "package:ente_qr/ente_qr.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_util.dart";

class QrCodeDetectionHelper {
  static const _debounceDuration = Duration(milliseconds: 500);
  static const _maxCacheSize = 20;

  final Logger _logger = Logger("QrCodeDetectionHelper");
  final EnteQr _enteQr = EnteQr();

  final ValueNotifier<List<QrDetection>> qrDetectionsNotifier =
      ValueNotifier<List<QrDetection>>(const []);

  /// LRU cache keyed by file tag (unique identifier).
  final LinkedHashMap<String, List<QrDetection>> _cache =
      LinkedHashMap<String, List<QrDetection>>();

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

    // Return cached result immediately if available
    final cached = _cache[file.tag];
    if (cached != null) {
      _logger.info("QR cache hit: found=${cached.length}");
      qrDetectionsNotifier.value = cached;
      return;
    }

    qrDetectionsNotifier.value = const [];

    _debounceTimer = Timer(_debounceDuration, () {
      _scanFile(file, requestId);
    });
  }

  Future<void> _scanFile(
    EnteFile file,
    int requestId,
  ) async {
    if (_disposed || requestId != _requestId) return;

    try {
      final stopwatch = Stopwatch()..start();
      final File? localFile = await getFile(file);
      if (_disposed || requestId != _requestId) return;
      if (localFile == null || !localFile.existsSync()) {
        qrDetectionsNotifier.value = const [];
        return;
      }
      final getFileMs = stopwatch.elapsedMilliseconds;

      List<QrDetection> detections = const [];
      try {
        final result = await _enteQr.scanAllQrFromImage(localFile.path);
        if (result.success && result.detections.isNotEmpty) {
          detections = result.detections;
        }
      } catch (error, stackTrace) {
        _logger.severe("Failed to scan QR codes", error, stackTrace);
      }

      final totalMs = stopwatch.elapsedMilliseconds;
      _logger.info(
        "QR scan: getFile=${getFileMs}ms, "
        "detect=${totalMs - getFileMs}ms, "
        "total=${totalMs}ms, "
        "found=${detections.length}",
      );

      // Cache the result
      _cacheResult(file.tag, detections);

      if (_disposed || requestId != _requestId) return;

      qrDetectionsNotifier.value = detections;
    } catch (error, stackTrace) {
      _logger.severe("QR code detection failed", error, stackTrace);
      if (_disposed || requestId != _requestId) return;
      qrDetectionsNotifier.value = const [];
    }
  }

  void _cacheResult(String fileId, List<QrDetection> detections) {
    // Move to end (most recently used)
    _cache.remove(fileId);
    _cache[fileId] = detections;
    // Evict oldest entry if over limit
    if (_cache.length > _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
  }

  bool _isFileEligible(EnteFile file) {
    return file.fileType == FileType.image ||
        file.fileType == FileType.livePhoto;
  }

  void dispose() {
    _disposed = true;
    _debounceTimer?.cancel();
    _cache.clear();
    qrDetectionsNotifier.dispose();
  }
}
