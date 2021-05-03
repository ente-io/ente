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
import 'package:photos/core/errors.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

final _logger = Logger("ThumbnailUtil");
final _map = LinkedHashMap<int, FileDownloadItem>();
final _queue = Queue<int>();
const int kMaximumConcurrentDownloads = 2500;

class FileDownloadItem {
  final File file;
  final Completer<io.File> completer;
  final CancelToken cancelToken;

  FileDownloadItem(this.file, this.completer, this.cancelToken);
}

Future<io.File> getThumbnailFromServer(File file) async {
  return ThumbnailCacheManager.instance
      .getFileFromCache(file.getThumbnailUrl())
      .then((info) {
    if (info == null) {
      if (!_map.containsKey(file.uploadedFileID)) {
        if (_queue.length == kMaximumConcurrentDownloads) {
          final id = _queue.removeFirst();
          final item = _map.remove(id);
          item.cancelToken.cancel();
          item.completer.completeError(RequestCancelledError());
        }
        final item =
            FileDownloadItem(file, Completer<io.File>(), CancelToken());
        _map[file.uploadedFileID] = item;
        _queue.add(file.uploadedFileID);
        _downloadItem(item);
        return item.completer.future;
      } else {
        return _map[file.uploadedFileID].completer.future;
      }
    } else {
      ThumbnailFileLruCache.put(file, info.file);
      return info.file;
    }
  });
}

void removePendingGetThumbnailRequestIfAny(File file) {
  if (_map.containsKey(file.uploadedFileID)) {
    final item = _map.remove(file.uploadedFileID);
    item.cancelToken.cancel();
    _queue.removeWhere((element) => element == file.uploadedFileID);
  }
}

void _downloadItem(FileDownloadItem item) async {
  try {
    await _downloadAndDecryptThumbnail(item);
  } catch (e, s) {
    _logger.severe(
        "Failed to download thumbnail " + item.file.toString(), e, s);
    item.completer.completeError(e);
  }
  _queue.removeWhere((element) => element == item.file.uploadedFileID);
  _map.remove(item.file.uploadedFileID);
}

Future<void> _downloadAndDecryptThumbnail(FileDownloadItem item) async {
  final file = item.file;
  var encryptedThumbnail;
  try {
    encryptedThumbnail = (await Network.instance.getDio().get(
              file.getThumbnailUrl(),
              options: Options(
                headers: {"X-Auth-Token": Configuration.instance.getToken()},
                responseType: ResponseType.bytes,
              ),
              cancelToken: item.cancelToken,
            ))
        .data;
  } catch (e) {
    if (e is DioError && CancelToken.isCancel(e)) {
      return;
    }
    throw e;
  }
  if (!_map.containsKey(file.uploadedFileID)) {
    return;
  }
  final thumbnailDecryptionKey = decryptFileKey(file);
  var data = CryptoUtil.decryptChaCha(
    encryptedThumbnail,
    thumbnailDecryptionKey,
    Sodium.base642bin(file.thumbnailDecryptionHeader),
  );
  final thumbnailSize = data.length;
  if (thumbnailSize > THUMBNAIL_DATA_LIMIT) {
    data = await compressThumbnail(data);
  }
  final cachedThumbnail = await ThumbnailCacheManager.instance.putFile(
    file.getThumbnailUrl(),
    data,
    eTag: file.getThumbnailUrl(),
    maxAge: Duration(days: 365),
  );
  ThumbnailFileLruCache.put(item.file, cachedThumbnail);
  if (_map.containsKey(file.uploadedFileID)) {
    try {
      item.completer.complete(cachedThumbnail);
    } catch (e) {
      _logger.severe("Error while completing request for " +
          file.uploadedFileID.toString());
    }
  }
}
