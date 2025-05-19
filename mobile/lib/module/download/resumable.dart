import "dart:async";
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DownloadTask {
  final int id;
  final String url;
  final String filename;
  int bytesDownloaded;
  int totalBytes;
  String status; // 'pending', 'downloading', 'paused', 'completed', 'error'
  String error;

  DownloadTask({
    required this.id,
    required this.url,
    required this.filename,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    this.status = 'pending',
    this.error = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'filename': filename,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'status': status,
      'error': error,
    };
  }

  factory DownloadTask.fromMap(Map<String, dynamic> map) {
    return DownloadTask(
      id: map['id'],
      url: map['url'],
      filename: map['filename'],
      bytesDownloaded: map['bytesDownloaded'],
      totalBytes: map['totalBytes'],
      status: map['status'],
      error: map['error'],
    );
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final String path = join(await getDatabasesPath(), 'download_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE downloads (
            id INTEGER PRIMARY KEY,
            url TEXT,
            filename TEXT,
            bytesDownloaded INTEGER,
            totalBytes INTEGER,
            status TEXT,
            error TEXT
          )
        ''');
      },
    );
  }

  Future<int> insertDownload(DownloadTask task) async {
    final db = await database;
    return await db.insert('downloads', task.toMap());
  }

  Future<int> updateDownload(DownloadTask task) async {
    final db = await database;
    return await db.update(
      'downloads',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<List<DownloadTask>> getDownloads() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('downloads');
    return List.generate(maps.length, (i) {
      return DownloadTask.fromMap(maps[i]);
    });
  }

  Future<DownloadTask?> getDownload(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return DownloadTask.fromMap(maps.first);
    }
    return null;
  }

  Future<int> deleteDownload(int id) async {
    final db = await database;
    return await db.delete(
      'downloads',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

class DownloadManager {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final Map<int, StreamController<DownloadTask>> _progressControllers = {};
  final Map<int, CancelToken> _cancelTokens = {};
  final Dio _dio = Dio();

  DownloadManager();

  // Stream for subscribers to listen for download updates
  Stream<DownloadTask> getDownloadProgress(int taskId) {
    if (!_progressControllers.containsKey(taskId)) {
      _progressControllers[taskId] = StreamController<DownloadTask>.broadcast();
    }
    return _progressControllers[taskId]!.stream;
  }

  // Create a new download task
  Future<DownloadTask> createDownload(String url, String filename) async {
    final task = DownloadTask(
      id: DateTime.now().millisecondsSinceEpoch,
      url: url,
      filename: filename,
      status: 'pending',
    );
    await _dbHelper.insertDownload(task);
    return task;
  }

  // Start or resume a download
  Future<void> startDownload(int taskId) async {
    final task = await _dbHelper.getDownload(taskId);
    if (task == null) return;

    if (task.status == 'downloading') return; // Already running

    task.status = 'downloading';
    await _dbHelper.updateDownload(task);
    _updateProgress(task);

    // Create a cancel token for this download
    final cancelToken = CancelToken();
    _cancelTokens[taskId] = cancelToken;

    try {
      // Get download directory and create file
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${task.filename}';
      final file = File(filePath);

      // Prepare request options
      final options = Options(
        headers: {},
        responseType: ResponseType.stream,
      );

      // If we've already downloaded some bytes, add Range header
      if (task.bytesDownloaded > 0) {
        options.headers!['Range'] = 'bytes=${task.bytesDownloaded}-';
      }

      // Make HEAD request first to get content length if we don't have it
      if (task.totalBytes == 0) {
        try {
          final headResponse = await _dio.head(
            task.url,
            options: Options(
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          final contentLength = headResponse.headers.value('content-length');
          if (contentLength != null) {
            task.totalBytes = int.parse(contentLength);
            await _dbHelper.updateDownload(task);
            _updateProgress(task);
          }
        } catch (e) {
          // Failed to get size, will try to get it from GET request
          print('Failed to get content length via HEAD: $e');
        }
      }

      // Make actual download request
      final response = await _dio.get(
        task.url,
        options: options,
        cancelToken: cancelToken,
      );

      // For handling the response stream
      final responseStream = response.data.stream as Stream<List<int>>;

      // Check response status
      final statusCode = response.statusCode ?? 0;

      if (statusCode == 200 || statusCode == 206) {
        // Get total file size from headers if not already known
        if (task.totalBytes == 0) {
          final contentLength = response.headers.value('content-length');
          if (contentLength != null) {
            task.totalBytes = int.parse(contentLength);

            // If it's a partial response, add what we've already downloaded
            if (statusCode == 206) {
              // Parse content range header to get total size
              final contentRange = response.headers.value('content-range');
              if (contentRange != null && contentRange.contains('/')) {
                final totalString = contentRange.split('/').last;
                if (totalString != '*') {
                  task.totalBytes = int.parse(totalString);
                } else {
                  // If server sends '*', we add what we already have
                  task.totalBytes += task.bytesDownloaded;
                }
              } else {
                task.totalBytes += task.bytesDownloaded;
              }
            }

            await _dbHelper.updateDownload(task);
            _updateProgress(task);
          }
        }

        // Open the file in append mode if resuming, otherwise create new
        IOSink fileSink;
        if (task.bytesDownloaded > 0 && statusCode == 206) {
          fileSink = file.openWrite(mode: FileMode.append);
        } else {
          // If it's not a partial response, start from the beginning
          task.bytesDownloaded = 0;
          fileSink = file.openWrite(mode: FileMode.write);
        }

        // Process the response stream
        await responseStream.listen(
          (List<int> chunk) async {
            // Write to file
            fileSink.add(chunk);

            // Update progress
            task.bytesDownloaded += chunk.length;
            await _dbHelper.updateDownload(task);
            _updateProgress(task);
          },
          onDone: () async {
            await fileSink.close();

            // Download completed
            task.status = 'completed';
            await _dbHelper.updateDownload(task);
            _updateProgress(task);

            _cancelTokens.remove(taskId);
          },
          onError: (error) async {
            await fileSink.close();

            // Handle error
            task.status = 'error';
            task.error = error.toString();
            await _dbHelper.updateDownload(task);
            _updateProgress(task);

            _cancelTokens.remove(taskId);
          },
          cancelOnError: true,
        ).asFuture();
      } else if (statusCode == 416) {
        // Requested range not satisfiable
        task.bytesDownloaded = 0;
        task.error = 'Server does not support resume. Starting from beginning.';
        await _dbHelper.updateDownload(task);
        _updateProgress(task);

        // Retry from beginning
        await startDownload(taskId);
      } else {
        // Other HTTP error
        task.status = 'error';
        task.error = 'HTTP Error: $statusCode';
        await _dbHelper.updateDownload(task);
        _updateProgress(task);

        _cancelTokens.remove(taskId);
      }
    } on DioException catch (e) {
      // Handle Dio exceptions
      if (e.type == DioExceptionType.cancel) {
        // Download was canceled - don't update status as it was likely paused
        _cancelTokens.remove(taskId);
        return;
      }

      task.status = 'error';
      task.error = 'Download error: ${e.message}';
      await _dbHelper.updateDownload(task);
      _updateProgress(task);

      _cancelTokens.remove(taskId);
    } catch (e) {
      // Handle generic exceptions
      task.status = 'error';
      task.error = e.toString();
      await _dbHelper.updateDownload(task);
      _updateProgress(task);

      _cancelTokens.remove(taskId);
    }
  }

  // Pause a download
  Future<void> pauseDownload(int taskId) async {
    final task = await _dbHelper.getDownload(taskId);
    if (task == null) return;

    if (task.status == 'downloading') {
      task.status = 'paused';
      await _dbHelper.updateDownload(task);
      _updateProgress(task);

      // Cancel the download
      if (_cancelTokens.containsKey(taskId)) {
        _cancelTokens[taskId]!.cancel('Download paused');
        _cancelTokens.remove(taskId);
      }
    }
  }

  // Cancel and delete a download
  Future<void> cancelDownload(int taskId) async {
    // Pause download first
    await pauseDownload(taskId);

    // Delete the file
    final task = await _dbHelper.getDownload(taskId);
    if (task != null) {
      try {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/${task.filename}');
        if (await file.exists()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting file: $e');
      }
    }

    // Remove from database
    await _dbHelper.deleteDownload(taskId);

    // Close the stream controller
    if (_progressControllers.containsKey(taskId)) {
      await _progressControllers[taskId]!.close();
      _progressControllers.remove(taskId);
    }
  }

  // Get a list of all downloads
  Future<List<DownloadTask>> getAllDownloads() async {
    return await _dbHelper.getDownloads();
  }

  // Update the progress and notify listeners
  void _updateProgress(DownloadTask task) {
    if (_progressControllers.containsKey(task.id) &&
        !_progressControllers[task.id]!.isClosed) {
      _progressControllers[task.id]!.add(task);
    }
  }

  // Cleanup resources
  Future<void> dispose() async {
    for (final controller in _progressControllers.values) {
      await controller.close();
    }
    _progressControllers.clear();

    for (final cancelToken in _cancelTokens.values) {
      cancelToken.cancel('Disposed');
    }
    _cancelTokens.clear();
  }
}
