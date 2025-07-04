import 'dart:async';
import "dart:convert";
import "dart:io";
import 'dart:typed_data';
import 'dart:ui' as ui;

import "package:computer/computer.dart";
import 'package:ente_crypto/ente_crypto.dart';
import "package:exif_reader/exif_reader.dart";
import 'package:logging/logging.dart';
import "package:motion_photos/motion_photos.dart";
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import "package:photos/image/thumnail/upload_thumb.dart";
import "package:photos/models/api/metadata.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/module/upload/model/upload_data.dart";
import "package:photos/services/local/asset_entity.service.dart";
import "package:photos/services/local/import/local_import.dart";
import "package:photos/services/local/livephoto.dart";
import "package:photos/services/local/metadata/metadata.service.dart";
import "package:photos/services/local/shared_assert.service.dart";
import "package:photos/utils/exif_util.dart";
import "package:photos/utils/panorama_util.dart";
import "package:photos/utils/standalone/decode_image.dart";
import 'package:video_thumbnail/video_thumbnail.dart';

final _logger = Logger("FileUtil");

Future<MediaUploadData> getUploadDataFromEnteFile(
  EnteFile file, {
  bool parseExif = false,
}) async {
  if (file.isSharedMediaToAppSandbox) {
    return await _getSharedMediaUploadData(file);
  } else {
    return await _getMediaUploadDataFromAssetFile(file, parseExif);
  }
}

Future<MediaUploadData> _getMediaUploadDataFromAssetFile(
  EnteFile file,
  bool parseExif,
) async {
  Uint8List? thumbnailData;
  bool isDeleted;
  String? zipHash;
  String fileHash;
  Map<String, IfdTag>? exifData;
  final asset = await AssetEntityService.fromIDWithRetry(file.lAsset!.id);
  AssetEntityService.assetType(asset, file.fileType);
  if (Platform.isIOS) {
    trackOriginFetchForUploadOrML.put(file.lAsset!.id, true);
  }
  File sourceFile = await AssetEntityService.sourceFromAsset(asset);
  thumbnailData = await getThumbnailForUpload(asset);
  if (parseExif) {
    exifData = await tryExifFromFile(sourceFile);
  }
  final int? h = asset.height != 0 ? asset.height : null;
  final int? w = asset.width != 0 ? asset.width : null;
  int? motionPhotoStartingIndex;
  if (Platform.isAndroid && asset.type == AssetType.image) {
    try {
      motionPhotoStartingIndex = await Computer.shared().compute(
        motionVideoIndex,
        param: {'path': sourceFile.path},
        taskName: 'motionPhotoIndex',
      );
    } catch (e) {
      _logger.severe('error while detecthing motion photo start index', e);
    }
  }

  fileHash = await CryptoUtil.getHash(sourceFile);
  if (file.fileType == FileType.livePhoto && Platform.isIOS) {
    final (videoUrl, videoHash) =
        await LivePhotoService.liveVideoAndHash(file.lAsset!.id);
    final zippedPath = await LivePhotoService.zip(
      id: file.lAsset!.id,
      imagePath: sourceFile.path,
      videoPath: videoUrl.path,
    );
    await sourceFile.delete();
    await videoUrl.delete();
    // new sourceFile which needs to be uploaded
    sourceFile = File(zippedPath);
    // imgHash:vidHash
    fileHash = '$fileHash$kHashSeprator$videoHash';
    zipHash = await CryptoUtil.getHash(sourceFile);
  }

  isDeleted = !(await asset.exists);

  return MediaUploadData(
    sourceFile,
    thumbnailData,
    isDeleted,
    Hash(fileHash, zipHash: zipHash),
    height: h,
    width: w,
    motionPhotoStartIndex: motionPhotoStartingIndex,
    exifData: exifData,
  );
}

Future<int?> motionVideoIndex(Map<String, dynamic> args) async {
  final String path = args['path'];
  return (await MotionPhotos(path).getMotionVideoIndex())?.start;
}

Future<Map<String, dynamic>> getMetadata(
  MediaUploadData mediaUploadData,
  ParsedExifDateTime? exifTime,
  EnteFile file,
) async {
  final AssetEntity? asset = await file.getAsset;
  final FileType fileType = file.fileType;
  final String? deviceFolder = file.deviceFolder;

  int? duration;
  final (int creationTime, int modificationTime) =
      LocalMetadataService.computeCreationAndModification(
    asset,
    mediaUploadData.exifData,
  );
  String? title = file.title;

  final Location? location = await LocalMetadataService.detectLocation(
    fileType.isVideo,
    asset,
    mediaUploadData.sourceFile,
    mediaUploadData.exifData,
  );
  // asset can be null for files shared to app
  if (asset != null) {
    if (asset.type == AssetType.video) {
      duration = asset.duration;
    }
    if (title == null || title.isEmpty) {
      _logger.warning("Title was missing ${file.tag}");
      title = await asset.titleAsync;
    }
  }

  mediaUploadData.isPanorama = isPanoFromExif(mediaUploadData.exifData);
  if (mediaUploadData.isPanorama != true && fileType == FileType.image) {
    try {
      final xmpData = await getXmp(mediaUploadData.sourceFile);
      mediaUploadData.isPanorama = isPanoFromXmp(xmpData);
    } catch (_) {}
    mediaUploadData.isPanorama ??= false;
  }

  final metadata = <String, dynamic>{
    "localID": asset?.id,
    "hash": mediaUploadData.hash.data,
    "version": EnteFile.kCurrentMetadataVersion,
    "title": title,
    "deviceFolder": deviceFolder,
    "creationTime": creationTime,
    "modificationTime": modificationTime,
    "fileType": fileType.index,
  };

  if (asset != null) {
    metadata["subType"] = asset.subtype;
  }
  if (Location.isValidLocation(location)) {
    metadata["latitude"] = location!.latitude;
    metadata["longitude"] = location.longitude;
  }
  if (duration != null) {
    metadata["duration"] = duration;
  }

  return metadata;
}

Map<String, dynamic> buildPublicMagicData(
  MediaUploadData mediaUploadData,
  ParsedExifDateTime? parsedExifTime,
  RemoteAsset? rAsset,
) {
  final Map<String, dynamic> pubMetadata = {};
  if ((mediaUploadData.height ?? 0) != 0 && (mediaUploadData.width ?? 0) != 0) {
    pubMetadata[heightKey] = mediaUploadData.height;
    pubMetadata[widthKey] = mediaUploadData.width;
  }
  pubMetadata[mediaTypeKey] = mediaUploadData.isPanorama == true ? 1 : 0;
  if (mediaUploadData.motionPhotoStartIndex != null) {
    pubMetadata[motionVideoIndexKey] = mediaUploadData.motionPhotoStartIndex;
  }
  if (mediaUploadData.thumbnail == null) {
    pubMetadata[noThumbKey] = true;
  }
  if (parsedExifTime?.dateTime != null) {
    pubMetadata[dateTimeKey] = parsedExifTime!.dateTime;
  }
  if (parsedExifTime?.offsetTime != null) {
    pubMetadata[offsetTimeKey] = parsedExifTime!.offsetTime;
  }

  final Map<String, dynamic> jsonToUpdate =
      rAsset?.publicMetadata?.data ?? <String, dynamic>{};
  pubMetadata.forEach((key, value) {
    jsonToUpdate[key] = value;
  });
  return jsonToUpdate;
}

Future<MetadataRequest?> getPubMetadataRequest(
  EnteFile file,
  Map<String, dynamic> jsonToUpdate,
  Uint8List fileKey,
) async {
  if (jsonToUpdate.isEmpty) {
    return null;
  }
  final int currentVersion = (file.rAsset?.publicMetadata?.version ?? 0);
  final encryptedMMd = await CryptoUtil.encryptChaCha(
    utf8.encode(jsonEncode(jsonToUpdate)),
    fileKey,
  );
  return MetadataRequest(
    version: currentVersion == 0 ? 1 : currentVersion,
    count: jsonToUpdate.length,
    data: CryptoUtil.bin2base64(encryptedMMd.encryptedData!),
    header: CryptoUtil.bin2base64(encryptedMMd.header!),
  );
}

Future<MediaUploadData> _getSharedMediaUploadData(EnteFile file) async {
  final localPath = SharedAssetService.getPath(file.localID!);
  final sourceFile = File(localPath);
  if (!sourceFile.existsSync()) {
    _logger.warning("File doesn't exist in app sandbox");
    throw InvalidFileError(
      "source missing in sandbox",
      InvalidReason.sourceFileMissing,
    );
  }
  try {
    Map<String, IfdTag>? exifData;
    final Uint8List? thumbnailData = await SharedAssetService.getThumbnail(
      file.localID!,
      file.isVideo,
    );
    final fileHash = await CryptoUtil.getHash(sourceFile);
    ui.Image? decodedImage;
    if (file.fileType == FileType.image) {
      decodedImage = await decodeImageInIsolate(localPath);
      exifData = await tryExifFromFile(sourceFile);
    } else if (thumbnailData != null) {
      // the thumbnail null check is to ensure that we are able to generate thum
      // for video, we need to use the thumbnail data with any max width/height
      final thumbforVidDimention = await VideoThumbnail.thumbnailFile(
        video: localPath,
        imageFormat: ImageFormat.JPEG,
        thumbnailPath: (await getTemporaryDirectory()).path,
        quality: 10,
      );
      if (thumbforVidDimention != null) {
        decodedImage = await decodeImageInIsolate(thumbforVidDimention);
      }
    }
    return MediaUploadData(
      sourceFile,
      thumbnailData,
      false,
      Hash(fileHash),
      height: decodedImage?.height,
      width: decodedImage?.width,
      exifData: exifData,
    );
  } catch (e, s) {
    _logger.warning("failed to generate thumbnail", e, s);
    throw InvalidFileError(
      "thumbnail failed for appCache fileType: ${file.fileType.toString()}",
      InvalidReason.thumbnailMissing,
    );
  }
}
