import 'dart:io';

import 'package:dio/dio.dart';
import "package:flutter/foundation.dart";
import 'package:logging/logging.dart';
import 'package:path/path.dart' as file_path;
import "package:photo_manager/photo_manager.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import 'package:photos/core/network/network.dart';
import "package:photos/db/files_db.dart";
import "package:photos/events/local_photos_updated_event.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ignored_file.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/local_sync_service.dart";
import 'package:photos/utils/crypto_util.dart';
import "package:photos/utils/data_util.dart";
import "package:photos/utils/fake_progress.dart";
import "package:photos/utils/file_key.dart";
import "package:photos/utils/file_util.dart";

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
      _logger
          .info('$logPrefix decryption completed (genID ${file.generatedID})');
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

Future<void> downloadToGallery(EnteFile file) async {
  try {
    final FileType type = file.fileType;
    final bool downloadLivePhotoOnDroid =
        type == FileType.livePhoto && Platform.isAndroid;
    AssetEntity? savedAsset;
    final File? fileToSave = await getFile(file);
    //Disabling notifications for assets changing to insert the file into
    //files db before triggering a sync.
    await PhotoManager.stopChangeNotify();
    if (type == FileType.image) {
      savedAsset = await PhotoManager.editor
          .saveImageWithPath(fileToSave!.path, title: file.title!);
    } else if (type == FileType.video) {
      savedAsset =
          await PhotoManager.editor.saveVideo(fileToSave!, title: file.title!);
    } else if (type == FileType.livePhoto) {
      final File? liveVideoFile =
          await getFileFromServer(file, liveVideo: true);
      if (liveVideoFile == null) {
        throw AssertionError("Live video can not be null");
      }
      if (downloadLivePhotoOnDroid) {
        await _saveLivePhotoOnDroid(fileToSave!, liveVideoFile, file);
      } else {
        savedAsset = await PhotoManager.editor.darwin.saveLivePhoto(
          imageFile: fileToSave!,
          videoFile: liveVideoFile,
          title: file.title!,
        );
      }
    }

    if (savedAsset != null) {
      file.localID = savedAsset.id;
      await FilesDB.instance.insert(file);
      Bus.instance.fire(
        LocalPhotosUpdatedEvent(
          [file],
          source: "download",
        ),
      );
    } else if (!downloadLivePhotoOnDroid && savedAsset == null) {
      _logger.severe('Failed to save assert of type $type');
    }
  } catch (e) {
    _logger.severe("Failed to save file", e);
    rethrow;
  } finally {
    await PhotoManager.startChangeNotify();
    LocalSyncService.instance.checkAndSync().ignore();
  }
}

Future<void> _saveLivePhotoOnDroid(
  File image,
  File video,
  EnteFile enteFile,
) async {
  debugPrint("Downloading LivePhoto on Droid");
  AssetEntity? savedAsset = await (PhotoManager.editor
      .saveImageWithPath(image.path, title: enteFile.title!));
  if (savedAsset == null) {
    throw Exception("Failed to save image of live photo");
  }
  IgnoredFile ignoreVideoFile = IgnoredFile(
    savedAsset.id,
    savedAsset.title ?? '',
    savedAsset.relativePath ?? 'remoteDownload',
    "remoteDownload",
  );
  await IgnoredFilesService.instance.cacheAndInsert([ignoreVideoFile]);
  final videoTitle = file_path.basenameWithoutExtension(enteFile.title!) +
      file_path.extension(video.path);
  savedAsset = (await (PhotoManager.editor.saveVideo(
    video,
    title: videoTitle,
  )));
  if (savedAsset == null) {
    throw Exception("Failed to save video of live photo");
  }

  ignoreVideoFile = IgnoredFile(
    savedAsset.id,
    savedAsset.title ?? videoTitle,
    savedAsset.relativePath ?? 'remoteDownload',
    "remoteDownload",
  );
  await IgnoredFilesService.instance.cacheAndInsert([ignoreVideoFile]);
}
