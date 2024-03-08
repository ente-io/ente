import 'dart:io';

import "package:computer/computer.dart";
import 'package:dio/dio.dart';
import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/crypto_util.dart';
import "package:photos/utils/data_util.dart";
import "package:photos/utils/fake_progress.dart";

final _logger = Logger("file_download_util");

Future<File?> downloadAndDecrypt(
  EnteFile file, {
  ProgressCallback? progressCallback,
}) async {
  final String logPrefix = 'File-${file.uploadedFileID}:';
  _logger
      .info('$logPrefix starting download ${formatBytes(file.fileSize ?? 0)}');

  final String tempDir = Configuration.instance.getTempDirectory();
  final String encryptedFilePath = "$tempDir${file.generatedID}.encrypted";
  final encryptedFile = File(encryptedFilePath);

  final startTime = DateTime.now().millisecondsSinceEpoch;

  try {
    final response = await NetworkClient.instance.getDio().download(
      file.downloadUrl,
      encryptedFilePath,
      options: Options(
        headers: {"X-Auth-Token": Configuration.instance.getToken()},
      ),
      onReceiveProgress: (a, b) {
        if (kDebugMode && a >= 0 && b >= 0) {
          // _logger.fine(
          //   "$logPrefix download progress: ${formatBytes(a)} / ${formatBytes(b)}",
          // );
        }
        progressCallback?.call(a, b);
      },
    );
    if (response.statusCode != 200 || !encryptedFile.existsSync()) {
      _logger.warning('$logPrefix download failed ${response.toString()}');
      return null;
    }

    final int sizeInBytes = file.fileSize ?? await encryptedFile.length();
    final double elapsedSeconds =
        (DateTime.now().millisecondsSinceEpoch - startTime) / 1000;
    final double speedInKBps = sizeInBytes / 1024.0 / elapsedSeconds;

    _logger.info(
      '$logPrefix download completed: ${formatBytes(sizeInBytes)}, avg speed: ${speedInKBps.toStringAsFixed(2)} KB/s',
    );

    final String decryptedFilePath = "$tempDir${file.generatedID}.decrypted";
    // As decryption can take time, emit fake progress for large files during
    // decryption
    final FakePeriodicProgress? fakeProgress = file.fileType == FileType.video
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
        getFileKey(file),
      );
      fakeProgress?.stop();
      _logger.info('$logPrefix decryption completed');
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

Uint8List getFileKey(EnteFile file) {
  final encryptedKey = CryptoUtil.base642bin(file.encryptedKey!);
  final nonce = CryptoUtil.base642bin(file.keyDecryptionNonce!);
  final collectionKey =
      CollectionsService.instance.getCollectionKey(file.collectionID!);
  return CryptoUtil.decryptSync(encryptedKey, collectionKey, nonce);
}

Future<Uint8List> getFileKeyUsingBgWorker(EnteFile file) async {
  final collectionKey =
      CollectionsService.instance.getCollectionKey(file.collectionID!);
  return await Computer.shared().compute(
    _decryptFileKey,
    param: <String, dynamic>{
      "encryptedKey": file.encryptedKey,
      "keyDecryptionNonce": file.keyDecryptionNonce,
      "collectionKey": collectionKey,
    },
  );
}

Uint8List _decryptFileKey(Map<String, dynamic> args) {
  final encryptedKey = CryptoUtil.base642bin(args["encryptedKey"]);
  final nonce = CryptoUtil.base642bin(args["keyDecryptionNonce"]);
  return CryptoUtil.decryptSync(
    encryptedKey,
    args["collectionKey"],
    nonce,
  );
}
