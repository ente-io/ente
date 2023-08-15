import 'dart:async';
import 'dart:collection';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/models/file.dart';
import 'package:photos/utils/crypto_util.dart';
import 'package:photos/utils/file_download_util.dart';
import 'package:photos/utils/file_uploader_util.dart';
import 'package:photos/utils/file_util.dart';

final _logger = Logger("ThumbnailUtil");
final _uploadIDToDownloadItem = <int, FileDownloadItem>{};
final _downloadQueue = Queue<int>();
const int kMaximumConcurrentDownloads = 500;

class FileDownloadItem {
  final File file;
  final Completer<Uint8List> completer;
  final CancelToken cancelToken;
  int counter = 0; // number of times file download was requested

  FileDownloadItem(this.file, this.completer, this.cancelToken, this.counter);
}

Future<Uint8List?> getThumbnail(File file) async {
  if (file.isRemoteFile) {
    return getThumbnailFromServer(file);
  } else {
    return getThumbnailFromLocal(
      file,
      size: thumbnailLargeSize,
    );
  }
}

Future<Uint8List> getThumbnailFromServer(File file) async {
  final cachedThumbnail = cachedThumbnailPath(file);
  if (await cachedThumbnail.exists()) {
    final data = await cachedThumbnail.readAsBytes();
    ThumbnailInMemoryLruCache.put(file, data);
    return data;
  }
  // Check if there's already in flight request for fetching thumbnail from the
  // server
  if (!_uploadIDToDownloadItem.containsKey(file.uploadedFileID)) {
    final item =
        FileDownloadItem(file, Completer<Uint8List>(), CancelToken(), 1);
    _uploadIDToDownloadItem[file.uploadedFileID!] = item;
    if (_downloadQueue.length > kMaximumConcurrentDownloads) {
      final id = _downloadQueue.removeFirst();
      final FileDownloadItem item = _uploadIDToDownloadItem.remove(id)!;
      item.cancelToken.cancel();
      item.completer.completeError(RequestCancelledError());
    }
    _downloadQueue.add(file.uploadedFileID!);
    _downloadItem(item);
    return item.completer.future;
  } else {
    _uploadIDToDownloadItem[file.uploadedFileID]!.counter++;
    return _uploadIDToDownloadItem[file.uploadedFileID]!.completer.future;
  }
}

Future<Uint8List?> getThumbnailFromLocal(
  File file, {
  int size = thumbnailSmallSize,
  int quality = thumbnailQuality,
}) async {
  final lruCachedThumbnail = ThumbnailInMemoryLruCache.get(file, size);
  if (lruCachedThumbnail != null) {
    return lruCachedThumbnail;
  }
  final cachedThumbnail = cachedThumbnailPath(file);
  if ((await cachedThumbnail.exists())) {
    final data = await cachedThumbnail.readAsBytes();
    ThumbnailInMemoryLruCache.put(file, data);
    return data;
  }
  if (file.isSharedMediaToAppSandbox) {
    //todo:neeraj support specifying size/quality
    return getThumbnailFromInAppCacheFile(file).then((data) {
      if (data != null) {
        ThumbnailInMemoryLruCache.put(file, data, size);
      }
      return data;
    });
  } else {
    return file.getAsset.then((asset) async {
      if (asset == null || !(await asset.exists)) {
        return null;
      }
      return asset
          .thumbnailDataWithSize(ThumbnailSize(size, size), quality: quality)
          .then((data) {
        ThumbnailInMemoryLruCache.put(file, data, size);
        return data;
      });
    });
  }
}

void removePendingGetThumbnailRequestIfAny(File file) {
  if (_uploadIDToDownloadItem.containsKey(file.uploadedFileID)) {
    final item = _uploadIDToDownloadItem[file.uploadedFileID]!;
    item.counter--;
    if (item.counter <= 0) {
      _uploadIDToDownloadItem.remove(file.uploadedFileID);
      item.cancelToken.cancel();
      _downloadQueue.removeWhere((element) => element == file.uploadedFileID);
    }
  }
}

void _downloadItem(FileDownloadItem item) async {
  try {
    await _downloadAndDecryptThumbnail(item);
  } catch (e, s) {
    _logger.severe(
      "Failed to download thumbnail " + item.file.toString(),
      e,
      s,
    );
    item.completer.completeError(e);
  }
  _downloadQueue.removeWhere((element) => element == item.file.uploadedFileID);
  _uploadIDToDownloadItem.remove(item.file.uploadedFileID);
}

Future<void> _downloadAndDecryptThumbnail(FileDownloadItem item) async {
  final file = item.file;
  Uint8List encryptedThumbnail;
  try {
    encryptedThumbnail = (await NetworkClient.instance.getDio().get(
              file.thumbnailUrl,
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
    rethrow;
  }
  if (!_uploadIDToDownloadItem.containsKey(file.uploadedFileID)) {
    return;
  }
  final thumbnailDecryptionKey = await getFileKeyUsingBgWorker(file);
  Uint8List data;
  try {
    data = await CryptoUtil.decryptChaCha(
      encryptedThumbnail,
      thumbnailDecryptionKey,
      CryptoUtil.base642bin(file.thumbnailDecryptionHeader!),
    );
  } catch (e, s) {
    _logger.severe("Failed to decrypt thumbnail", e, s);
    item.completer.completeError(e);
    return;
  }
  final thumbnailSize = data.length;
  if (thumbnailSize > thumbnailDataLimit) {
    data = await compressThumbnail(data);
  }
  ThumbnailInMemoryLruCache.put(item.file, data);
  final cachedThumbnail = cachedThumbnailPath(item.file);
  if (await cachedThumbnail.exists()) {
    await cachedThumbnail.delete();
  }
  // data is already cached in-memory, no need to await on dist write
  unawaited(cachedThumbnail.writeAsBytes(data));
  if (_uploadIDToDownloadItem.containsKey(file.uploadedFileID)) {
    try {
      item.completer.complete(data);
    } catch (e) {
      _logger.severe(
        "Error while completing request for " + file.uploadedFileID.toString(),
      );
    }
  }
}

io.File cachedThumbnailPath(File file) {
  final thumbnailCacheDirectory =
      Configuration.instance.getThumbnailCacheDirectory();
  return io.File(
    thumbnailCacheDirectory + "/" + file.uploadedFileID.toString(),
  );
}
