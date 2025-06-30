import 'dart:async';
import "dart:convert";
import "dart:io";
import 'dart:typed_data';
import 'dart:ui' as ui;

import "package:archive/archive_io.dart";
import "package:computer/computer.dart";
import 'package:ente_crypto/ente_crypto.dart';
import "package:exif_reader/exif_reader.dart";
import 'package:logging/logging.dart';
import "package:motion_photos/motion_photos.dart";
import 'package:motionphoto/motionphoto.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/core/errors.dart';
import "package:photos/image/thumnail/upload_thumb.dart";
import "package:photos/models/api/metadata.dart";
import "package:photos/models/ffmpeg/ffprobe_props.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/location/location.dart";
import "package:photos/services/local/asset_entity.service.dart";
import "package:photos/services/local/local_import.dart";
import "package:photos/services/local/shared_assert.service.dart";
import "package:photos/utils/exif_util.dart";
import 'package:photos/utils/file_util.dart';
import "package:photos/utils/standalone/decode_image.dart";
import "package:uuid/uuid.dart";
import 'package:video_thumbnail/video_thumbnail.dart';

final _logger = Logger("FileUtil");

class MediaUploadData {
  final File? sourceFile;
  final Uint8List? thumbnail;
  final bool isDeleted;
  final FileHashData? hashData;
  final int? height;
  final int? width;

  // For android motion photos, the startIndex is the index of the first frame
  // For iOS, this value will be always null.
  final int? motionPhotoStartIndex;

  final Map<String, IfdTag>? exifData;

  bool? isPanorama;

  MediaUploadData(
    this.sourceFile,
    this.thumbnail,
    this.isDeleted,
    this.hashData, {
    this.height,
    this.width,
    this.motionPhotoStartIndex,
    this.isPanorama,
    this.exifData,
  });
}

class FileHashData {
  // For livePhotos, the fileHash value will be imageHash:videoHash
  final String? fileHash;

  // zipHash is used to take care of existing live photo uploads from older
  // mobile clients
  String? zipHash;

  FileHashData(this.fileHash, {this.zipHash});
}

Future<MediaUploadData> getUploadDataFromEnteFile(
  EnteFile file, {
  bool parseExif = false,
}) async {
  if (file.isSharedMediaToAppSandbox) {
    return await _getMediaUploadDataFromAppCache(file, parseExif);
  } else {
    return await _getMediaUploadDataFromAssetFile(file, parseExif);
  }
}

Future<MediaUploadData> _getMediaUploadDataFromAssetFile(
  EnteFile file,
  bool parseExif,
) async {
  File? sourceFile;
  Uint8List? thumbnailData;
  bool isDeleted;
  String? zipHash;
  String fileHash;
  Map<String, IfdTag>? exifData;

  // The timeouts are to safeguard against https://github.com/CaiJingLong/flutter_photo_manager/issues/467
  final asset = await AssetEntityService.fromIDWithRetry(file.lAsset!.id);
  _assertFileType(asset, file);
  if (Platform.isIOS) {
    trackOriginFetchForUploadOrML.put(file.lAsset!.id, true);
  }
  sourceFile = await AssetEntityService.sourceFromAsset(asset);
  thumbnailData = await getThumbnailForUpload(asset);
  if (parseExif) {
    exifData = await tryExifFromFile(sourceFile);
  }
  // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
  // call this method before creating zip for live photo as sourceFile image will be
  // deleted after zipping
  await _decorateEnteFileData(file, asset, sourceFile, exifData);
  int? h, w;
  if (asset.width != 0 && asset.height != 0) {
    h = asset.height;
    w = asset.width;
  }
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
  fileHash = CryptoUtil.bin2base64(await CryptoUtil.getHash(sourceFile));
  if (file.fileType == FileType.livePhoto && Platform.isIOS) {
    final File? videoUrl = await Motionphoto.getLivePhotoFile(file.localID!);
    if (videoUrl == null || !videoUrl.existsSync()) {
      final String errMsg =
          "missing livePhoto url for  ${file.toString()} with subType ${file.fileSubType}";
      _logger.severe(errMsg);
      throw InvalidFileError(errMsg, InvalidReason.livePhotoVideoMissing);
    }
    final String videoHash =
        CryptoUtil.bin2base64(await CryptoUtil.getHash(videoUrl));
    // imgHash:vidHash
    fileHash = '$fileHash$kLivePhotoHashSeparator$videoHash';
    final tempPath = Configuration.instance.getTempDirectory();
    // .elp -> ente live photo
    final uniqueId = const Uuid().v4().toString();
    final zippedPath = tempPath + uniqueId + "_${file.generatedID}.elp";
    _logger.info("Creating zip for live photo from " + basename(zippedPath));
    await zip(
      zipPath: zippedPath,
      imagePath: sourceFile.path,
      videoPath: videoUrl.path,
    );
    // delete the temporary video and image copy (only in IOS)
    if (Platform.isIOS) {
      await sourceFile.delete();
    }
    // new sourceFile which needs to be uploaded
    sourceFile = File(zippedPath);
    zipHash = CryptoUtil.bin2base64(await CryptoUtil.getHash(sourceFile));
  }

  isDeleted = !(await asset.exists);

  return MediaUploadData(
    sourceFile,
    thumbnailData,
    isDeleted,
    FileHashData(fileHash, zipHash: zipHash),
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

Future<void> zip({
  required String zipPath,
  required String imagePath,
  required String videoPath,
}) {
  return Computer.shared().compute(
    (Map<String, dynamic> args) async {
      final encoder = ZipFileEncoder();
      encoder.create(args['zipPath']);
      await encoder.addFile(
        File(args['imagePath']),
        "image${extension(args['imagePath'])}",
      );
      await encoder.addFile(
        File(args['videoPath']),
        "video${extension(args['videoPath'])}",
      );
      await encoder.close();
    },
    param: {
      'zipPath': zipPath,
      'imagePath': imagePath,
      'videoPath': videoPath,
    },
    taskName: 'zip',
  );
}

// check if the assetType is still the same. This can happen for livePhotos
// if the user turns off the video using native photos app
void _assertFileType(AssetEntity asset, EnteFile file) {
  final assetType = fileTypeFromAsset(asset);
  if (assetType == file.fileType) {
    return;
  }
  if (Platform.isIOS || Platform.isMacOS) {
    if (assetType == FileType.image && file.fileType == FileType.livePhoto) {
      throw InvalidFileError(
        'id ${asset.id}',
        InvalidReason.livePhotoToImageTypeChanged,
      );
    } else if (assetType == FileType.livePhoto &&
        file.fileType == FileType.image) {
      throw InvalidFileError(
        'id ${asset.id}',
        InvalidReason.imageToLivePhotoTypeChanged,
      );
    }
  }
  throw InvalidFileError(
    'fileType mismatch for id ${asset.id} assetType $assetType fileType ${file.fileType}',
    InvalidReason.unknown,
  );
}

Future<void> _decorateEnteFileData(
  EnteFile file,
  AssetEntity asset,
  File sourceFile,
  Map<String, IfdTag>? exifData,
) async {
  // h4ck to fetch location data if missing (thank you Android Q+) lazily only during uploads
  if (file.location == null ||
      (file.location!.latitude == 0 && file.location!.longitude == 0)) {
    final latLong = await asset.latlngAsync();
    file.location =
        Location(latitude: latLong.latitude, longitude: latLong.longitude);
  }
  if (!file.hasLocation && file.isVideo && Platform.isAndroid) {
    final FFProbeProps? props = await getVideoPropsAsync(sourceFile);
    if (props != null && props.location != null) {
      file.location = props.location;
    }
  }
  if (Platform.isAndroid && exifData != null) {
    //Fix for missing location data in lower android versions.
    final Location? exifLocation = locationFromExif(exifData);
    if (Location.isValidLocation(exifLocation)) {
      file.location = exifLocation;
    }
  }
  if (file.title == null || file.title!.isEmpty) {
    _logger.warning("Title was missing ${file.tag}");
    file.title = await asset.titleAsync;
  }
}

Future<MetadataRequest> getPubMetadataRequest(
  EnteFile file,
  Map<String, dynamic> jsonToUpdate,
  Uint8List fileKey,
) async {
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

Future<MediaUploadData> _getMediaUploadDataFromAppCache(
  EnteFile file,
  bool parseExif,
) async {
  final localPath = getSharedMediaFilePath(file);
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
    final Uint8List? thumbnailData =
        await SharedAssertService.getThumbnailFromInAppCacheFile(
      file.localID!,
      file.isVideo,
    );
    final fileHash =
        CryptoUtil.bin2base64(await CryptoUtil.getHash(sourceFile));
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
      FileHashData(fileHash),
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
