import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:ente_network/network.dart';
import 'package:ente_utils/fake_progress.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/download/models/task.dart';
import 'package:locker/services/files/download/service_locator.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:locker/utils/data_util.dart';
import 'package:logging/logging.dart';

final _logger = Logger("FileDownloader");

Future<File?> downloadAndDecrypt(
  EnteFile file,
  Uint8List fileKey, {
  ProgressCallback? progressCallback,
  bool shouldFakeProgress = false,
  bool shouldUseCache = false,
}) async {
  final String logPrefix = 'File-${file.uploadedFileID}:';
  _logger.info('$logPrefix starting download');

  final String tempDir = Configuration.instance.getTempDirectory();
  final String cacheDir = Configuration.instance.getCacheDirectory();

  String encryptedFilePath = "$tempDir${file.uploadedFileID}.encrypted";
  File encryptedFile = File(encryptedFilePath);

  final String decryptedFilePath = shouldUseCache
      ? "$cacheDir${file.displayName}"
      : "$tempDir${file.displayName}";

  final startTime = DateTime.now().millisecondsSinceEpoch;

  try {
    if (downloadManager.enableResumableDownload(file.fileSize)) {
      final DownloadResult result = await downloadManager.download(
        file.uploadedFileID!,
        file.displayName,
        file.fileSize!,
      );
      if (result.success) {
        encryptedFilePath = result.task.filePath!;
        encryptedFile = File(encryptedFilePath);
      } else {
        _logger.warning(
          '$logPrefix download failed ${result.task.error} ${result.task.status}',
        );
        return null;
      }
    } else {
      // If the file is small, download it directly to the final location
      final response = await Network.instance.getDio().download(
        file.downloadUrl,
        encryptedFilePath,
        options: Options(
          headers: {"X-Auth-Token": Configuration.instance.getToken()},
        ),
        onReceiveProgress: (a, b) {
          progressCallback?.call(a, b);
        },
      );
      if (response.statusCode != 200 || !encryptedFile.existsSync()) {
        _logger.warning('$logPrefix download failed ${response.toString()}');
        return null;
      }
    }

    final int sizeInBytes = file.fileSize ?? await encryptedFile.length();
    final double elapsedSeconds =
        (DateTime.now().millisecondsSinceEpoch - startTime) / 1000;
    final double speedInKBps = sizeInBytes / 1024.0 / elapsedSeconds;

    _logger.info(
      '$logPrefix download completed: ${formatBytes(sizeInBytes)}, avg speed: ${speedInKBps.toStringAsFixed(2)} KB/s',
    );

    // As decryption can take time, emit fake progress for large files during
    // decryption
    final FakePeriodicProgress? fakeProgress = shouldFakeProgress
        ? FakePeriodicProgress(
            callback: (count) {
              progressCallback?.call(sizeInBytes, sizeInBytes);
            },
            duration: const Duration(milliseconds: 5000),
          )
        : null;
    try {
      // Start the periodic callback after initial 5 seconds
      fakeProgress?.start();
      await CryptoUtil.decryptFile(
        encryptedFilePath,
        decryptedFilePath,
        CryptoUtil.base642bin(file.fileDecryptionHeader!),
        fileKey,
      );
      fakeProgress?.stop();
      _logger
          .info('$logPrefix decryption completed (ID ${file.uploadedFileID})');
    } catch (e, s) {
      fakeProgress?.stop();
      _logger.severe("Critical: $logPrefix failed to decrypt", e, s);
      return null;
    }
    await encryptedFile.delete();
    return File(decryptedFilePath);
  } catch (e, s) {
    _logger.severe("$logPrefix failed to download or decrypt", e, s);
    return null;
  }
}
