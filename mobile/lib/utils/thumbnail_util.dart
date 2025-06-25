import 'dart:async';
import 'dart:collection';
import 'dart:io';
import "dart:typed_data";

import 'package:dio/dio.dart';
import 'package:ente_crypto/ente_crypto.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/module/download/file_url.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/utils/file_key.dart";
import 'package:photos/utils/file_uploader_util.dart';
import 'package:photos/utils/file_util.dart';

final _logger = Logger("ThumbnailUtil");
final _uploadIDToDownloadItem = <int, FileDownloadItem>{};
final _downloadQueue = Queue<int>();
const int kMaximumConcurrentDownloads = 500;

class FileDownloadItem {
  final EnteFile file;
  final Completer<Uint8List> completer;
  final CancelToken cancelToken;
  int counter = 0; // number of times file download was requested

  FileDownloadItem(this.file, this.completer, this.cancelToken, this.counter);
}

Future<Uint8List?> getThumbnail(EnteFile file) async {
  if (file.isRemoteFile) {
    return getThumbnailFromServer(file);
  } else {
    return getThumbnailFromLocal(
      file,
      size: thumbnailLargeSize,
    );
  }
}

// Note: This method should only be called for files that have been uploaded
// since cachedThumbnailPath depends on the file's uploadedID
Future<File?> getThumbnailForUploadedFile(EnteFile file) async {
  final cachedThumbnail = cachedThumbnailPath(file);
  if (await cachedThumbnail.exists()) {
    _logger.info("Thumbnail already exists for ${file.uploadedFileID}");
    return cachedThumbnail;
  }
  final thumbnail = await getThumbnail(file);
  if (thumbnail != null) {
    // it might be already written to this path during `getThumbnail(file)`
    if (!await cachedThumbnail.exists()) {
      await cachedThumbnail.writeAsBytes(thumbnail, flush: true);
    }
    _logger.info("Thumbnail obtained for ${file.uploadedFileID}");
    return cachedThumbnail;
  }
  _logger.severe("Failed to get thumbnail for ${file.uploadedFileID}");
  return null;
}

Future<Uint8List> getThumbnailFromServer(EnteFile file) async {
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
  EnteFile file, {
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

void removePendingGetThumbnailRequestIfAny(EnteFile file) {
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
    if (CollectionsService.instance.isSharedPublicLink(file.collectionID!)) {
      final headers = CollectionsService.instance
          .publicCollectionHeaders(file.collectionID!);
      encryptedThumbnail = (await NetworkClient.instance.getDio().get(
                FileUrl.getUrl(
                  file.uploadedFileID!,
                  FileUrlType.publicThumbnail,
                ),
                options: Options(
                  headers: headers,
                  responseType: ResponseType.bytes,
                ),
              ))
          .data;
    } else {
      encryptedThumbnail = (await NetworkClient.instance.getDio().get(
                FileUrl.getUrl(
                  file.uploadedFileID!,
                  FileUrlType.thumbnail,
                ),
                options: Options(
                  headers: {"X-Auth-Token": Configuration.instance.getToken()},
                  responseType: ResponseType.bytes,
                ),
                cancelToken: item.cancelToken,
              ))
          .data;
    }
  } catch (e) {
    if (e is DioException && CancelToken.isCancel(e)) {
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
    _logger.severe("Failed to decrypt thumbnail ${item.file.toString()}", e, s);
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

File cachedThumbnailPath(EnteFile file) {
  final thumbnailCacheDirectory =
      Configuration.instance.getThumbnailCacheDirectory();
  return File(
    thumbnailCacheDirectory + "/" + file.uploadedFileID.toString(),
  );
}

File cachedFaceCropPath(String faceID, bool useTempCache) {
  late final String thumbnailCacheDirectory;
  if (useTempCache) {
    thumbnailCacheDirectory =
        Configuration.instance.getThumbnailCacheDirectory();
  } else {
    thumbnailCacheDirectory =
        Configuration.instance.getPersonFaceThumbnailCacheDirectory();
  }
  return File(
    thumbnailCacheDirectory + "/" + faceID,
  );
}
