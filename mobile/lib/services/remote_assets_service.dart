import "dart:async";
import "dart:io";

import "package:flutter/foundation.dart";
import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";

class RemoteAssetsService {
  static final _logger = Logger("RemoteAssetsService");

  RemoteAssetsService._privateConstructor();
  final StreamController<(String, int, int)> _progressController =
      StreamController<(String, int, int)>.broadcast();

  Stream<(String, int, int)> get progressStream => _progressController.stream;

  static final RemoteAssetsService instance =
      RemoteAssetsService._privateConstructor();

  Future<File> getAsset(String remotePath, {bool refetch = false}) async {
    final path = await _getLocalPath(remotePath);
    final file = File(path);
    if (await file.exists() && !refetch) {
      _logger.info("Returning cached file for $remotePath");
      return file;
    } else {
      final tempFile = File(path + ".temp");
      await _downloadFile(remotePath, tempFile.path);
      await tempFile.rename(path);
      return File(path);
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
    if (await existingFile.exists()) {
      await existingFile.delete();
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
}
