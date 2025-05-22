import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";

import 'package:photos/module/download/db.dart';
import "package:photos/module/download/file_url.dart";
import "package:photos/module/download/task.dart";

class DownloadManager {
  static const int _chunkSize = 50 * 1024 * 1024;

  final _db = DatabaseHelper();
  final _dio = Dio();
  final _logger = Logger('DownloadManager');

  // Active downloads with their completers and streams
  final Map<int, Completer<DownloadResult>> _completers = {};
  final Map<int, StreamController<DownloadTask>> _streams = {};
  final Map<int, CancelToken> _cancelTokens = {};

  /// Subscribe to download progress updates for a specific file ID
  Stream<DownloadTask> watchDownload(int fileId) {
    _streams[fileId] ??= StreamController<DownloadTask>.broadcast();
    return _streams[fileId]!.stream;
  }

  /// Start download and return a Future that completes when download finishes
  Future<DownloadResult> download(
    int fileId,
    String filename,
    int totalBytes,
  ) async {
    // If already downloading, return existing future
    if (_completers.containsKey(fileId)) {
      return _completers[fileId]!.future;
    }

    final completer = Completer<DownloadResult>();
    _completers[fileId] = completer;

    // Get or create task
    final task = await _db.get(fileId) ??
        DownloadTask(
          id: fileId,
          filename: filename,
          totalBytes: totalBytes,
        );

    // Don't restart if already completed
    if (task.isCompleted) {
      final result = DownloadResult(task, true);
      completer.complete(result);
      return result;
    }

    unawaited(_startDownload(task, completer));
    return completer.future;
  }

  /// Pause download
  Future<void> pause(int fileId) async {
    final token = _cancelTokens[fileId];
    if (token != null && !token.isCancelled) {
      token.cancel('paused');
    }

    final task = await _db.get(fileId);
    if (task != null && task.isActive) {
      await _updateTask(task.copyWith(status: DownloadStatus.paused));
    }
  }

  /// Cancel and delete download
  Future<void> cancel(int fileId) async {
    await pause(fileId);

    final task = await _db.get(fileId);
    if (task != null) {
      await _deleteFiles(task);
      await _updateTask(task.copyWith(status: DownloadStatus.cancelled));
      await _db.delete(fileId);
    }

    _cleanup(fileId);
  }

  /// Get current download status
  Future<DownloadTask?> getDownload(int fileId) => _db.get(fileId);

  /// Get all downloads
  Future<List<DownloadTask>> getAllDownloads() => _db.getAll();

  Future<void> _startDownload(
    DownloadTask task,
    Completer<DownloadResult> completer,
  ) async {
    try {
      task = task.copyWith(status: DownloadStatus.downloading);
      await _updateTask(task);

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      final directory = Configuration.instance.getTempDirectory();
      final basePath = '$directory${task.id}_${task.filename}';

      // Check existing chunks and calculate progress
      final totalChunks = (task.totalBytes / _chunkSize).ceil();
      final existingChunks =
          await _validateExistingChunks(basePath, task.totalBytes, totalChunks);

      task = task.copyWith(
        bytesDownloaded: _calculateDownloadedBytes(
          existingChunks,
          task.totalBytes,
          totalChunks,
        ),
      );
      await _updateTask(task);

      // Download missing chunks
      for (int i = 0; i < totalChunks; i++) {
        if (existingChunks[i] || cancelToken.isCancelled) continue;

        await _downloadChunk(task, basePath, i, totalChunks, cancelToken);
        existingChunks[i] = true;
      }

      if (!cancelToken.isCancelled) {
        final finalPath = await _combineChunks(basePath, totalChunks);
        task = task.copyWith(
          status: DownloadStatus.completed,
          filePath: finalPath,
          bytesDownloaded: task.totalBytes,
        );
        await _updateTask(task);
        completer.complete(DownloadResult(task, true));
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        // Handle pause - don't complete the future
        return;
      }

      task = task.copyWith(status: DownloadStatus.error, error: e.toString());
      await _updateTask(task);
      completer.complete(DownloadResult(task, false));
    } finally {
      _cleanup(task.id);
    }
  }

  Future<List<bool>> _validateExistingChunks(
    String basePath,
    int totalBytes,
    int totalChunks,
  ) async {
    final existingChunks = List.filled(totalChunks, false);

    for (int i = 0; i < totalChunks; i++) {
      final chunkFile = File('$basePath.part${i + 1}');
      if (!await chunkFile.exists()) continue;

      final expectedSize =
          i == totalChunks - 1 ? totalBytes - (i * _chunkSize) : _chunkSize;

      final actualSize = await chunkFile.length();
      if (actualSize == expectedSize) {
        existingChunks[i] = true;
      } else {
        await chunkFile.delete(); // Remove corrupted chunk
      }
    }

    return existingChunks;
  }

  int _calculateDownloadedBytes(
    List<bool> existingChunks,
    int totalBytes,
    int totalChunks,
  ) {
    int bytes = 0;
    for (int i = 0; i < existingChunks.length; i++) {
      if (existingChunks[i]) {
        bytes +=
            i == totalChunks - 1 ? totalBytes - (i * _chunkSize) : _chunkSize;
      }
    }
    return bytes;
  }

  Future<void> _downloadChunk(
    DownloadTask task,
    String basePath,
    int chunkIndex,
    int totalChunks,
    CancelToken cancelToken,
  ) async {
    final chunkPath = '$basePath.part${chunkIndex + 1}';
    final startByte = chunkIndex * _chunkSize;
    final endByte = chunkIndex == totalChunks - 1
        ? task.totalBytes - 1
        : (startByte + _chunkSize) - 1;

    await _dio.download(
      FileUrl.getUrl(task.id, FileUrlType.download),
      chunkPath,
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
          "Range": "bytes=$startByte-$endByte",
        },
      ),
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) async {
        final updatedTask = task.copyWith(
          bytesDownloaded: task.bytesDownloaded + received,
        );
        _notifyProgress(updatedTask);
      },
    );

    // Update progress after chunk completion
    final chunkSize = await File(chunkPath).length();
    task = task.copyWith(bytesDownloaded: task.bytesDownloaded + chunkSize);
    await _updateTask(task);
  }

  Future<String> _combineChunks(String basePath, int totalChunks) async {
    final finalFile = File(basePath);
    final sink = finalFile.openWrite();

    try {
      for (int i = 1; i <= totalChunks; i++) {
        final chunkFile = File('$basePath.part$i');
        final bytes = await chunkFile.readAsBytes();
        sink.add(bytes);
        await chunkFile.delete();
      }
    } finally {
      await sink.close();
    }

    return finalFile.path;
  }

  Future<void> _deleteFiles(DownloadTask task) async {
    try {
      final directory = Configuration.instance.getTempDirectory();
      final basePath = '$directory${task.id}_${task.filename}';
      // Delete final file
      final finalFile = File(basePath);
      if (await finalFile.exists()) await finalFile.delete();

      // Delete chunk files
      final totalChunks = (task.totalBytes / _chunkSize).ceil();
      for (int i = 1; i <= totalChunks; i++) {
        final chunkFile = File('$basePath.part$i');
        if (await chunkFile.exists()) await chunkFile.delete();
      }
    } catch (e) {
      _logger.warning('Error deleting files: $e');
    }
  }

  Future<void> _updateTask(DownloadTask task) async {
    await _db.save(task);
    _notifyProgress(task);
  }

  void _notifyProgress(DownloadTask task) {
    final stream = _streams[task.id];
    if (stream != null && !stream.isClosed) {
      stream.add(task);
    }
  }

  void _cleanup(int fileId) {
    _completers.remove(fileId);
    _cancelTokens.remove(fileId);

    final stream = _streams[fileId];
    if (stream != null && !stream.hasListener) {
      stream.close();
      _streams.remove(fileId);
    }
  }

  Future<void> dispose() async {
    for (final completer in _completers.values) {
      if (!completer.isCompleted) {
        completer.completeError('Disposed');
      }
    }
    _completers.clear();

    for (final token in _cancelTokens.values) {
      token.cancel('Disposed');
    }
    _cancelTokens.clear();

    for (final stream in _streams.values) {
      await stream.close();
    }
    _streams.clear();
  }
}
