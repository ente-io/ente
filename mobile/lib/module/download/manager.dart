import "dart:async";
import "dart:io";

import "package:dio/dio.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";

import "package:photos/module/download/file_url.dart";
import "package:photos/module/download/task.dart";

class DownloadManager {
  final _logger = Logger('DownloadManager');
  static const int downloadChunkSize = 40 * 1024 * 1024;

  final Dio _dio;

  // In-memory storage for download tasks
  final Map<int, DownloadTask> _tasks = {};

  // Active downloads with their completers and streams
  final Map<int, Completer<DownloadResult>> _completers = {};
  final Map<int, StreamController<DownloadTask>> _streams = {};
  final Map<int, CancelToken> _cancelTokens = {};
  final Map<int, int> _downloadStartTimes = {};

  DownloadManager(this._dio);

  /// Subscribe to download progress updates for a specific file ID
  Stream<DownloadTask> watchDownload(int fileId) {
    _streams[fileId] ??= StreamController<DownloadTask>.broadcast();
    return _streams[fileId]!.stream;
  }

  bool enableResumableDownload(int? size) {
    if (size == null) return false;
    //todo: Use FileUrlType.direct instead of FileUrlType.directDownload
    return size > downloadChunkSize;
  }

  /// Start download and return a Future that completes when download finishes
  /// If download was paused, calling this again will resume it
  Future<DownloadResult> download(
    int fileId,
    String filename,
    int totalBytes,
  ) async {
    _downloadStartTimes[fileId] = DateTime.now().microsecondsSinceEpoch;
    // If already downloading, return existing future
    if (_completers.containsKey(fileId)) {
      return _completers[fileId]!.future;
    }

    final completer = Completer<DownloadResult>();
    _completers[fileId] = completer;

    // Get or create task
    final existingTask = _tasks[fileId];
    final task = existingTask ??
        DownloadTask(
          id: fileId,
          filename: filename,
          totalBytes: totalBytes,
        );

    // Store task in memory
    _tasks[fileId] = task;

    // Don't restart if already completed
    if (task.isCompleted) {
      // ensure that the file exists
      final filePath = task.filePath;
      if (filePath == null || !(await File(filePath).exists())) {
        // If the file doesn't exist, mark the task as error
        _logger.warning(
          'File not found for ${task.filename} (${task.bytesDownloaded}/${task.totalBytes} bytes)',
        );
        final updatedTask = task.copyWith(
          status: DownloadStatus.error,
          error: 'File not found',
          filePath: null,
        );
        _updateTask(updatedTask);
        final result = DownloadResult(updatedTask, false);
        completer.complete(result);
        return result;
      } else {
        _logger.info(
          'Download already completed for ${task.filename} (${task.bytesDownloaded}/${task.totalBytes} bytes)',
        );
        final result = DownloadResult(task, true);
        completer.complete(result);
        return result;
      }
    }
    unawaited(_startDownload(task, completer));
    return completer.future;
  }

  /// Pause download
  Future<void> pause(int fileId) async {
    // ignore cancel if download started less than 1 second ago,
    // this is to avoid cancellination due to different type of video players, where dispose is called
    // little later after other video player operations
    final startTime = _downloadStartTimes[fileId];
    if (startTime == null ||
        DateTime.now().microsecondsSinceEpoch - startTime < 1e6) {
      _logger.info('Download paused too soon, ignoring pause request');
      return;
    }
    final token = _cancelTokens[fileId];
    if (token != null && !token.isCancelled) {
      token.cancel('paused');
    }

    final task = _tasks[fileId];
    if (task != null && task.isActive) {
      _updateTask(task.copyWith(status: DownloadStatus.paused));
    }

    // Clean up streams if no listeners
    final stream = _streams[fileId];
    if (stream != null && !stream.hasListener) {
      await stream.close();
      _streams.remove(fileId);
    }
  }

  /// Cancel and delete download
  Future<void> cancel(int fileId) async {
    final token = _cancelTokens[fileId];
    if (token != null && !token.isCancelled) {
      token.cancel('cancelled');
    }

    final task = _tasks[fileId];
    if (task != null) {
      await _deleteFiles(task);
      _updateTask(task.copyWith(status: DownloadStatus.cancelled));
      _tasks.remove(fileId);
    }
    _cleanup(fileId);
  }

  /// Get current download status
  Future<DownloadTask?> getDownload(int fileId) async => _tasks[fileId];

  /// Get all downloads
  Future<List<DownloadTask>> getAllDownloads() async => _tasks.values.toList();

  Future<void> _startDownload(
    DownloadTask task,
    Completer<DownloadResult> completer,
  ) async {
    try {
      task = task.copyWith(status: DownloadStatus.downloading);
      _updateTask(task);

      final cancelToken = CancelToken();
      _cancelTokens[task.id] = cancelToken;

      final directory = Configuration.instance.getTempDirectory();
      final basePath = '$directory${task.id}.encrypted';

      // check if base file already exists and is of correct size
      final baseFile = File(basePath);
      if (await baseFile.exists()) {
        final existingSize = await baseFile.length();
        if (existingSize == task.totalBytes) {
          _logger.info(
            'Download already exists for ${task.filename} (${existingSize}/${task.totalBytes} bytes)',
          );
          task = task.copyWith(
            status: DownloadStatus.completed,
            filePath: basePath,
            bytesDownloaded: existingSize,
          );
          _updateTask(task);
          completer.complete(DownloadResult(task, true));
          return;
        } else {
          _logger.warning(
            'Existing file size mismatch for ${task.filename}: '
            'expected ${task.totalBytes}, but got $existingSize',
          );
          await baseFile.delete(); // Remove corrupted file
        }
      }

      // Check existing chunks and calculate progress
      final totalChunks = (task.totalBytes / downloadChunkSize).ceil();
      final existingChunks =
          await _validateExistingChunks(basePath, task.totalBytes, totalChunks);

      task = task.copyWith(
        bytesDownloaded: _calculateDownloadedBytes(
          existingChunks,
          task.totalBytes,
          totalChunks,
        ),
      );
      _updateTask(task);

      _logger.info(
        'Resuming download for ${task.filename} (${task.bytesDownloaded}/${task.totalBytes} bytes)',
      );
      for (int i = 0; i < totalChunks; i++) {
        if (existingChunks[i]) {
          continue;
        }
        if (cancelToken.isCancelled) {
          _logger.info('Download cancelled for ${task.filename}');
          break;
        }
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
        _updateTask(task);
        completer.complete(DownloadResult(task, true));
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.cancel) {
        _logger.info('Download cancelled for ${task.filename}');
        // Complete future with current task state (paused or cancelled)
        final currentTask = _tasks[task.id];
        if (currentTask != null && !completer.isCompleted) {
          completer.complete(DownloadResult(currentTask, false));
        }
        return;
      }
      _logger.warning('Error downloading ${task.filename}', e);
      task = task.copyWith(status: DownloadStatus.error, error: e.toString());
      _updateTask(task);
      if (!completer.isCompleted) {
        completer.complete(DownloadResult(task, false));
      }
    } finally {
      _cleanup(task.id);
    }
  }

  String _getChunkPath(String basePath, int part) {
    return '$basePath.${part}_part';
  }

  Future<List<bool>> _validateExistingChunks(
    String basePath,
    int totalBytes,
    int totalChunks,
  ) async {
    final existingChunks = List.filled(totalChunks, false);

    for (int i = 0; i < totalChunks; i++) {
      final chunkFile = File(_getChunkPath(basePath, i + 1));
      if (!await chunkFile.exists()) continue;

      final expectedSize = i == totalChunks - 1
          ? totalBytes - (i * downloadChunkSize)
          : downloadChunkSize;

      final actualSize = await chunkFile.length();
      if (actualSize == expectedSize) {
        _logger.info('existing chunk ${i + 1} is valid');
        existingChunks[i] = true;
      } else {
        _logger.warning(
          'Chunk ${i + 1} is corrupted: expected $expectedSize bytes, '
          'but got $actualSize bytes',
        );
        existingChunks[i] = false;
        // await chunkFile.delete(); // Remove corrupted chunk
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
        bytes += i == totalChunks - 1
            ? totalBytes - (i * downloadChunkSize)
            : downloadChunkSize;
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
    final chunkPath = _getChunkPath(basePath, chunkIndex + 1);
    final startByte = chunkIndex * downloadChunkSize;
    final endByte = chunkIndex == totalChunks - 1
        ? task.totalBytes - 1
        : (startByte + downloadChunkSize) - 1;
    _logger.info('Downloading chunk ${chunkIndex + 1}/$totalChunks');
    await _dio.download(
      FileUrl.getUrl(task.id, FileUrlType.directDownload),
      chunkPath,
      queryParameters: {
        "token": Configuration.instance.getToken(),
      },
      options: Options(
        headers: {
          "Range": "bytes=$startByte-$endByte",
        },
      ),
      cancelToken: cancelToken,
      onReceiveProgress: (received, total) async {
        final updatedTask = task.copyWith(
          bytesDownloaded: (chunkIndex) * downloadChunkSize + received,
        );
        _notifyProgress(updatedTask);
      },
    );
    // Update progress after chunk completion
    final chunkFileSize = await File(chunkPath).length();
    task = task.copyWith(
      bytesDownloaded: (chunkIndex) * downloadChunkSize + chunkFileSize,
    );
    _updateTask(task);
  }

  Future<String> _combineChunks(String basePath, int totalChunks) async {
    final finalFile = File(basePath);
    final sink = finalFile.openWrite();
    try {
      for (int i = 1; i <= totalChunks; i++) {
        final chunkFile = File(_getChunkPath(basePath, i));
        await sink.addStream(chunkFile.openRead());
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
      final basePath = '$directory${task.id}.encrypted';
      final finalFile = File(basePath);
      if (await finalFile.exists()) await finalFile.delete();

      // Delete chunk files
      final totalChunks = (task.totalBytes / downloadChunkSize).ceil();
      for (int i = 1; i <= totalChunks; i++) {
        final chunkFile = File(_getChunkPath(basePath, i));
        if (await chunkFile.exists()) await chunkFile.delete();
      }
    } catch (e) {
      _logger.warning('Error deleting files: $e');
    }
  }

  void _updateTask(DownloadTask task) {
    _tasks[task.id] = task;
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

    _tasks.clear();
  }
}
