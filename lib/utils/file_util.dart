import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:motionphoto/motionphoto.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:path/path.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart' as ente;
import 'package:photos/models/file_type.dart';
import 'package:photos/utils/thumbnail_util.dart';
import 'package:photos/utils/file_download_util.dart';

final _logger = Logger("FileUtil");

void preloadFile(ente.File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  getFile(file);
}

Future<io.File> getFile(ente.File file) async {
  if (file.isRemoteFile()) {
    return getFileFromServer(file);
  } else {
    final cachedFile = FileLruCache.get(file);
    if (cachedFile == null) {
      final diskFile = await _getLocalDiskFile(file);
      FileLruCache.put(file, diskFile);
      return diskFile;
    }
    return cachedFile;
  }
}

Future<io.File> getLiveVideo(ente.File file) async {
  return Motionphoto.getLivePhotoFile(file.localID);
}

Future<io.File> _getLocalDiskFile(ente.File file) async {
  if (file.isSharedMediaToAppSandbox()) {
    var localFile = io.File(getSharedMediaFilePath(file));
    return localFile.exists().then((exist) {
      return exist ? localFile : null;
    });
  } else {
    return file.getAsset().then((asset) async {
      if (asset == null || !(await asset.exists)) {
        return null;
      }
      return asset.file;
    });
  }
}

String getSharedMediaFilePath(ente.File file) {
  return Configuration.instance.getSharedMediaCacheDirectory() +
      "/" +
      file.localID.replaceAll(kSharedMediaIdentifier, '');
}

void preloadThumbnail(ente.File file) {
  if (file.isRemoteFile()) {
    getThumbnailFromServer(file);
  } else {
    getThumbnailFromLocal(file);
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
        fileDownloadsInProgress[file.uploadedFileID] = _downloadAndCache(
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

Future<io.File> _downloadAndCache(ente.File file, BaseCacheManager cacheManager,
    {ProgressCallback progressCallback}) async {
  return downloadAndDecrypt(file, progressCallback: progressCallback)
      .then((decryptedFile) async {
    if (decryptedFile == null) {
      return null;
    }
    var decryptedFilePath = decryptedFile.path;
    var fileExtension = "unknown";
    try {
      fileExtension = extension(file.title).substring(1).toLowerCase();
    } catch (e) {
      _logger.severe("Could not capture file extension");
    }
    var outputFile = decryptedFile;
    if ((fileExtension == "unknown" && file.fileType == FileType.image) ||
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

Future<Uint8List> compressThumbnail(Uint8List thumbnail) {
  return FlutterImageCompress.compressWithList(
    thumbnail,
    minHeight: kCompressedThumbnailResolution,
    minWidth: kCompressedThumbnailResolution,
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
