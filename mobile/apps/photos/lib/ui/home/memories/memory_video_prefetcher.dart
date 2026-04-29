import "dart:async";
import "dart:collection";

import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/video_preview_service.dart";
import "package:photos/utils/file_util.dart";
import "package:photos/utils/network_util.dart";

const int kMemoryVideoLookaheadCap = 20;
const int kMemoryVideoMaxConcurrentPrefetches = 1;

const int kMemoryVideoPreviewMaxBytes = 25 * 1024 * 1024;
const int kMemoryVideoOriginalMaxBytes = 25 * 1024 * 1024;
const int kMemoryVideoOriginalMaxDurationSeconds = 30;
const int kMemoryVideoSessionBudgetBytes = 100 * 1024 * 1024;

class MemoryVideoPrefetcher {
  final Queue<({EnteFile file, bool Function()? stillActive})> _queue =
      Queue<({EnteFile file, bool Function()? stillActive})>();
  final Set<int> _queuedIDs = <int>{};
  final Set<int> _attemptedIDs = <int>{};

  int _activeCount = 0;
  int _reservedDownloadBytes = 0;
  bool _disposed = false;

  void prefetchFiles(
    Iterable<EnteFile> files, {
    bool Function()? stillActive,
    bool replacePending = false,
  }) {
    if (_disposed || isOfflineMode) return;
    if (replacePending) {
      clearPending();
    }
    for (final file in files) {
      if (stillActive != null && !stillActive()) return;
      _enqueue(file, stillActive);
    }
    _pump();
  }

  void clearPending() {
    _queue.clear();
    _queuedIDs.clear();
  }

  void dispose() {
    _disposed = true;
    clearPending();
  }

  void _enqueue(EnteFile file, bool Function()? stillActive) {
    if (file.fileType != FileType.video || !file.isRemoteFile) return;
    final uploadedFileID = file.uploadedFileID;
    if (uploadedFileID == null) return;
    if (_attemptedIDs.contains(uploadedFileID) ||
        _queuedIDs.contains(uploadedFileID)) {
      return;
    }
    _queue.add((file: file, stillActive: stillActive));
    _queuedIDs.add(uploadedFileID);
  }

  void _pump() {
    if (_disposed || isOfflineMode) return;
    while (_activeCount < kMemoryVideoMaxConcurrentPrefetches &&
        _queue.isNotEmpty) {
      final entry = _queue.removeFirst();
      final file = entry.file;
      final uploadedFileID = file.uploadedFileID;
      if (uploadedFileID == null) continue;
      _queuedIDs.remove(uploadedFileID);
      if (_attemptedIDs.contains(uploadedFileID)) continue;
      if (!_isActive(entry.stillActive)) continue;

      _activeCount++;
      unawaited(
        _prefetch(file, uploadedFileID, entry.stillActive).whenComplete(() {
          _activeCount--;
          _pump();
        }),
      );
    }
  }

  bool _isActive(bool Function()? stillActive) {
    return !_disposed &&
        !isOfflineMode &&
        (stillActive == null || stillActive());
  }

  bool _tryReserveDownloadBytes(int bytes) {
    if (_reservedDownloadBytes + bytes > kMemoryVideoSessionBudgetBytes) {
      return false;
    }
    _reservedDownloadBytes += bytes;
    return true;
  }

  Future<void> _prefetch(
    EnteFile file,
    int uploadedFileID,
    bool Function()? stillActive,
  ) async {
    try {
      if (!_isActive(stillActive)) return;
      if (!await canUseHighBandwidth()) return;
      if (!_isActive(stillActive)) return;

      final didWarmPreview =
          await VideoPreviewService.instance.prefetchExistingPreview(
        file,
        maxPreviewSizeBytes: kMemoryVideoPreviewMaxBytes,
        tryReserveBytes: (bytes) {
          return _isActive(stillActive) && _tryReserveDownloadBytes(bytes);
        },
      );
      if (!_isActive(stillActive)) return;
      if (!didWarmPreview) {
        await _prefetchSmallOriginal(file, stillActive: stillActive);
      }
      if (!_isActive(stillActive)) return;
      _attemptedIDs.add(uploadedFileID);
    } catch (_) {
      if (!_isActive(stillActive)) return;
      _attemptedIDs.add(uploadedFileID);
    }
  }

  Future<bool> _prefetchSmallOriginal(
    EnteFile file, {
    bool Function()? stillActive,
  }) async {
    final fileSize = file.fileSize;
    final duration = file.duration;
    if (fileSize == null ||
        fileSize <= 0 ||
        fileSize > kMemoryVideoOriginalMaxBytes ||
        duration == null ||
        duration <= 0 ||
        duration > kMemoryVideoOriginalMaxDurationSeconds) {
      return false;
    }
    if (await isFileCached(file)) {
      return true;
    }
    if (!_isActive(stillActive)) {
      return false;
    }
    if (!_tryReserveDownloadBytes(fileSize)) {
      return false;
    }
    final prefetchedFile = await getFileFromServer(file);
    return prefetchedFile != null;
  }
}
