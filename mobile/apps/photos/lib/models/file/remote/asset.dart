import "dart:io";
import "dart:typed_data";

import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/metadata/file_magic.dart";

class RemoteAsset {
  final int id;
  final int ownerID;
  final Uint8List thumbHeader;
  final Uint8List fileHeader;
  final Metadata metadata;
  final Metadata? privateMetadata;
  final Metadata? publicMetadata;
  final Info? info;

  RemoteAsset({
    required this.id,
    required this.ownerID,
    required this.thumbHeader,
    required this.fileHeader,
    required this.metadata,
    required this.privateMetadata,
    required this.publicMetadata,
    required this.info,
  });

  RemoteAsset copyWith({
    int? id,
    int? ownerID,
    Uint8List? thumbHeader,
    Uint8List? fileHeader,
    Metadata? metadata,
    Metadata? privateMetadata,
    Metadata? publicMetadata,
    Info? info,
  }) {
    return RemoteAsset(
      id: id ?? this.id,
      ownerID: ownerID ?? this.ownerID,
      thumbHeader: thumbHeader ?? this.thumbHeader,
      fileHeader: fileHeader ?? this.fileHeader,
      metadata: metadata ?? this.metadata,
      privateMetadata: privateMetadata ?? this.privateMetadata,
      publicMetadata: publicMetadata ?? this.publicMetadata,
      info: info ?? this.info,
    );
  }

  String get title =>
      publicMetadata?.data['editedName'] ?? metadata.data['title'] ?? "";

  String? get localID => metadata.data['localID'];

  String? get matchLocalID => localID == null || deviceFolder == null
      ? null
      : Platform.isIOS
          ? localID
          : '$localID-$deviceFolder-$title';

  bool get isArchived {
    return metadata.data[magicKeyVisibility] == archiveVisibility;
  }

  String? get deviceFolder => metadata.data['deviceFolder'];

  Location? get location {
    if (publicMetadata?.data[latKey] != null) {
      return Location(
        latitude: publicMetadata!.data[latKey],
        longitude: publicMetadata!.data[longKey],
      );
    }
    if (metadata.data['latitude'] == null ||
        metadata.data['longitude'] == null) {
      return null;
    }
    final latitude = double.tryParse(metadata.data["latitude"].toString());
    final longitude = double.tryParse(metadata.data["longitude"].toString());
    if (latitude == null ||
        longitude == null ||
        (latitude == 0.0 && longitude == 0.0)) {
      return null;
    } else {
      return Location(latitude: latitude, longitude: longitude);
    }
  }

  FileType get fileType {
    return getFileType(metadata.data['fileType'] ?? -1);
  }

  int get subType {
    return metadata.data['subType'] ?? -1;
  }

  int get durationInSec => metadata.data['duration'] ?? 0;

  int get creationTime =>
      publicMetadata?.data['editedTime'] ?? metadata.data['creationTime'] ?? 0;

  int get modificationTime => metadata.data['modificationTime'] ?? creationTime;

  // note: during remote to local sync, older live photo hash format from desktop
  // is already converted to the new format
  String? get hash => metadata.data['hash'];

  String? get caption => publicMetadata?.data[captionKey];

  int? get height {
    return publicMetadata?.data[heightKey];
  }

  int? get width {
    return publicMetadata?.data[widthKey];
  }

  void inMemUpdateCaption(String? newCaption) {
    if (publicMetadata == null) {
      return;
    }
    publicMetadata!.data[captionKey] = newCaption;
  }

  int get fileSize => info?.fileSize ?? -1;

  String? get uploaderName {
    return publicMetadata?.data[uploaderNameKey];
  }

  int? get mediaType => publicMetadata?.data[mediaTypeKey];
}
