import 'dart:async';
import 'dart:io' as io;
import 'dart:typed_data';

import 'package:archive/archive_io.dart';
import 'package:logging/logging.dart';
import 'package:motionphoto/motionphoto.dart';
import 'package:path/path.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/models/file.dart' as ente;
import 'package:photos/models/file_type.dart';
import 'package:photos/models/location.dart';

import 'file_util.dart';

final _logger = Logger("FileUtil");
const kMaximumThumbnailCompressionAttempts = 2;

class MediaUploadData {
  final io.File sourceFile;
  final Uint8List thumbnail;
  final bool isDeleted;

  MediaUploadData(this.sourceFile, this.thumbnail, this.isDeleted);
}

Future<MediaUploadData> getUploadDataFromEnteFile(ente.File file) async {
  if (file.isSharedMediaToAppSandbox()) {
    return await _getMediaUploadDataFromAppCache(file);
  } else {
    return await _getMediaUploadDataFromAssetFile(file);
  }
}

Future<MediaUploadData> _getMediaUploadDataFromAssetFile(ente.File file) async {
  io.File sourceFile;
  Uint8List thumbnailData;
  bool isDeleted;

  // The timeouts are to safeguard against https://github.com/CaiJingLong/flutter_photo_manager/issues/467
  final asset =
      await file.getAsset().timeout(Duration(seconds: 3)).catchError((e) async {
    if (e is TimeoutException) {
      _logger.info("Asset fetch timed out for " + file.toString());
      return await file.getAsset();
    } else {
      throw e;
    }
  });
  if (asset == null) {
    throw InvalidFileError();
  }
  sourceFile = await asset.originFile
      .timeout(Duration(seconds: 3))
      .catchError((e) async {
    if (e is TimeoutException) {
      _logger.info("Origin file fetch timed out for " + file.toString());
      return await asset.originFile;
    } else {
      throw e;
    }
  });
  if (!sourceFile.existsSync()) {
    throw InvalidFileError();
  }

  // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
  await _decorateEnteFileData(file, asset);

  if (file.fileType == FileType.livePhoto && io.Platform.isIOS) {
    final io.File videoUrl = await Motionphoto.getLivePhotoFile(file.localID);
    final tempPath =  Configuration.instance.getTempDirectory();
    final zipFilePath = tempPath + file.generatedID.toString() + ".zip";
    _logger.fine("Uploading zipped live photo from " + zipFilePath);
    var encoder = ZipFileEncoder();
    encoder.create(zipFilePath);
    encoder.addFile(videoUrl, "video" + extension(videoUrl.path));
    encoder.addFile(sourceFile, "image" + extension(sourceFile.path));
    encoder.close();
    // delete the temporary video and image copy (only in IOS)
    if(io.Platform.isIOS) {
      sourceFile.deleteSync();
    }
    // new sourceFile which needs to be uploaded
    sourceFile = io.File(zipFilePath);
  }

  thumbnailData = await asset.thumbDataWithSize(
    kThumbnailSmallSize,
    kThumbnailSmallSize,
    quality: kThumbnailQuality,
  );
  int compressionAttempts = 0;
  while (thumbnailData.length > kThumbnailDataLimit &&
      compressionAttempts < kMaximumThumbnailCompressionAttempts) {
    _logger.info("Thumbnail size " + thumbnailData.length.toString());
    thumbnailData = await compressThumbnail(thumbnailData);
    _logger
        .info("Compressed thumbnail size " + thumbnailData.length.toString());
    compressionAttempts++;
  }

  isDeleted = asset == null || !(await asset.exists);
  return MediaUploadData(sourceFile, thumbnailData, isDeleted);
}

Future<void> _decorateEnteFileData(ente.File file, AssetEntity asset) async {
  // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
  if (file.location == null ||
      (file.location.latitude == 0 && file.location.longitude == 0)) {
    final latLong = await asset.latlngAsync();
    file.location = Location(latLong.latitude, latLong.longitude);
  }

  if (file.title == null || file.title.isEmpty) {
    _logger.severe("Title was missing");
    file.title = await asset.titleAsync;
  }
}

Future<MediaUploadData> _getMediaUploadDataFromAppCache(ente.File file) async {
  io.File sourceFile;
  Uint8List thumbnailData;
  bool isDeleted = false;
  var localPath = getSharedMediaFilePath(file);
  sourceFile = io.File(localPath);
  if (!sourceFile.existsSync()) {
    _logger.warning("File doesn't exist in app sandbox");
    throw InvalidFileError();
  }
  thumbnailData = await getThumbnailFromInAppCacheFile(file);
  return MediaUploadData(sourceFile, thumbnailData, isDeleted);
}

Future<Uint8List> getThumbnailFromInAppCacheFile(ente.File file) async {
  var localFile = io.File(getSharedMediaFilePath(file));
  if (!localFile.existsSync()) {
    return null;
  }
  var thumbnailData = localFile.readAsBytesSync();
  int compressionAttempts = 0;
  while (thumbnailData.length > kThumbnailDataLimit &&
      compressionAttempts < kMaximumThumbnailCompressionAttempts) {
    _logger.info("Thumbnail size " + thumbnailData.length.toString());
    thumbnailData = await compressThumbnail(thumbnailData);
    _logger
        .info("Compressed thumbnail size " + thumbnailData.length.toString());
    compressionAttempts++;
  }
  return thumbnailData;
}
