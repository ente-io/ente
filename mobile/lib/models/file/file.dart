import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import "package:photos/models/api/diff/trash_time.dart";
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import 'package:photos/models/location/location.dart';
import "package:photos/models/metadata/file_magic.dart";
import "package:photos/module/download/file_url.dart";
import "package:photos/services/local/asset_entity.service.dart";

//Todo: files with no location data have lat and long set to 0.0. This should ideally be null.
class EnteFile {
  static final _logger = Logger('File');
  AssetEntity? lAsset;
  RemoteAsset? rAsset;
  CollectionFile? cf;
  TrashTime? trashTime;
  int? generatedID;
  int? uploadedFileID;
  int? ownerID;
  int? collectionID;
  String? localID;
  String? title;
  String? deviceFolder;
  int? creationTime;
  int? modificationTime;
  int? updationTime;
  int? addedTime;
  late Location? location;
  late FileType fileType;
  int? fileSubType;
  int? duration;
  String? exif;
  String? hash;
  int? metadataVersion;

  // public magic metadata is shared if during file/album sharing
  String? pubMmdEncodedJson;
  int pubMmdVersion = 0;
  PubMagicMetadata? _pubMmd;

  PubMagicMetadata? get pubMagicMetadata =>
      _pubMmd ?? PubMagicMetadata.fromEncodedJson(pubMmdEncodedJson ?? '{}');

  set pubMagicMetadata(val) => _pubMmd = val;

  // in Version 1, live photo hash is stored as zip's hash.
  // in V2: LivePhoto hash is stored as imgHash:vidHash
  static const kCurrentMetadataVersion = 2;

  EnteFile();

  static Future<EnteFile> fromAsset(String pathName, AssetEntity lAsset) async {
    final EnteFile file = EnteFile();
    file.lAsset = lAsset;
    file.localID = lAsset.id;
    file.title = lAsset.title;
    file.deviceFolder = pathName;
    file.location =
        Location(latitude: lAsset.latitude, longitude: lAsset.longitude);
    file.fileType = enteTypeFromAsset(lAsset);
    file.creationTime = AssetEntityService.parseFileCreationTime(lAsset);
    file.modificationTime = lAsset.modifiedDateTime.microsecondsSinceEpoch;
    file.fileSubType = lAsset.subtype;
    file.metadataVersion = kCurrentMetadataVersion;
    return file;
  }

  static EnteFile fromAssetSync(AssetEntity asset) {
    final EnteFile file = EnteFile();
    file.lAsset = asset;
    file.localID = asset.id;
    file.title = asset.title;
    file.deviceFolder = asset.relativePath;
    file.location =
        Location(latitude: asset.latitude, longitude: asset.longitude);
    file.fileType = enteTypeFromAsset(asset);
    file.creationTime = asset.createDateTime.microsecondsSinceEpoch;
    file.modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    file.fileSubType = asset.subtype;
    file.metadataVersion = kCurrentMetadataVersion;
    file.duration = asset.duration;
    return file;
  }

  int get remoteID {
    if (rAsset != null) {
      return rAsset!.id;
    } else {
      throw Exception("Remote ID is not set for the file");
    }
  }

  static EnteFile fromRemoteAsset(
    RemoteAsset rAsset,
    CollectionFile collection, {
    AssetEntity? lAsset,
  }) {
    final EnteFile file = EnteFile();
    file.rAsset = rAsset;
    file.cf = collection;
    file.lAsset = lAsset;

    file.uploadedFileID = rAsset.id;
    file.ownerID = rAsset.ownerID;
    file.title = rAsset.title;
    file.deviceFolder = rAsset.deviceFolder;
    file.location = rAsset.location;
    file.fileType = rAsset.fileType;
    file.creationTime = rAsset.creationTime;
    file.modificationTime = rAsset.modificationTime;
    file.fileSubType = rAsset.subType;
    file.metadataVersion = kCurrentMetadataVersion;
    file.duration = rAsset.durationInSec;
    file.collectionID = collection.collectionID;
    file.pubMagicMetadata =
        PubMagicMetadata.fromMap(rAsset.publicMetadata?.data);
    return file;
  }

  Future<AssetEntity?> get getAsset {
    if (localID == null) {
      return Future.value(null);
    }
    return AssetEntity.fromId(localID!);
  }

  String get downloadUrl =>
      FileUrl.getUrl(uploadedFileID!, FileUrlType.download);

  String? get caption {
    return rAsset?.caption;
  }

  int? get fileSize {
    if (rAsset != null && rAsset!.fileSize != -1) {
      return rAsset!.fileSize;
    }
    return null;
  }

  String get displayName {
    if (rAsset != null) {
      return rAsset!.title;
    }
    if (title == null && kDebugMode) _logger.severe('File title is null');
    return title ?? '';
  }

  // return 0 if the height is not available
  int get height {
    return pubMagicMetadata?.h ?? 0;
  }

  int get width {
    return pubMagicMetadata?.w ?? 0;
  }

  bool get hasDimensions {
    return height != 0 && width != 0;
  }

  // returns true if the file isn't available in the user's gallery
  bool get isRemoteFile {
    return localID == null && isUploaded;
  }

  bool get isUploaded {
    return rAsset != null;
  }

  bool get isSharedMediaToAppSandbox {
    return localID != null && localID!.startsWith(sharedMediaIdentifier);
  }

  bool get hasLocation {
    return location != null &&
        ((location!.longitude ?? 0) != 0 || (location!.latitude ?? 0) != 0);
  }

  @override
  String toString() {
    return '''File(generatedID: $generatedID, localID: $localID, title: $title, 
      type: $fileType, uploadedFileId: $uploadedFileID, modificationTime: $modificationTime, 
      ownerID: $ownerID, collectionID: $collectionID, updationTime: $updationTime)''';
  }

  @override
  bool operator ==(Object o) {
    if (identical(this, o)) return true;

    return o is EnteFile &&
        o.generatedID == generatedID &&
        o.uploadedFileID == uploadedFileID &&
        o.localID == localID;
  }

  @override
  int get hashCode {
    return generatedID.hashCode ^ uploadedFileID.hashCode ^ localID.hashCode;
  }

  String get tag {
    return "local_" +
        localID.toString() +
        ":remote_" +
        uploadedFileID.toString() +
        ":generated_" +
        generatedID.toString();
  }

  String cacheKey() {
    // todo: Neeraj: 19thJuly'22: evaluate and add fileHash as the key?
    return localID ?? uploadedFileID?.toString() ?? generatedID.toString();
  }

  EnteFile copyWith({
    int? generatedID,
    int? uploadedFileID,
    int? ownerID,
    int? collectionID,
    String? localID,
    String? title,
    String? deviceFolder,
    int? creationTime,
    int? modificationTime,
    int? updationTime,
    int? addedTime,
    Location? location,
    FileType? fileType,
    int? fileSubType,
    int? duration,
    String? exif,
    String? hash,
    int? metadataVersion,
    int? fileSize,
    String? pubMmdEncodedJson,
    int? pubMmdVersion,
    PubMagicMetadata? pubMagicMetadata,
  }) {
    return EnteFile()
      ..lAsset = lAsset
      ..rAsset = rAsset
      ..cf = cf
      ..generatedID = generatedID ?? this.generatedID
      ..uploadedFileID = uploadedFileID ?? this.uploadedFileID
      ..ownerID = ownerID ?? this.ownerID
      ..collectionID = collectionID ?? this.collectionID
      ..localID = localID ?? this.localID
      ..title = title ?? this.title
      ..deviceFolder = deviceFolder ?? this.deviceFolder
      ..creationTime = creationTime ?? this.creationTime
      ..modificationTime = modificationTime ?? this.modificationTime
      ..updationTime = updationTime ?? this.updationTime
      ..addedTime = addedTime ?? this.addedTime
      ..location = location ?? this.location
      ..fileType = fileType ?? this.fileType
      ..fileSubType = fileSubType ?? this.fileSubType
      ..duration = duration ?? this.duration
      ..exif = exif ?? this.exif
      ..hash = hash ?? this.hash
      ..metadataVersion = metadataVersion ?? this.metadataVersion
      ..pubMmdEncodedJson = pubMmdEncodedJson ?? this.pubMmdEncodedJson
      ..pubMmdVersion = pubMmdVersion ?? this.pubMmdVersion
      ..pubMagicMetadata = pubMagicMetadata ?? this.pubMagicMetadata;
  }
}
