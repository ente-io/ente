import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/thumbnail_util.dart';

import 'crypto_util.dart';

final _logger = Logger("FileUtil");

void preloadFile(File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  if (file.localID == null) {
    getFileFromServer(file);
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

void preloadThumbnail(File file) {
  if (file.localID == null) {
    getThumbnailFromServer(file);
  } else {
    if (ThumbnailLruCache.get(file, THUMBNAIL_SMALL_SIZE) != null) {
      return;
    }
    file.getAsset().then((asset) {
      asset
          .thumbDataWithSize(
        THUMBNAIL_SMALL_SIZE,
        THUMBNAIL_SMALL_SIZE,
        quality: THUMBNAIL_QUALITY,
      )
          .then((data) {
        ThumbnailLruCache.put(file, data, THUMBNAIL_SMALL_SIZE);
      });
    });
  }
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

Future<io.File> getFileFromServer(File file,
    {ProgressCallback progressCallback}) async {
  final cacheManager = file.fileType == FileType.video
      ? VideoCacheManager.instance
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

void clearCache(File file) {
  if (file.fileType == FileType.video) {
    VideoCacheManager.instance.removeFile(file.getDownloadUrl());
  } else {
    DefaultCacheManager().removeFile(file.getDownloadUrl());
  }
  final cachedThumbnail = io.File(
      Configuration.instance.getThumbnailCacheDirectory() +
          "/" +
          file.uploadedFileID.toString());
  if (cachedThumbnail.existsSync()) {
    cachedThumbnail.deleteSync();
  }
}
