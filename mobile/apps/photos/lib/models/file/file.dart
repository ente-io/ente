import "dart:core";

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/constants.dart';
import "package:photos/models/api/diff/trash_time.dart";
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/models/local/shared_asset.dart";
import 'package:photos/models/location/location.dart';
import "package:photos/module/download/file_url.dart";
import "package:photos/services/local/asset_entity.service.dart";

//Todo: files with no location data have lat and long set to 0.0. This should ideally be null.
class EnteFile {
  static final _logger = Logger('EnteFile');
  AssetEntity? lAsset;
  RemoteAsset? rAsset;
  CollectionFile? cf;
  TrashTime? trashTime;
  SharedAsset? sharedAsset;

  int? generatedID;
  int? ownerID;

  String? localID;

  String? deviceFolder;
  int? creationTime;
  int? modificationTime;

  late Location? location;
  late FileType fileType;

  // String? hash;

  EnteFile();

  static Future<EnteFile> fromAsset(String pathName, AssetEntity lAsset) async {
    final EnteFile file = EnteFile();
    file.lAsset = lAsset;
    file.localID = lAsset.id;
    file.deviceFolder = pathName;
    file.location =
        Location(latitude: lAsset.latitude, longitude: lAsset.longitude);
    file.fileType = enteTypeFromAsset(lAsset);
    file.creationTime = AssetEntityService.estimateCreationTime(lAsset);
    file.modificationTime = lAsset.modifiedDateTime.microsecondsSinceEpoch;
    return file;
  }

  static EnteFile fromAssetSync(AssetEntity asset) {
    final EnteFile file = EnteFile();
    file.lAsset = asset;
    file.localID = asset.id;
    file.deviceFolder = asset.relativePath;
    file.location =
        Location(latitude: asset.latitude, longitude: asset.longitude);
    file.fileType = enteTypeFromAsset(asset);
    file.creationTime = asset.createDateTime.microsecondsSinceEpoch;
    file.modificationTime = asset.modifiedDateTime.microsecondsSinceEpoch;
    return file;
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
    file.ownerID = rAsset.ownerID;
    // file.deviceFolder = rAsset.deviceFolder;
    file.location = rAsset.location;
    file.fileType = rAsset.fileType;
    file.creationTime = rAsset.creationTime;
    file.modificationTime = rAsset.modificationTime;
    return file;
  }

  int get remoteID {
    if (rAsset != null) {
      return rAsset!.id;
    } else {
      throw Exception("Remote ID is not set for the file");
    }
  }

  String? get hash => rAsset?.hash;

  int? get fileSubType => rAsset?.subType ?? lAsset?.subtype;

  int? get uploadedFileID => rAsset?.id;

  int? get durationInSec => rAsset?.durationInSec ?? lAsset?.duration;

  String? get title => rAsset?.title ?? lAsset?.title;

  int? get collectionID => cf?.collectionID;

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
    if (rAsset != null) {
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
    if (rAsset != null) {
      return rAsset!.height ?? 0;
    }
    return lAsset?.height ?? 0;
  }

  int get width {
    if (rAsset != null) {
      return rAsset!.width ?? 0;
    }
    return lAsset?.width ?? 0;
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
      ownerID: $ownerID, collectionID: $collectionID, updationTime: ${cf?.updatedAt})''';
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
    int? ownerID,
    String? localID,
    String? deviceFolder,
    int? creationTime,
    int? modificationTime,
    int? updationTime,
    Location? location,
    FileType? fileType,
    int? metadataVersion,
    int? fileSize,
  }) {
    return EnteFile()
      ..lAsset = lAsset
      ..rAsset = rAsset
      ..cf = cf
      ..generatedID = generatedID ?? this.generatedID
      ..ownerID = ownerID ?? this.ownerID
      ..localID = localID ?? this.localID
      ..deviceFolder = deviceFolder ?? this.deviceFolder
      ..creationTime = creationTime ?? this.creationTime
      ..modificationTime = modificationTime ?? this.modificationTime
      ..location = location ?? this.location
      ..fileType = fileType ?? this.fileType;
  }
}
