import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_util.dart';

import 'dart:io' as io;
import 'file_uploader_util.dart';

final _logger = Logger("ThumbnailUtil");
final _map = LinkedHashMap<int, FileDownloadItem>();
final _queue = Queue<int>();
const int kMaximumConcurrentDownloads = 500;

class FileDownloadItem {
  final File file;
  final Completer<Uint8List> completer;
  final CancelToken cancelToken;
  int counter = 0; // number of times file download was requested

  FileDownloadItem(this.file, this.completer, this.cancelToken, this.counter);
}

Future<Uint8List> getThumbnailFromServer(File file) async {
  final cachedThumbnail = getCachedThumbnail(file);
  if (cachedThumbnail.existsSync()) {
    final data = cachedThumbnail.readAsBytesSync();
    ThumbnailLruCache.put(file, data);
    return data;
  }
  if (!_map.containsKey(file.uploadedFileID)) {
    if (_queue.length > kMaximumConcurrentDownloads) {
      final id = _queue.removeFirst();
      final item = _map.remove(id);
      item.cancelToken.cancel();
      item.completer.completeError(RequestCancelledError());
    }
    final item =
        FileDownloadItem(file, Completer<Uint8List>(), CancelToken(), 1);
    _map[file.uploadedFileID] = item;
    _queue.add(file.uploadedFileID);
    _downloadItem(item);
    return item.completer.future;
  } else {
    _map[file.uploadedFileID].counter++;
    return _map[file.uploadedFileID].completer.future;
  }
}

Future<Uint8List> getThumbnailFromLocal(File file) async {
  if (ThumbnailLruCache.get(file, kThumbnailSmallSize) != null) {
    return ThumbnailLruCache.get(file);
  }
  final cachedThumbnail = getCachedThumbnail(file);
  if (cachedThumbnail.existsSync()) {
    final data = cachedThumbnail.readAsBytesSync();
    ThumbnailLruCache.put(file, data);
    return data;
  }
  if (file.isCachedInAppSandbox()) {
    return getThumbnailFromInAppCacheFile(file)
        .then((data) {
      if (data != null) {
        ThumbnailLruCache.put(file, data, kThumbnailSmallSize);
      }
      return data;
    });
  } else {
    return file.getAsset().then((asset) async {
      if (asset == null || !(await asset.exists)) {
        return null;
      }
      return asset
          .thumbDataWithSize(kThumbnailSmallSize, kThumbnailSmallSize,
              quality: kThumbnailQuality)
          .then((data) {
        ThumbnailLruCache.put(file, data, kThumbnailSmallSize);
        return data;
      });
    });
  }
}

void removePendingGetThumbnailRequestIfAny(File file) {
  if (_map.containsKey(file.uploadedFileID)) {
    final item = _map[file.uploadedFileID];
    item.counter--;
    if (item.counter <= 0) {
      _map.remove(file.uploadedFileID);
      item.cancelToken.cancel();
      _queue.removeWhere((element) => element == file.uploadedFileID);
    }
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
  var data = await CryptoUtil.decryptChaCha(
    encryptedThumbnail,
    thumbnailDecryptionKey,
    Sodium.base642bin(file.thumbnailDecryptionHeader),
  );
  final thumbnailSize = data.length;
  if (thumbnailSize > kThumbnailDataLimit) {
    data = await compressThumbnail(data);
  }
  ThumbnailLruCache.put(item.file, data);
  final cachedThumbnail = getCachedThumbnail(item.file);
  if (cachedThumbnail.existsSync()) {
    cachedThumbnail.deleteSync();
  }
  cachedThumbnail.writeAsBytes(data);
  if (_map.containsKey(file.uploadedFileID)) {
    try {
      item.completer.complete(data);
    } catch (e) {
      _logger.severe("Error while completing request for " +
          file.uploadedFileID.toString());
    }
  }
}

io.File getCachedThumbnail(File file) {
  final thumbnailCacheDirectory =
      Configuration.instance.getThumbnailCacheDirectory();
  return io.File(
      thumbnailCacheDirectory + "/" + file.uploadedFileID.toString());
}
