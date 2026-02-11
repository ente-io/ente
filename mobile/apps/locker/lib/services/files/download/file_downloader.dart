import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:ente_crypto_api/ente_crypto_api.dart';
import 'package:ente_network/network.dart';
import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/download/models/task.dart';
import 'package:locker/services/files/download/service_locator.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;

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

  final String cachedEncryptedFilePath =
      "$cacheDir${file.uploadedFileID}.encrypted";
  final String tempEncryptedFilePath =
      "$tempDir${file.uploadedFileID}.encrypted";
  String encryptedFilePath = tempEncryptedFilePath;
  File encryptedFile = File(encryptedFilePath);
  bool usingCachedEncryptedFile = false;
  bool downloadedFreshEncryptedFile = false;

  final String safeDisplayName = p.basename(file.displayName);
  final String decryptedFilePath =
      "$tempDir${file.uploadedFileID}_$safeDisplayName";
  final File decryptedFile = File(decryptedFilePath);

  final startTime = DateTime.now().millisecondsSinceEpoch;

  try {
    bool shouldDownload = true;
    if (shouldUseCache) {
      final cachedEncryptedFile = File(cachedEncryptedFilePath);
      if (await cachedEncryptedFile.exists()) {
        final encryptedSize = await cachedEncryptedFile.length();
        if (encryptedSize > 0) {
          shouldDownload = false;
          usingCachedEncryptedFile = true;
          encryptedFilePath = cachedEncryptedFilePath;
          encryptedFile = cachedEncryptedFile;
          _logger.info('$logPrefix using cached encrypted file');
        } else {
          await cachedEncryptedFile.delete();
        }
      }
    }

    if (shouldDownload) {
      if (downloadManager.enableResumableDownload(file.fileSize)) {
        final DownloadResult result = await downloadManager.download(
          file.uploadedFileID!,
          file.displayName,
          file.fileSize!,
        );
        if (result.success) {
          encryptedFilePath = result.task.filePath!;
          encryptedFile = File(encryptedFilePath);
          downloadedFreshEncryptedFile = true;
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
          tempEncryptedFilePath,
          options: Options(
            headers: {"X-Auth-Token": Configuration.instance.getToken()},
          ),
          onReceiveProgress: (a, b) {
            progressCallback?.call(a, b);
          },
        );
        encryptedFilePath = tempEncryptedFilePath;
        encryptedFile = File(encryptedFilePath);
        downloadedFreshEncryptedFile = true;
        if (response.statusCode != 200 || !encryptedFile.existsSync()) {
          _logger.warning('$logPrefix download failed ${response.toString()}');
          return null;
        }
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
      if (await decryptedFile.exists()) {
        await decryptedFile.delete();
      }
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
      if (downloadedFreshEncryptedFile) {
        try {
          await encryptedFile.delete();
        } catch (_) {}
      } else if (usingCachedEncryptedFile) {
        // Cached encrypted file is likely corrupted; remove it so next attempt
        // fetches a fresh copy.
        try {
          await encryptedFile.delete();
        } catch (_) {}
      }
      return null;
    }
    if (shouldUseCache && downloadedFreshEncryptedFile) {
      try {
        if (encryptedFilePath != cachedEncryptedFilePath) {
          await encryptedFile.copy(cachedEncryptedFilePath);
          await encryptedFile.delete();
        }
      } catch (e, s) {
        _logger.warning(
          '$logPrefix failed to persist encrypted file cache',
          e,
          s,
        );
      }
    } else if (!shouldUseCache) {
      await encryptedFile.delete();
    }
    return decryptedFile;
  } catch (e, s) {
    _logger.severe("$logPrefix failed to download or decrypt", e, s);
    return null;
  }
}
