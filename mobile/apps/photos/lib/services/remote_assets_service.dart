import "dart:async";
import "dart:convert";
import "dart:io";

import "package:dio/dio.dart";
import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";
import "package:photos/service_locator.dart" show flagService, isOfflineMode;
import "package:synchronized/synchronized.dart";

class RemoteAssetsService {
  static final _logger = Logger("RemoteAssetsService");
  static const int _resumableThresholdBytes = 10 * 1024 * 1024;

  bool checkRemovedOldAssets = false;

  RemoteAssetsService._privateConstructor();
  final StreamController<(String, int, int)> _progressController =
      StreamController<(String, int, int)>.broadcast();
  final Map<String, Lock> _assetLocks = {};

  Stream<(String, int, int)> get progressStream => _progressController.stream;

  static final RemoteAssetsService instance =
      RemoteAssetsService._privateConstructor();

  Future<File> getAsset(String remotePath, {bool refetch = false}) async {
    return _lockFor(remotePath).synchronized(() async {
      final path = await _getLocalPath(remotePath);
      final file = File(path);
      if (await file.exists() && !refetch) {
        _logger.info("Returning cached file for $remotePath");
        return file;
      }

      final tempFile = File(_tempPath(path));
      await _downloadFile(remotePath, tempFile.path);
      await _replaceFile(tempFile, file);
      await _deleteResumeMetadata(tempFile.path);
      return file;
    });
  }

  Future<String> getAssetPath(String remotePath, {bool refetch = false}) async {
    await cleanupOldModelsIfNeeded();
    final file = await getAsset(remotePath, refetch: refetch);
    return file.path;
  }

  ///Returns asset if the remote asset is new compared to the local copy of it
  Future<File?> getAssetIfUpdated(String remotePath) async {
    return _lockFor(remotePath).synchronized(() async {
      try {
        final path = await _getLocalPath(remotePath);
        final file = File(path);
        final tempFile = File(_tempPath(path));

        if (!await file.exists()) {
          await _downloadFile(remotePath, tempFile.path);
          await _replaceFile(tempFile, file);
          await _deleteResumeMetadata(tempFile.path);
          return file;
        }

        final existingFileSize = await file.length();
        await _downloadFile(remotePath, tempFile.path);
        final newFileSize = await tempFile.length();
        if (existingFileSize != newFileSize) {
          await _replaceFile(tempFile, file);
          await _deleteResumeMetadata(tempFile.path);
          return file;
        }

        await _clearResumeArtifacts(tempFile.path);
        return null;
      } catch (e) {
        _logger.warning("Error getting asset if updated", e);
        return null;
      }
    });
  }

  Future<bool> hasAsset(String remotePath) async {
    final path = await _getLocalPath(remotePath);
    return File(path).exists();
  }

  Future<String> _getLocalPath(String remotePath) async {
    return (await getApplicationSupportDirectory()).path +
        "/assets/" +
        _urlToFileName(remotePath);
  }

  String _urlToFileName(String url) {
    // Remove the protocol part (http:// or https://)
    String fileName = url
        .replaceAll(RegExp(r'https?://'), '')
        // Replace all non-alphanumeric characters except for underscores and periods with an underscore
        .replaceAll(RegExp(r'[^\w\.]'), '_');
    // Optionally, you might want to trim the resulting string to a certain length

    // Replace periods with underscores for better readability, if desired
    fileName = fileName.replaceAll('.', '_');

    return fileName;
  }

  Future<void> _downloadFile(String url, String savePath) async {
    _logger.info("Downloading " + url);
    final probe = await _probeRemoteAsset(url);
    if (_shouldUseResumableDownload(probe)) {
      await _downloadFileResumable(url, savePath, probe!);
    } else {
      await _downloadFileSingleShot(url, savePath);
    }

    _logger.info("Downloaded " + url);
  }

  Future<void> _downloadFileSingleShot(String url, String savePath) async {
    await _clearResumeArtifacts(savePath);

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        _emitProgress(url, received, total);
      },
    );
  }

  Future<void> cleanupOldModelsIfNeeded() async {
    if (checkRemovedOldAssets) return;
    const oldModelNames = [
      "https://models.ente.io/clip-image-vit-32-float32.onnx",
      "https://models.ente.io/clip-text-vit-32-uint8.onnx",
      "https://models.ente.io/mobileclip_s2_image_opset18_rgba_sim.onnx",
      "https://models.ente.io/mobileclip_s2_image_opset18_rgba_opt.onnx",
      "https://models.ente.io/mobileclip_s2_text_int32.onnx",
      "https://models.ente.io/yolov5s_face_opset18_rgba_opt.onnx",
      "https://models.ente.io/yolov5s_face_opset18_rgba_opt_nosplits.onnx",
    ];

    await cleanupSelectedModels(oldModelNames);

    checkRemovedOldAssets = true;
    _logger.info("Old ML models cleaned up");
  }

  Future<void> cleanupSelectedModels(List<String> modelRemotePaths) async {
    for (final remotePath in modelRemotePaths) {
      final localPath = await _getLocalPath(remotePath);
      final hasArtifacts = await File(localPath).exists() ||
          await File(_tempPath(localPath)).exists() ||
          await File(_resumeMetadataPath(_tempPath(localPath))).exists();
      if (hasArtifacts) {
        _logger.info(
          'Removing unused ML model ${remotePath.split('/').last} at $localPath',
        );
        await _deleteAssetArtifacts(localPath);
      }
    }
  }

  Dio get _dio => NetworkClient.instance.getDio();

  bool get _resumableDownloadsEnabled =>
      flagService.internalUser || isOfflineMode;

  Lock _lockFor(String remotePath) =>
      _assetLocks.putIfAbsent(remotePath, Lock.new);

  String _tempPath(String finalPath) => "$finalPath.temp";

  String _resumeMetadataPath(String tempPath) => "$tempPath.resume.json";

  bool _shouldUseResumableDownload(_RemoteAssetProbe? probe) {
    if (!_resumableDownloadsEnabled || probe == null) {
      return false;
    }
    return probe.totalBytes > _resumableThresholdBytes && probe.canResume;
  }

  Future<_RemoteAssetProbe?> _probeRemoteAsset(String url) async {
    if (!_resumableDownloadsEnabled) {
      return null;
    }

    final headProbe = await _probeWithHead(url);
    if (headProbe != null &&
        (headProbe.canResume ||
            headProbe.totalBytes <= _resumableThresholdBytes)) {
      return headProbe;
    }

    final rangeProbe = await _probeWithRange(url);
    if (headProbe == null) {
      return rangeProbe;
    }
    if (rangeProbe == null) {
      return headProbe;
    }
    return headProbe.merge(rangeProbe);
  }

  Future<_RemoteAssetProbe?> _probeWithHead(String url) async {
    try {
      final response = await _dio.head<void>(url);
      return _RemoteAssetProbe.fromHeaders(
        url,
        response.statusCode,
        response.headers,
      );
    } catch (e) {
      _logger.fine("HEAD probe failed for $url: $e");
      return null;
    }
  }

  Future<_RemoteAssetProbe?> _probeWithRange(String url) async {
    Response<ResponseBody>? response;
    try {
      response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            HttpHeaders.rangeHeader: "bytes=0-0",
          },
          validateStatus: (status) =>
              status == HttpStatus.ok || status == HttpStatus.partialContent,
        ),
      );
      return _RemoteAssetProbe.fromHeaders(
        url,
        response.statusCode,
        response.headers,
      );
    } catch (e) {
      _logger.fine("Range probe failed for $url: $e");
      return null;
    } finally {
      await _cancelProbeResponse(response?.data);
    }
  }

  Future<void> _cancelProbeResponse(ResponseBody? body) async {
    if (body == null) {
      return;
    }
    final subscription = body.stream.listen((_) {});
    await subscription.cancel();
  }

  Future<void> _downloadFileResumable(
    String url,
    String savePath,
    _RemoteAssetProbe probe,
  ) async {
    final tempFile = File(savePath);
    final metadata = _ResumeMetadata.fromProbe(probe);
    final existingBytes = await _prepareTempFileForResume(
      tempFile,
      metadata,
      probe,
    );

    await _writeResumeMetadata(savePath, metadata);

    if (existingBytes == probe.totalBytes) {
      _emitProgress(url, existingBytes, probe.totalBytes);
      return;
    }
    if (existingBytes > 0) {
      _emitProgress(url, existingBytes, probe.totalBytes);
    }

    try {
      await _startResumableDownload(url, savePath, probe, existingBytes);
    } on DioException catch (e) {
      if (existingBytes > 0 && _shouldRestartDownloadFromScratch(e)) {
        _logger.info("Restarting resumable download from scratch for $url");
        await _clearResumeArtifacts(savePath);
        await _writeResumeMetadata(savePath, metadata);
        await _startResumableDownload(url, savePath, probe, 0);
        return;
      }
      rethrow;
    }
  }

  Future<int> _prepareTempFileForResume(
    File tempFile,
    _ResumeMetadata metadata,
    _RemoteAssetProbe probe,
  ) async {
    final metadataFile = File(_resumeMetadataPath(tempFile.path));
    final tempExists = await tempFile.exists();
    final metadataExists = await metadataFile.exists();

    if (!tempExists) {
      if (metadataExists) {
        await metadataFile.delete();
      }
      return 0;
    }

    if (!metadataExists) {
      await _clearResumeArtifacts(tempFile.path);
      return 0;
    }

    final storedMetadata = await _readResumeMetadata(tempFile.path);
    if (storedMetadata == null || !storedMetadata.matches(metadata)) {
      await _clearResumeArtifacts(tempFile.path);
      return 0;
    }

    final existingBytes = await tempFile.length();
    if (existingBytes <= 0 || existingBytes > probe.totalBytes) {
      await _clearResumeArtifacts(tempFile.path);
      return 0;
    }

    return existingBytes;
  }

  Future<void> _startResumableDownload(
    String url,
    String savePath,
    _RemoteAssetProbe probe,
    int existingBytes,
  ) async {
    if (existingBytes > 0) {
      await _dio.download(
        url,
        savePath,
        deleteOnError: false,
        fileAccessMode: FileAccessMode.append,
        options: Options(
          headers: {
            HttpHeaders.rangeHeader: "bytes=$existingBytes-",
          },
          validateStatus: (status) => status == HttpStatus.partialContent,
        ),
        onReceiveProgress: (received, _) {
          _emitProgress(url, existingBytes + received, probe.totalBytes);
        },
      );
      return;
    }

    await _dio.download(
      url,
      savePath,
      deleteOnError: false,
      onReceiveProgress: (received, total) {
        _emitProgress(
          url,
          received,
          probe.totalBytes > 0 ? probe.totalBytes : total,
        );
      },
    );
  }

  bool _shouldRestartDownloadFromScratch(DioException error) {
    if (error.type != DioExceptionType.badResponse) {
      return false;
    }
    final statusCode = error.response?.statusCode;
    return statusCode == HttpStatus.ok ||
        statusCode == HttpStatus.requestedRangeNotSatisfiable;
  }

  Future<_ResumeMetadata?> _readResumeMetadata(String tempPath) async {
    final file = File(_resumeMetadataPath(tempPath));
    if (!await file.exists()) {
      return null;
    }
    try {
      final raw = await file.readAsString();
      return _ResumeMetadata.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (e, s) {
      _logger.warning("Failed to parse resume metadata for $tempPath", e, s);
      return null;
    }
  }

  Future<void> _writeResumeMetadata(
    String tempPath,
    _ResumeMetadata metadata,
  ) async {
    final file = File(_resumeMetadataPath(tempPath));
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(metadata.toJson()), flush: true);
  }

  Future<void> _deleteResumeMetadata(String tempPath) async {
    await _deleteFileIfExists(File(_resumeMetadataPath(tempPath)));
  }

  Future<void> _clearResumeArtifacts(String tempPath) async {
    await _deleteFileIfExists(File(tempPath));
    await _deleteResumeMetadata(tempPath);
  }

  Future<void> _replaceFile(File source, File target) async {
    await target.parent.create(recursive: true);
    await _deleteFileIfExists(target);
    await source.rename(target.path);
  }

  Future<void> _deleteAssetArtifacts(String localPath) async {
    await _deleteFileIfExists(File(localPath));
    await _clearResumeArtifacts(_tempPath(localPath));
  }

  Future<void> _deleteFileIfExists(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  void _emitProgress(String url, int received, int total) {
    if (received > 0 && total > 0) {
      final boundedReceived = received > total ? total : received;
      _progressController.add((url, boundedReceived, total));
    } else if (kDebugMode) {
      debugPrint("$url Received: $received, Total: $total");
    }
  }
}

class _RemoteAssetProbe {
  const _RemoteAssetProbe({
    required this.url,
    required this.totalBytes,
    required this.acceptsRanges,
    required this.etag,
    required this.lastModified,
  });

  static _RemoteAssetProbe? fromHeaders(
    String url,
    int? statusCode,
    Headers headers,
  ) {
    final totalBytes = _parseTotalBytes(headers);
    if (totalBytes == null || totalBytes <= 0) {
      return null;
    }

    return _RemoteAssetProbe(
      url: url,
      totalBytes: totalBytes,
      acceptsRanges: _acceptsRanges(headers, statusCode),
      etag: _normalizeHeader(headers.value(HttpHeaders.etagHeader)),
      lastModified: _normalizeHeader(
        headers.value(HttpHeaders.lastModifiedHeader),
      ),
    );
  }

  final String url;
  final int totalBytes;
  final bool acceptsRanges;
  final String? etag;
  final String? lastModified;

  bool get hasStableValidator => etag != null || lastModified != null;

  bool get canResume => acceptsRanges && hasStableValidator;

  _RemoteAssetProbe merge(_RemoteAssetProbe other) {
    return _RemoteAssetProbe(
      url: url,
      totalBytes: other.totalBytes > 0 ? other.totalBytes : totalBytes,
      acceptsRanges: acceptsRanges || other.acceptsRanges,
      etag: other.etag ?? etag,
      lastModified: other.lastModified ?? lastModified,
    );
  }

  static int? _parseTotalBytes(Headers headers) {
    final contentRange = headers.value(HttpHeaders.contentRangeHeader);
    if (contentRange != null) {
      final match = RegExp(r"bytes\s+\d+-\d+/(\d+)").firstMatch(contentRange);
      final totalString = match?.group(1);
      if (totalString != null) {
        return int.tryParse(totalString);
      }
    }

    final contentLength = headers.value(HttpHeaders.contentLengthHeader);
    return int.tryParse(contentLength ?? "");
  }

  static bool _acceptsRanges(Headers headers, int? statusCode) {
    final acceptRanges = _normalizeHeader(headers.value("accept-ranges"));
    return statusCode == HttpStatus.partialContent ||
        acceptRanges == "bytes" ||
        headers.value(HttpHeaders.contentRangeHeader) != null;
  }

  static String? _normalizeHeader(String? value) {
    if (value == null) {
      return null;
    }
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ResumeMetadata {
  const _ResumeMetadata({
    required this.url,
    required this.totalBytes,
    required this.etag,
    required this.lastModified,
  });

  factory _ResumeMetadata.fromProbe(_RemoteAssetProbe probe) {
    return _ResumeMetadata(
      url: probe.url,
      totalBytes: probe.totalBytes,
      etag: probe.etag,
      lastModified: probe.lastModified,
    );
  }

  factory _ResumeMetadata.fromJson(Map<String, dynamic> json) {
    return _ResumeMetadata(
      url: json["url"] as String,
      totalBytes: json["totalBytes"] as int,
      etag: json["etag"] as String?,
      lastModified: json["lastModified"] as String?,
    );
  }

  final String url;
  final int totalBytes;
  final String? etag;
  final String? lastModified;

  Map<String, dynamic> toJson() {
    return {
      "url": url,
      "totalBytes": totalBytes,
      "etag": etag,
      "lastModified": lastModified,
    };
  }

  bool matches(_ResumeMetadata other) {
    return url == other.url &&
        totalBytes == other.totalBytes &&
        etag == other.etag &&
        lastModified == other.lastModified;
  }
}
