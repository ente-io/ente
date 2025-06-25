import 'dart:async';
import 'dart:io';

import 'package:archive/archive.dart';
import "package:dio/dio.dart";
import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:logging/logging.dart';
import 'package:motionphoto/motionphoto.dart';
import 'package:path/path.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/cache/video_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:photos/utils/thumbnail_util.dart';

final _logger = Logger("FileUtil");

void preloadFile(EnteFile file) {
  if (file.fileType == FileType.video) {
    return;
  }
  getFile(file);
}

// IMPORTANT: Delete the returned file if `isOrigin` is set to true
// https://github.com/CaiJingLong/flutter_photo_manager#cache-problem-of-ios
Future<File?> getFile(
  EnteFile file, {
  bool liveVideo = false,
  bool isOrigin = false,
} // only relevant for live photos
    ) async {
  try {
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
        if (!(isOrigin && Platform.isIOS) && diskFile != null) {
          FileLruCache.put(key, diskFile);
        }
        return diskFile;
      }
      return cachedFile;
    }
  } catch (e, s) {
    _logger.warning("Failed to get file", e, s);
    return null;
  }
}

Future<bool> doesLocalFileExist(EnteFile file) async {
  return await _getLocalDiskFile(file) != null;
}

Future<File?> _getLocalDiskFile(
  EnteFile file, {
  bool liveVideo = false,
  bool isOrigin = false,
}) {
  if (file.isSharedMediaToAppSandbox) {
    final localFile = File(getSharedMediaFilePath(file));
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

String getSharedMediaFilePath(EnteFile file) {
  return getSharedMediaPathFromLocalID(file.localID!);
}

String getSharedMediaPathFromLocalID(String localID) {
  return Configuration.instance.getSharedMediaDirectory() +
      "/" +
      localID.replaceAll(sharedMediaIdentifier, '');
}

void preloadThumbnail(EnteFile file) {
  if (file.isRemoteFile) {
    getThumbnailFromServer(file);
  } else {
    getThumbnailFromLocal(file);
  }
}

final Map<String, Future<File?>> _fileDownloadsInProgress =
    <String, Future<File?>>{};
Map<String, ProgressCallback?> _progressCallbacks = {};

void removeCallBack(EnteFile file) {
  if (!file.isUploaded) {
    return;
  }
  String id = file.uploadedFileID.toString() + false.toString();
  _progressCallbacks.remove(id);
  if (file.isLivePhoto) {
    id = file.uploadedFileID.toString() + true.toString();
    _progressCallbacks.remove(id);
  }
}

Future<File?> getFileFromServer(
  EnteFile file, {
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

  if (progressCallback != null) {
    _progressCallbacks[downloadID] = progressCallback;
  }

  if (!_fileDownloadsInProgress.containsKey(downloadID)) {
    final completer = Completer<File?>();
    _fileDownloadsInProgress[downloadID] = completer.future;

    Future<File?> downloadFuture;
    if (file.fileType == FileType.livePhoto) {
      downloadFuture = _getLivePhotoFromServer(
        file,
        progressCallback: (count, total) {
          _progressCallbacks[downloadID]?.call(count, total);
        },
        needLiveVideo: liveVideo,
      );
    } else {
      downloadFuture = _downloadAndCache(
        file,
        cacheManager,
        progressCallback: (count, total) {
          _progressCallbacks[downloadID]?.call(count, total);
        },
      );
    }
    // ignore: unawaited_futures
    downloadFuture.then((downloadedFile) async {
      completer.complete(downloadedFile);
      await _fileDownloadsInProgress.remove(downloadID);
      _progressCallbacks.remove(downloadID);
    });
  }
  return _fileDownloadsInProgress[downloadID];
}

Future<bool> isFileCached(EnteFile file, {bool liveVideo = false}) async {
  final cacheManager = (file.fileType == FileType.video || liveVideo)
      ? VideoCacheManager.instance
      : DefaultCacheManager();
  final fileInfo = await cacheManager.getFileFromCache(file.downloadUrl);
  return fileInfo != null;
}

final Map<int, Future<_LivePhoto?>> _livePhotoDownloadsTracker =
    <int, Future<_LivePhoto?>>{};

Future<File?> _getLivePhotoFromServer(
  EnteFile file, {
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
    await _livePhotoDownloadsTracker.remove(downloadID);
    if (livePhoto == null) {
      return null;
    }
    return needLiveVideo ? livePhoto.video : livePhoto.image;
  } catch (e, s) {
    _logger.warning("live photo get failed", e, s);
    await _livePhotoDownloadsTracker.remove(downloadID);
    return null;
  }
}

Future<_LivePhoto?> _downloadLivePhoto(
  EnteFile file, {
  ProgressCallback? progressCallback,
}) async {
  return downloadAndDecrypt(file, progressCallback: progressCallback)
      .then((decryptedFile) async {
    if (decryptedFile == null) {
      return null;
    }
    _logger.info("Decoded zipped live photo from " + decryptedFile.path);
    File? imageFileCache, videoFileCache;
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
          final imageFile = File(decodePath);
          await imageFile.create(recursive: true);
          await imageFile.writeAsBytes(data);
          File imageConvertedFile = imageFile;
          if ((fileExtension == "unknown") ||
              (Platform.isAndroid && fileExtension == "heic")) {
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
              imageConvertedFile = File(compressResult.path);
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
          final videoFile = File(decodePath);
          await videoFile.create(recursive: true);
          await videoFile.writeAsBytes(data);
          videoFileCache = await VideoCacheManager.instance.putFileStream(
            file.downloadUrl,
            videoFile.openRead(),
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
      debugPrint(
        "Warning: ${file.tag} either image ${imageFileCache == null} or video ${videoFileCache == null} is missing from remoteLive",
      );
      return null;
    }
  }).catchError((e) {
    _logger.warning("failed to download live photos : ${file.tag}", e);
    throw e;
  });
}

Future<File?> _downloadAndCache(
  EnteFile file,
  BaseCacheManager cacheManager, {
  required ProgressCallback progressCallback,
}) async {
  return downloadAndDecrypt(file, progressCallback: progressCallback)
      .then((decryptedFile) async {
    if (decryptedFile == null) {
      return null;
    }
    final decryptedFilePath = decryptedFile.path;
    final String fileExtension = getExtension(file.title ?? '');
    File outputFile = decryptedFile;
    if ((fileExtension == "unknown" && file.fileType == FileType.image)) {
      final compressResult = await FlutterImageCompress.compressAndGetFile(
        decryptedFilePath,
        decryptedFilePath + ".jpg",
        keepExif: true,
      );
      if (compressResult == null) {
        throw Exception("Failed to convert heic to jpg");
      } else {
        outputFile = File(compressResult.path);
      }
      await decryptedFile.delete();
    }
    final cachedFile = await cacheManager.putFileStream(
      file.downloadUrl,
      outputFile.openRead(),
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

Future<void> clearCache(EnteFile file) async {
  if (file.fileType == FileType.video) {
    await VideoCacheManager.instance.removeFile(file.downloadUrl);
  } else {
    await DefaultCacheManager().removeFile(file.downloadUrl);
  }
  final cachedThumbnail = File(
    Configuration.instance.getThumbnailCacheDirectory() +
        "/" +
        file.uploadedFileID.toString(),
  );
  if (cachedThumbnail.existsSync()) {
    await cachedThumbnail.delete();
  }
  ThumbnailInMemoryLruCache.clearCache(file);
}

class _LivePhoto {
  final File image;
  final File video;

  _LivePhoto(this.image, this.video);
}

Set<int> filesToUploadedFileIDs(List<EnteFile> files) {
  final uploadedFileIDs = <int>{};
  for (final file in files) {
    if (file.isUploaded) {
      uploadedFileIDs.add(file.uploadedFileID!);
    }
  }
  return uploadedFileIDs;
}
