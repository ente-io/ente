import "dart:io";

import "package:logging/logging.dart";
import "package:path_provider/path_provider.dart";
import "package:photos/core/network/network.dart";

class RemoteAssetsService {
  static final _logger = Logger("RemoteAssetsService");

  RemoteAssetsService._privateConstructor();

  static final RemoteAssetsService instance =
      RemoteAssetsService._privateConstructor();

  Future<File> getAsset(String remotePath) async {
    final path = await _getLocalPath(remotePath);
    final file = File(path);
    if (await file.exists()) {
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
    await NetworkClient.instance.getDio().download(url, savePath);
    _logger.info("Downloaded " + url);
  }
}
