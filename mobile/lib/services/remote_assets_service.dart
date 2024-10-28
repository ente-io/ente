import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";

class RemoteAssetsService {
  static final _logger = Logger("RemoteAssetsService");

  bool checkRemovedOldAssets = false;

  RemoteAssetsService._privateConstructor();
  final StreamController<(String, int, int)> _progressController =
      StreamController<(String, int, int)>.broadcast();

  Stream<(String, int, int)> get progressStream => _progressController.stream;

  static final RemoteAssetsService instance =
      RemoteAssetsService._privateConstructor();

  Future<File> getAsset(String remotePath, {bool refetch = false}) async {
    final path = await _getLocalPath(remotePath);
    final file = File(path);
    if (file.existsSync() && !refetch) {
      _logger.info("Returning cached file for $remotePath");
      return file;
    } else {
      final tempFile = File(path + ".temp");
      await _downloadFile(remotePath, tempFile.path);
      tempFile.renameSync(path);
      return File(path);
    }
  }

  Future<String> getAssetPath(String remotePath, {bool refetch = false}) async {
    await cleanupOldModelsIfNeeded();
    final file = await getAsset(remotePath, refetch: refetch);
    return file.path;
  }

  ///Returns asset if the remote asset is new compared to the local copy of it
  Future<File?> getAssetIfUpdated(String remotePath) async {
    try {
      final path = await _getLocalPath(remotePath);
      final file = File(path);
      if (!file.existsSync()) {
        final tempFile = File(path + ".temp");
        await _downloadFile(remotePath, tempFile.path);
        tempFile.renameSync(path);
        return File(path);
      } else {
        final existingFileSize = File(path).lengthSync();
        final tempFile = File(path + ".temp");
        await _downloadFile(remotePath, tempFile.path);
        final newFileSize = tempFile.lengthSync();
        if (existingFileSize != newFileSize) {
          tempFile.renameSync(path);
          return File(path);
        } else {
          tempFile.deleteSync();
          return null;
        }
      }
    } catch (e) {
      _logger.warning("Error getting asset if updated", e);
      return null;
    }
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
    final existingFile = File(savePath);
    if (existingFile.existsSync()) {
      existingFile.deleteSync();
    }

    await NetworkClient.instance.getDio().download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (received > 0 && total > 0) {
          _progressController.add((url, received, total));
        } else if (kDebugMode) {
          debugPrint("$url Received: $received, Total: $total");
        }
      },
    );

    _logger.info("Downloaded " + url);
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
      if (File(localPath).existsSync()) {
        _logger.info(
          'Removing unused ML model ${remotePath.split('/').last} at $localPath',
        );
        await File(localPath).delete();
      }
    }
  }
}
