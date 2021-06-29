import 'dart:async';
import 'dart:io' as io;
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
import 'package:photos/models/file.dart' as ente;
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/thumbnail_util.dart';

import 'crypto_util.dart';

final _logger = Logger("FileUtil");

void preloadFile(ente.File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  getFile(file);
}

Future<io.File> getFile(ente.File file) async {
  if (file.localID == null) {
    return getFileFromServer(file);
  } else {
    final cachedFile = FileLruCache.get(file);
    if (cachedFile == null) {
      final diskFile = await (await file.getAsset()).file;
      FileLruCache.put(file, diskFile);
      return diskFile;
    }
    return cachedFile;
  }
}

void preloadThumbnail(ente.File file) {
  if (file.localID == null) {
    getThumbnailFromServer(file);
  } else {
    if (ThumbnailLruCache.get(file, THUMBNAIL_SMALL_SIZE) != null) {
      return;
    }
    file.getAsset().then((asset) {
      if (asset != null) {
        asset
            .thumbDataWithSize(
          THUMBNAIL_SMALL_SIZE,
          THUMBNAIL_SMALL_SIZE,
          quality: THUMBNAIL_QUALITY,
        )
            .then((data) {
          ThumbnailLruCache.put(file, data, THUMBNAIL_SMALL_SIZE);
        });
      }
    });
  }
}

Future<Uint8List> getBytes(ente.File file, {int quality = 100}) async {
  if (file.localID == null) {
    return getFileFromServer(file).then((file) => file.readAsBytesSync());
  } else {
    return await getBytesFromDisk(file, quality: quality);
  }
}

Future<Uint8List> getBytesFromDisk(ente.File file, {int quality = 100}) async {
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

Future<io.File> getFileFromServer(ente.File file,
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

Future<io.File> _downloadAndDecrypt(
    ente.File file, BaseCacheManager cacheManager,
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
    var fileExtension = "unknown";
    try {
      fileExtension = extension(file.title).substring(1).toLowerCase();
    } catch(e) {
      _logger.severe("Could not capture file extension");
    }
    var outputFile = decryptedFile;
    if ((fileExtension=="unknown" && file.fileType == FileType.image) || 
        (io.Platform.isAndroid && fileExtension == "heic")) {
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

Uint8List decryptFileKey(ente.File file) {
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

void clearCache(ente.File file) {
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
