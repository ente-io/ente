import 'dart:io' as io;
import 'dart:typed_data';

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
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';

import 'crypto_util.dart';

final logger = Logger("FileUtil");

Future<void> deleteFiles(List<File> files,
    {bool deleteEveryWhere = false}) async {
  await PhotoManager.editor
      .deleteWithIds(files.map((file) => file.localID).toList());
  for (File file in files) {
    deleteEveryWhere
        ? await FilesDB.instance.markForDeletion(file)
        : await FilesDB.instance.delete(file);
  }
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
        .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
        .then((data) {
      ThumbnailLruCache.put(file, THUMBNAIL_SMALL_SIZE, data);
    });
  });
}

Future<io.File> getNativeFile(File file) async {
  if (file.localID == null) {
    return getFileFromServer(file);
  } else {
    return file.getAsset().then((asset) => asset.file);
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

final Map<int, Future<io.File>> downloadsInProgress =
    Map<int, Future<io.File>>();

Future<io.File> getFileFromServer(File file,
    {ProgressCallback progressCallback}) async {
  final cacheManager = file.fileType == FileType.video
      ? VideoCacheManager()
      : DefaultCacheManager();
  if (!file.isEncrypted) {
    return cacheManager.getSingleFile(file.getDownloadUrl());
  } else {
    return cacheManager.getFileFromCache(file.getDownloadUrl()).then((info) {
      if (info == null) {
        if (!downloadsInProgress.containsKey(file.uploadedFileID)) {
          downloadsInProgress[file.uploadedFileID] = _downloadAndDecrypt(
            file,
            cacheManager,
            progressCallback: progressCallback,
          );
        }
        return downloadsInProgress[file.uploadedFileID];
      } else {
        return info.file;
      }
    });
  }
}

Future<io.File> getThumbnailFromServer(File file) async {
  if (!file.isEncrypted) {
    return ThumbnailCacheManager()
        .getSingleFile(file.getThumbnailUrl())
        .then((data) {
      ThumbnailFileLruCache.put(file, data);
      return data;
    });
  } else {
    return ThumbnailCacheManager()
        .getFileFromCache(file.getThumbnailUrl())
        .then((info) {
      if (info == null) {
        return _downloadAndDecryptThumbnail(file).then((data) {
          ThumbnailFileLruCache.put(file, data);
          return data;
        });
      } else {
        ThumbnailFileLruCache.put(file, info.file);
        return info.file;
      }
    });
  }
}

Future<io.File> _downloadAndDecrypt(File file, BaseCacheManager cacheManager,
    {ProgressCallback progressCallback}) async {
  logger.info("Downloading file " + file.uploadedFileID.toString());
  final encryptedFilePath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      ".encrypted";
  final decryptedFilePath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      ".decrypted";

  final encryptedFile = io.File(encryptedFilePath);
  final decryptedFile = io.File(decryptedFilePath);
  return Dio()
      .download(
    file.getDownloadUrl(),
    encryptedFilePath,
    onReceiveProgress: progressCallback,
  )
      .then((response) async {
    if (response.statusCode != 200) {
      logger.warning("Could not download file: ", response.toString());
      return null;
    } else if (!encryptedFile.existsSync()) {
      logger.warning("File was not downloaded correctly.");
      return null;
    }
    logger.info("File downloaded: " + file.uploadedFileID.toString());
    await CryptoUtil.decryptFile(encryptedFilePath, decryptedFilePath,
        Sodium.base642bin(file.fileDecryptionHeader), decryptFileKey(file));
    logger.info("File decrypted: " + file.uploadedFileID.toString());
    io.File(encryptedFilePath).deleteSync();
    final fileExtension = extension(file.title).substring(1).toLowerCase();
    final cachedFile = await cacheManager.putFile(
      file.getDownloadUrl(),
      decryptedFile.readAsBytesSync(),
      eTag: file.getDownloadUrl(),
      maxAge: Duration(days: 365),
      fileExtension: fileExtension,
    );
    decryptedFile.deleteSync();
    downloadsInProgress.remove(file.uploadedFileID);
    return cachedFile;
  }).catchError((e) {
    downloadsInProgress.remove(file.uploadedFileID);
  });
}

Future<io.File> _downloadAndDecryptThumbnail(File file) async {
  final temporaryPath = Configuration.instance.getTempDirectory() +
      file.generatedID.toString() +
      "_thumbnail.decrypted";
  return Dio().download(file.getThumbnailUrl(), temporaryPath).then((_) async {
    final encryptedFile = io.File(temporaryPath);
    final thumbnailDecryptionKey = decryptFileKey(file);
    final data = CryptoUtil.decryptChaCha(
      encryptedFile.readAsBytesSync(),
      thumbnailDecryptionKey,
      Sodium.base642bin(file.thumbnailDecryptionHeader),
    );
    encryptedFile.deleteSync();
    return ThumbnailCacheManager().putFile(
      file.getThumbnailUrl(),
      data,
      eTag: file.getThumbnailUrl(),
      maxAge: Duration(days: 365),
    );
  });
}

Uint8List decryptFileKey(File file) {
  final encryptedKey = Sodium.base642bin(file.encryptedKey);
  final nonce = Sodium.base642bin(file.keyDecryptionNonce);
  if (file.ownerID == Configuration.instance.getUserID()) {
    return CryptoUtil.decryptSync(
        encryptedKey, Configuration.instance.getKey(), nonce);
  } else {
    final collectionKey =
        CollectionsService.instance.getCollectionKey(file.collectionID);
    return CryptoUtil.decryptSync(encryptedKey, collectionKey, nonce);
  }
}
