import 'dart:async';
import 'dart:collection';

import 'dart:io' as io;

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/image_cache.dart';
import 'package:photos/core/cache/thumbnail_cache_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

final _logger = Logger("ThumbnailUtil");
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

Future<io.File> getThumbnailFromServer(File file) async {
  return ThumbnailCacheManager.instance
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
  final cachedThumbnail = ThumbnailCacheManager.instance.putFile(
    file.getThumbnailUrl(),
    data,
    eTag: file.getThumbnailUrl(),
    maxAge: Duration(days: 365),
  );
  return cachedThumbnail;
}
