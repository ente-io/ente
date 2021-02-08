import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/cache/thumbnail_cache_manager.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/collection_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/repositories/file_repository.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/dialog_util.dart';

import 'crypto_util.dart';

final _logger = Logger("FileUtil");

Future<void> deleteFilesFromEverywhere(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  final localIDs = List<String>();
  for (final file in files) {
    if (file.localID != null) {
      localIDs.add(file.localID);
    }
  }
  final deletedIDs =
      (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  bool hasUploadedFiles = false;
  for (final file in files) {
    if (file.localID != null) {
      // Remove only those files that have been removed from disk
      if (deletedIDs.contains(file.localID)) {
        if (file.uploadedFileID != null) {
          hasUploadedFiles = true;
          await FilesDB.instance.markForDeletion(file.uploadedFileID);
        } else {
          await FilesDB.instance.deleteLocalFile(file.localID);
        }
      }
    } else {
      hasUploadedFiles = true;
      await FilesDB.instance.markForDeletion(file.uploadedFileID);
    }
    await dialog.hide();
  }

  await FileRepository.instance.reloadFiles();
  if (hasUploadedFiles) {
    Bus.instance.fire(CollectionUpdatedEvent());
    // TODO: Blocking call?
    SyncService.instance.deleteFilesOnServer();
  }
}

Future<void> deleteFilesOnDeviceOnly(
    BuildContext context, List<File> files) async {
  final dialog = createProgressDialog(context, "deleting...");
  await dialog.show();
  final localIDs = List<String>();
  for (final file in files) {
    if (file.localID != null) {
      localIDs.add(file.localID);
    }
  }
  final deletedIDs =
      (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  for (final file in files) {
    // Remove only those files that have been removed from disk
    if (deletedIDs.contains(file.localID)) {
      file.localID = null;
      FilesDB.instance.update(file);
    }
  }
  await FileRepository.instance.reloadFiles();
  await dialog.hide();
}

void preloadFile(File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  if (file.localID == null) {
    // getFileFromServer(file);
  } else {
    if (FileLruCache.get(file) == null) {
      file.getAsset().then((asset) {
        asset.file.then((assetFile) {
          FileLruCache.put(file, assetFile);
        });
      });
    }
  }
}

void preloadLocalFileThumbnail(File file) {
  if (file.localID == null ||
      ThumbnailLruCache.get(file, THUMBNAIL_SMALL_SIZE) != null) {
    return;
  }
  file.getAsset().then((asset) {
    asset
        .thumbDataWithSize(
      THUMBNAIL_SMALL_SIZE,
      THUMBNAIL_SMALL_SIZE,
      quality: THUMBNAIL_SMALL_SIZE_QUALITY,
    )
        .then((data) {
      ThumbnailLruCache.put(file, THUMBNAIL_SMALL_SIZE, data);
    });
  });
}

Future<io.File> getNativeFile(File file) async {
  if (file.localID == null) {
    return getFileFromServer(file);
  } else {
    return file.getAsset().then((asset) => asset.originFile);
  }
}

Future<Uint8List> getBytes(File file, {int quality = 100}) async {
  if (file.localID == null) {
    return getFileFromServer(file).then((file) => file.readAsBytesSync());
  } else {
    return await getBytesFromDisk(file, quality: quality);
  }
}

Future<Uint8List> getBytesFromDisk(File file, {int quality = 100}) async {
  final originalBytes = (await file.getAsset()).originBytes;
  if (extension(file.title) == ".HEIC" || quality != 100) {
    return originalBytes.then((bytes) {
      return FlutterImageCompress.compressWithList(bytes, quality: quality)
          .then((converted) {
        return Uint8List.fromList(converted);
      });
    });
  } else {
    return originalBytes;
  }
}

final Map<int, Future<io.File>> fileDownloadsInProgress =
    Map<int, Future<io.File>>();

final Map<int, Future<io.File>> thumbnailDownloadsInProgress =
    Map<int, Future<io.File>>();

Future<io.File> getFileFromServer(File file,
    {ProgressCallback progressCallback}) async {
  final cacheManager = file.fileType == FileType.video
      ? VideoCacheManager()
      : DefaultCacheManager();
  return cacheManager.getFileFromCache(file.getDownloadUrl()).then((info) {
    if (info == null) {
      if (!fileDownloadsInProgress.containsKey(file.uploadedFileID)) {
        fileDownloadsInProgress[file.uploadedFileID] = _downloadAndDecrypt(
          file,
          cacheManager,
          progressCallback: progressCallback,
        );
      }
      return fileDownloadsInProgress[file.uploadedFileID];
    } else {
      return info.file;
    }
  });
}

Future<io.File> getThumbnailFromServer(File file) async {
  return ThumbnailCacheManager()
      .getFileFromCache(file.getThumbnailUrl())
      .then((info) {
    if (info == null) {
      if (!thumbnailDownloadsInProgress.containsKey(file.uploadedFileID)) {
        thumbnailDownloadsInProgress[file.uploadedFileID] =
            _downloadAndDecryptThumbnail(file).then((data) {
          ThumbnailFileLruCache.put(file, data);
          return data;
        });
      }
      return thumbnailDownloadsInProgress[file.uploadedFileID];
    } else {
      ThumbnailFileLruCache.put(file, info.file);
      return info.file;
    }
  });
}

Future<io.File> _downloadAndDecrypt(File file, BaseCacheManager cacheManager,
    {ProgressCallback progressCallback}) async {
  _logger.info("Downloading file " + file.uploadedFileID.toString());
  final encryptedFilePath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      ".encrypted";
  final decryptedFilePath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      ".decrypted";

  final encryptedFile = io.File(encryptedFilePath);
  final decryptedFile = io.File(decryptedFilePath);
  final startTime = DateTime.now().millisecondsSinceEpoch;
  return Network.instance
      .getDio()
      .download(
        file.getDownloadUrl(),
        encryptedFilePath,
        options: Options(
          headers: {"X-Auth-Token": Configuration.instance.getToken()},
        ),
        onReceiveProgress: progressCallback,
      )
      .then((response) async {
    if (response.statusCode != 200) {
      _logger.warning("Could not download file: ", response.toString());
      return null;
    } else if (!encryptedFile.existsSync()) {
      _logger.warning("File was not downloaded correctly.");
      return null;
    }
    _logger.info("File downloaded: " + file.uploadedFileID.toString());
    _logger.info("Download speed: " +
        (io.File(encryptedFilePath).lengthSync() /
                (DateTime.now().millisecondsSinceEpoch - startTime))
            .toString() +
        "kBps");
    await CryptoUtil.decryptFile(encryptedFilePath, decryptedFilePath,
        Sodium.base642bin(file.fileDecryptionHeader), decryptFileKey(file));
    _logger.info("File decrypted: " + file.uploadedFileID.toString());
    encryptedFile.deleteSync();
    var fileExtension = extension(file.title).substring(1).toLowerCase();
    var outputFile = decryptedFile;
    if (Platform.isAndroid && fileExtension == "heic") {
      outputFile = await FlutterImageCompress.compressAndGetFile(
        decryptedFilePath,
        decryptedFilePath + ".jpg",
        keepExif: true,
      );
      decryptedFile.deleteSync();
    }
    final cachedFile = await cacheManager.putFile(
      file.getDownloadUrl(),
      outputFile.readAsBytesSync(),
      eTag: file.getDownloadUrl(),
      maxAge: Duration(days: 365),
      fileExtension: fileExtension,
    );
    outputFile.deleteSync();
    fileDownloadsInProgress.remove(file.uploadedFileID);
    return cachedFile;
  }).catchError((e) {
    fileDownloadsInProgress.remove(file.uploadedFileID);
  });
}

Future<io.File> _downloadAndDecryptThumbnail(File file) async {
  final temporaryPath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      "_thumbnail.decrypted";
  return Network.instance
      .getDio()
      .download(
        file.getThumbnailUrl(),
        temporaryPath,
        options: Options(
          headers: {"X-Auth-Token": Configuration.instance.getToken()},
        ),
      )
      .then((_) async {
    final encryptedFile = io.File(temporaryPath);
    final thumbnailDecryptionKey = decryptFileKey(file);
    var data = CryptoUtil.decryptChaCha(
      encryptedFile.readAsBytesSync(),
      thumbnailDecryptionKey,
      Sodium.base642bin(file.thumbnailDecryptionHeader),
    );
    final thumbnailSize = data.length;
    if (thumbnailSize > THUMBNAIL_DATA_LIMIT) {
      data = await compressThumbnail(data);
      _logger.info("Compressed thumbnail from " +
          thumbnailSize.toString() +
          " to " +
          data.length.toString());
    }
    encryptedFile.deleteSync();
    final cachedThumbnail = ThumbnailCacheManager().putFile(
      file.getThumbnailUrl(),
      data,
      eTag: file.getThumbnailUrl(),
      maxAge: Duration(days: 365),
    );
    thumbnailDownloadsInProgress.remove(file.uploadedFileID);
    return cachedThumbnail;
  }).catchError((e, s) {
    _logger.severe("Error downloading thumbnail ", e, s);
    thumbnailDownloadsInProgress.remove(file.uploadedFileID);
  });
}

Uint8List decryptFileKey(File file) {
  final encryptedKey = Sodium.base642bin(file.encryptedKey);
  final nonce = Sodium.base642bin(file.keyDecryptionNonce);
  final collectionKey =
      CollectionsService.instance.getCollectionKey(file.collectionID);
  return CryptoUtil.decryptSync(encryptedKey, collectionKey, nonce);
}

Future<Uint8List> compressThumbnail(Uint8List thumbnail) {
  return FlutterImageCompress.compressWithList(
    thumbnail,
    minHeight: COMPRESSED_THUMBNAIL_RESOLUTION,
    minWidth: COMPRESSED_THUMBNAIL_RESOLUTION,
    quality: 25,
  );
}
