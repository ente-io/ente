import "dart:convert";
import "dart:core";
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
import "package:photos/models/api/metadata.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/module/upload/model/media.dart";
import "package:photos/module/upload/model/upload_data.dart";
import "package:photos/module/upload/service/media.dart";
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

Future<UploadMetadaData> getUploadMetadata(
  UploadMedia mediaUploadData,
  EnteFile file,
) async {
  final FileType fileType = file.fileType;
  Map<String, IfdTag>? exifData;
  if (fileType == FileType.image) {
    exifData = await readExifAsync(mediaUploadData.uploadFile);
  } else if (fileType == FileType.livePhoto) {
    final imageFile = File(mediaUploadData.livePhotoImage!);
    exifData = await readExifAsync(imageFile);
  }
  final ParsedExifDateTime? exifTime =
      exifData != null ? parseExifTime(exifData) : null;
  bool? isPanorama;
  int? mviIndex;
  if (fileType == FileType.image) {
    isPanorama = isPanoFromExif(exifData);
    if (isPanorama != true) {
      try {
        final xmpData = await getXmp(mediaUploadData.uploadFile);
        isPanorama = isPanoFromXmp(xmpData);
      } catch (_) {}
      isPanorama ??= false;
    }
    if (Platform.isAndroid) {
      try {
        mviIndex = await Computer.shared().compute(
          motionVideoIndex,
          param: {'path': mediaUploadData.uploadFile.path},
          taskName: 'motionPhotoIndex',
        );
      } catch (e) {
        _logger.severe('error while detecthing motion photo start index', e);
      }
    }
  }
  final Map<String, dynamic> defaultMetadata = await getMetadata(
    mediaUploadData,
    exifTime,
    exifData,
    file,
  );

  final Map<String, dynamic> publicMetadata = _buildPublicMagicData(
    exifTime,
    file.rAsset,
    width: mediaUploadData.localAsset?.width,
    height: mediaUploadData.localAsset?.height,
    isPanorama: isPanorama,
    motionPhotoStartIndex: mviIndex,
    noThumbnail: mediaUploadData.thumbnail == null,
  );

  return UploadMetadaData(
    defaultMetadata: defaultMetadata,
    publicMetadata: publicMetadata.isEmpty ? null : publicMetadata,
  );
}

Future<Map<String, dynamic>> getMetadata(
  UploadMedia uploadMedia,
  ParsedExifDateTime? exifTime,
  Map<String, IfdTag>? exifData,
  EnteFile file,
) async {
  final AssetEntity? asset = uploadMedia.localAsset;

  final FileType fileType = file.fileType;
  final String? deviceFolder = file.deviceFolder;

  int? duration;
  final (int creationTime, int modificationTime) =
      LocalMetadataService.computeCreationAndModification(
    asset,
    exifData,
  );
  String? title = file.title;
  final Location? location = await LocalMetadataService.detectLocation(
    fileType.isVideo,
    asset,
    uploadMedia.uploadFile,
    exifData,
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

  final metadata = <String, dynamic>{
    "localID": asset?.id,
    "hash": uploadMedia.hash,
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

Map<String, dynamic> _buildPublicMagicData(
  ParsedExifDateTime? parsedExifTime,
  RemoteAsset? rAsset, {
  required int? width,
  required int? height,
  required bool? isPanorama,
  required int? motionPhotoStartIndex,
  required bool noThumbnail,
}) {
  final Map<String, dynamic> pubMetadata = {};
  if ((height ?? 0) != 0 && (width ?? 0) != 0) {
    pubMetadata[heightKey] = height;
    pubMetadata[widthKey] = width;
  }
  pubMetadata[mediaTypeKey] = isPanorama == true ? 1 : 0;
  if (motionPhotoStartIndex != null) {
    pubMetadata[motionVideoIndexKey] = motionPhotoStartIndex;
  }
  if (noThumbnail) {
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
