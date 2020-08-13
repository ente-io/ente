import 'dart:io' as io;
import 'dart:typed_data';

import 'package:path/path.dart';
import 'package:dio/dio.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/cache/thumbnail_cache.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart';

import 'crypto_util.dart';

Future<void> deleteFiles(List<File> files,
    {bool deleteEveryWhere = false}) async {
  await PhotoManager.editor
      .deleteWithIds(files.map((file) => file.localID).toList());
  for (File file in files) {
    deleteEveryWhere
        ? await FilesDB.instance.markForDeletion(file)
        : await FilesDB.instance.delete(file);
  }
}

void preloadFile(File file) {
  // TODO
}

Future<Uint8List> getBytes(File file, {int quality = 100}) async {
  if (file.localID == null) {
    if (!file.isEncrypted) {
      return DefaultCacheManager()
          .getSingleFile(file.getDownloadUrl())
          .then((file) => file.readAsBytesSync());
    } else {
      return DefaultCacheManager()
          .getFileFromCache(file.getDownloadUrl())
          .then((info) {
        if (info == null) {
          final temporaryPath = Configuration.instance.getTempDirectory() +
              file.generatedID.toString() +
              ".aes";
          return Dio()
              .download(file.getDownloadUrl(), temporaryPath)
              .then((_) async {
            final data = await CryptoUtil.decryptFileToData(
                temporaryPath, Configuration.instance.getKey());
            io.File(temporaryPath).deleteSync();
            DefaultCacheManager().putFile(file.getDownloadUrl(), data);
            return data;
          });
        } else {
          return info.file.readAsBytesSync();
        }
      });
    }
  } else {
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
}

void preloadLocalFileThumbnail(File file) {
  if (file.localID == null ||
      ThumbnailLruCache.get(file, THUMBNAIL_SMALL_SIZE) != null) {
    return;
  }
  file.getAsset().then((asset) {
    asset
        .thumbDataWithSize(THUMBNAIL_SMALL_SIZE, THUMBNAIL_SMALL_SIZE)
        .then((data) {
      ThumbnailLruCache.put(file, THUMBNAIL_SMALL_SIZE, data);
    });
  });
}
