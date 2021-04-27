import 'dart:async';
import 'dart:collection';
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
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/toast_util.dart';

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
  var deletedIDs;
  try {
    deletedIDs = (await PhotoManager.editor.deleteWithIds(localIDs)).toSet();
  } catch (e, s) {
    _logger.severe("Could not delete file", e, s);
  }
  final updatedCollectionIDs = Set<int>();
  final List<int> uploadedFileIDsToBeDeleted = [];
  final List<File> deletedFiles = [];
  for (final file in files) {
    if (file.localID != null) {
      // Remove only those files that have been removed from disk
      if (deletedIDs.contains(file.localID)) {
        deletedFiles.add(file);
        if (file.uploadedFileID != null) {
          uploadedFileIDsToBeDeleted.add(file.uploadedFileID);
          updatedCollectionIDs.add(file.collectionID);
        } else {
          await FilesDB.instance.deleteLocalFile(file.localID);
        }
      }
    } else {
      uploadedFileIDsToBeDeleted.add(file.uploadedFileID);
    }
  }
  if (uploadedFileIDsToBeDeleted.isNotEmpty) {
    try {
      await SyncService.instance
          .deleteFilesOnServer(uploadedFileIDsToBeDeleted);
      await FilesDB.instance
          .deleteMultipleUploadedFiles(uploadedFileIDsToBeDeleted);
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
      throw e;
    }
    for (final collectionID in updatedCollectionIDs) {
      Bus.instance.fire(CollectionUpdatedEvent(
          collectionID,
          deletedFiles
              .where((file) => file.collectionID == collectionID)
              .toList()));
    }
  }
  if (deletedFiles.isNotEmpty) {
    Bus.instance.fire(LocalPhotosUpdatedEvent(deletedFiles));
  }
  await dialog.hide();
  showToast("deleted from everywhere");
  if (uploadedFileIDsToBeDeleted.isNotEmpty) {
    SyncService.instance.syncWithRemote(silently: true);
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
  final List<File> deletedFiles = [];
  for (final file in files) {
    // Remove only those files that have been removed from disk
    if (deletedIDs.contains(file.localID)) {
      deletedFiles.add(file);
      file.localID = null;
      FilesDB.instance.update(file);
    }
  }
  if (deletedFiles.isNotEmpty) {
    Bus.instance.fire(LocalPhotosUpdatedEvent(deletedFiles));
  }
  await dialog.hide();
}

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
        ThumbnailLruCache.put(file, THUMBNAIL_SMALL_SIZE, data);
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

final _thumbnailQueue = LinkedHashMap<int, FileDownloadItem>();
int _currentlyDownloading = 0;
const int kMaximumConcurrentDownloads = 500;

class FileDownloadItem {
  final File file;
  final Completer<io.File> completer;
  DownloadStatus status;

  FileDownloadItem(
    this.file,
    this.completer, {
    this.status = DownloadStatus.not_started,
  });
}

enum DownloadStatus {
  not_started,
  in_progress,
}

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
      if (!_thumbnailQueue.containsKey(file.uploadedFileID)) {
        final completer = Completer<io.File>();
        _thumbnailQueue[file.uploadedFileID] =
            FileDownloadItem(file, completer);
        _pollQueue();
        return completer.future;
      } else {
        return _thumbnailQueue[file.uploadedFileID].completer.future;
      }
    } else {
      ThumbnailFileLruCache.put(file, info.file);
      return info.file;
    }
  });
}

void removePendingGetThumbnailRequestIfAny(File file) {
  if (_thumbnailQueue[file.uploadedFileID] != null &&
      _thumbnailQueue[file.uploadedFileID].status ==
          DownloadStatus.not_started) {
    _thumbnailQueue.remove(file.uploadedFileID);
  }
}

void _pollQueue() async {
  if (_thumbnailQueue.length > 0 &&
      _currentlyDownloading < kMaximumConcurrentDownloads) {
    final firstPendingEntry = _thumbnailQueue.entries.firstWhere(
        (entry) => entry.value.status == DownloadStatus.not_started,
        orElse: () => null);
    if (firstPendingEntry != null) {
      final item = firstPendingEntry.value;
      _currentlyDownloading++;
      item.status = DownloadStatus.in_progress;
      try {
        final data = await _downloadAndDecryptThumbnail(item.file);
        ThumbnailFileLruCache.put(item.file, data);
        item.completer.complete(data);
      } catch (e, s) {
        _logger.severe(
            "Failed to download thumbnail " + item.file.toString(), e, s);
        item.completer.completeError(e);
      }
      _currentlyDownloading--;
      _thumbnailQueue.remove(firstPendingEntry.key);
      _pollQueue();
    }
  }
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
  await Network.instance.getDio().download(
        file.getThumbnailUrl(),
        temporaryPath,
        options: Options(
          headers: {"X-Auth-Token": Configuration.instance.getToken()},
        ),
      );
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
  return cachedThumbnail;
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
    VideoCacheManager().removeFile(file.getDownloadUrl());
  } else {
    DefaultCacheManager().removeFile(file.getDownloadUrl());
  }
  ThumbnailCacheManager().removeFile(file.getThumbnailUrl());
}
