import 'dart:async';
import 'dart:io' as io;
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:motionphoto/motionphoto.dart';
import 'package:path/path.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file.dart' as ente;
import 'package:photos/models/file_type.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

final _logger = Logger("FileUtil");

void preloadFile(ente.File file) {
  if (file.fileType == FileType.video) {
    return;
  }
  getFile(file);
}

// IMPORTANT: Delete the returned file if `isOrigin` is set to true
// https://github.com/CaiJingLong/flutter_photo_manager#cache-problem-of-ios
Future<io.File?> getFile(
  ente.File file, {
  bool liveVideo = false,
  bool isOrigin = false,
} // only relevant for live photos
    ) async {
  if (file.isRemoteFile) {
    return getFileFromServer(file, liveVideo: liveVideo);
  } else {
    final String key = file.tag + liveVideo.toString() + isOrigin.toString();
    final cachedFile = FileLruCache.get(key);
    if (cachedFile == null) {
      final diskFile = await _getLocalDiskFile(
        file,
        liveVideo: liveVideo,
        isOrigin: isOrigin,
      );
      // do not cache origin file for IOS as they are immediately deleted
      // after usage
      if (!(isOrigin && Platform.isIOS && diskFile != null)) {
        FileLruCache.put(key, diskFile!);
      }
      return diskFile;
    }
    return cachedFile;
  }
}

Future<bool> doesLocalFileExist(ente.File file) async {
  return await _getLocalDiskFile(file) != null;
}

Future<io.File?> _getLocalDiskFile(
  ente.File file, {
  bool liveVideo = false,
  bool isOrigin = false,
}) async {
  if (file.isSharedMediaToAppSandbox) {
    final localFile = io.File(getSharedMediaFilePath(file));
    return localFile.exists().then((exist) {
      return exist ? localFile : null;
    });
  } else if (file.fileType == FileType.livePhoto && liveVideo) {
    return Motionphoto.getLivePhotoFile(file.localID!);
  } else {
    return file.getAsset.then((asset) async {
      if (asset == null || !(await asset.exists)) {
        return null;
      }
      return isOrigin ? asset.originFile : asset.file;
    });
  }
}

String getSharedMediaFilePath(ente.File file) {
  return getSharedMediaPathFromLocalID(file.localID!);
}

String getSharedMediaPathFromLocalID(String localID) {
  if (localID.startsWith(oldSharedMediaIdentifier)) {
    return Configuration.instance.getOldSharedMediaCacheDirectory() +
        "/" +
        localID.replaceAll(oldSharedMediaIdentifier, '');
  } else {
    return Configuration.instance.getSharedMediaDirectory() +
        "/" +
        localID.replaceAll(sharedMediaIdentifier, '');
  }
}

void preloadThumbnail(ente.File file) {
  if (file.isRemoteFile) {
    getThumbnailFromServer(file);
  } else {
    getThumbnailFromLocal(file);
  }
}

final Map<String, Future<io.File?>> fileDownloadsInProgress =
    <String, Future<io.File>>{};

Future<io.File?> getFileFromServer(
  ente.File file, {
  ProgressCallback? progressCallback,
  bool liveVideo = false, // only needed in case of live photos
}) async {
  final cacheManager = (file.fileType == FileType.video || liveVideo)
      ? VideoCacheManager.instance
      : DefaultCacheManager();
  final fileFromCache = await cacheManager.getFileFromCache(file.downloadUrl);
  if (fileFromCache != null) {
    return fileFromCache.file;
  }
  final downloadID = file.uploadedFileID.toString() + liveVideo.toString();
  if (!fileDownloadsInProgress.containsKey(downloadID)) {
    if (file.fileType == FileType.livePhoto) {
      fileDownloadsInProgress[downloadID] = _getLivePhotoFromServer(
        file,
        progressCallback: progressCallback,
        needLiveVideo: liveVideo,
      ).whenComplete(() {
        fileDownloadsInProgress.remove(downloadID);
      });
    } else {
      fileDownloadsInProgress[downloadID] = _downloadAndCache(
        file,
        cacheManager,
        progressCallback: progressCallback,
      ).whenComplete(() {
        fileDownloadsInProgress.remove(downloadID);
      });
    }
  }
  return fileDownloadsInProgress[downloadID];
}

Future<bool> isFileCached(ente.File file, {bool liveVideo = false}) async {
  final cacheManager = (file.fileType == FileType.video || liveVideo)
      ? VideoCacheManager.instance
      : DefaultCacheManager();
  final fileInfo = await cacheManager.getFileFromCache(file.downloadUrl);
  return fileInfo != null;
}

final Map<int, Future<_LivePhoto?>> _livePhotoDownloadsTracker =
    <int, Future<_LivePhoto?>>{};

Future<io.File?> _getLivePhotoFromServer(
  ente.File file, {
  ProgressCallback? progressCallback,
  required bool needLiveVideo,
}) async {
  final downloadID = file.uploadedFileID!;
  try {
    if (!_livePhotoDownloadsTracker.containsKey(downloadID)) {
      _livePhotoDownloadsTracker[downloadID] =
          _downloadLivePhoto(file, progressCallback: progressCallback);
    }
    final livePhoto = await _livePhotoDownloadsTracker[file.uploadedFileID];
    _livePhotoDownloadsTracker.remove(downloadID);
    if (livePhoto == null) {
      return null;
    }
    return needLiveVideo ? livePhoto.video : livePhoto.image;
  } catch (e, s) {
    _logger.warning("live photo get failed", e, s);
    _livePhotoDownloadsTracker.remove(downloadID);
    return null;
  }
}

Future<_LivePhoto?> _downloadLivePhoto(
  ente.File file, {
  ProgressCallback? progressCallback,
}) async {
  return downloadAndDecrypt(file, progressCallback: progressCallback)
      .then((decryptedFile) async {
    if (decryptedFile == null) {
      return null;
    }
    _logger.fine("Decoded zipped live photo from " + decryptedFile.path);
    io.File? imageFileCache, videoFileCache;
    final List<int> bytes = await decryptedFile.readAsBytes();
    final Archive archive = ZipDecoder().decodeBytes(bytes);
    final tempPath = Configuration.instance.getTempDirectory();
    // Extract the contents of Zip compressed archive to disk
    for (ArchiveFile archiveFile in archive) {
      if (archiveFile.isFile) {
        final String filename = archiveFile.name;
        final String fileExtension = getExtension(archiveFile.name);
        final String decodePath =
            tempPath + file.uploadedFileID.toString() + filename;
        final List<int> data = archiveFile.content;
        if (filename.startsWith("image")) {
          final imageFile = io.File(decodePath);
          await imageFile.create(recursive: true);
          await imageFile.writeAsBytes(data);
          io.File imageConvertedFile = imageFile;
          if ((fileExtension == "unknown") ||
              (io.Platform.isAndroid && fileExtension == "heic")) {
            final compressResult =
                await FlutterImageCompress.compressAndGetFile(
              decodePath,
              decodePath + ".jpg",
              keepExif: true,
            );
            await imageFile.delete();
            if (compressResult == null) {
              throw Exception("Failed to compress file");
            } else {
              imageConvertedFile = compressResult;
            }
          }
          imageFileCache = await DefaultCacheManager().putFile(
            file.downloadUrl,
            await imageConvertedFile.readAsBytes(),
            eTag: file.downloadUrl,
            maxAge: const Duration(days: 365),
            fileExtension: fileExtension,
          );
          await imageConvertedFile.delete();
        } else if (filename.startsWith("video")) {
          final videoFile = io.File(decodePath);
          await videoFile.create(recursive: true);
          await videoFile.writeAsBytes(data);
          videoFileCache = await VideoCacheManager.instance.putFile(
            file.downloadUrl,
            await videoFile.readAsBytes(),
            eTag: file.downloadUrl,
            maxAge: const Duration(days: 365),
            fileExtension: fileExtension,
          );
          await videoFile.delete();
        }
      }
    }
    if (imageFileCache != null && videoFileCache != null) {
      return _LivePhoto(imageFileCache, videoFileCache);
    } else {
      debugPrint("Warning: Either image or video is missing from remoteLive");
      return null;
    }
  }).catchError((e) {
    _logger.warning("failed to download live photos : ${file.tag}", e);
    throw e;
  });
}

Future<io.File?> _downloadAndCache(
  ente.File file,
  BaseCacheManager cacheManager, {
  ProgressCallback? progressCallback,
}) async {
  return downloadAndDecrypt(file, progressCallback: progressCallback)
      .then((decryptedFile) async {
    if (decryptedFile == null) {
      return null;
    }
    final decryptedFilePath = decryptedFile.path;
    final String fileExtension = getExtension(file.title ?? '');
    io.File outputFile = decryptedFile;
    if ((fileExtension == "unknown" && file.fileType == FileType.image) ||
        (io.Platform.isAndroid && fileExtension == "heic")) {
      final compressResult = await FlutterImageCompress.compressAndGetFile(
        decryptedFilePath,
        decryptedFilePath + ".jpg",
        keepExif: true,
      );
      if (compressResult == null) {
        throw Exception("Failed to convert heic to jpg");
      } else {
        outputFile = compressResult;
      }
      await decryptedFile.delete();
    }
    final cachedFile = await cacheManager.putFile(
      file.downloadUrl,
      await outputFile.readAsBytes(),
      eTag: file.downloadUrl,
      maxAge: const Duration(days: 365),
      fileExtension: fileExtension,
    );
    await outputFile.delete();
    return cachedFile;
  }).catchError((e) {
    _logger.warning("failed to download file : ${file.tag}", e);
    throw e;
  });
}

String getExtension(String nameOrPath) {
  var fileExtension = "unknown";
  try {
    fileExtension = extension(nameOrPath).substring(1).toLowerCase();
  } catch (e) {
    _logger.severe("Could not capture file extension");
  }
  return fileExtension;
}

Future<Uint8List> compressThumbnail(Uint8List thumbnail) {
  return FlutterImageCompress.compressWithList(
    thumbnail,
    minHeight: compressedThumbnailResolution,
    minWidth: compressedThumbnailResolution,
    quality: 25,
  );
}

Future<void> clearCache(ente.File file) async {
  if (file.fileType == FileType.video) {
    VideoCacheManager.instance.removeFile(file.downloadUrl);
  } else {
    DefaultCacheManager().removeFile(file.downloadUrl);
  }
  final cachedThumbnail = io.File(
    Configuration.instance.getThumbnailCacheDirectory() +
        "/" +
        file.uploadedFileID.toString(),
  );
  if (cachedThumbnail.existsSync()) {
    await cachedThumbnail.delete();
  }
  ThumbnailLruCache.clearCache(file);
}

class _LivePhoto {
  final io.File image;
  final io.File video;

  _LivePhoto(this.image, this.video);
}
