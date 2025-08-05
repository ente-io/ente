import "dart:typed_data";

import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/location/location.dart";
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/metadata/file_magic.dart";

// Represents the remote asset stored in the database
// Note: Ensure that the fields in this class matches the database schema
// (remote_db -> files table). Keep the field order consistent with the schema.
class RemoteAsset {
  final int id;
  final int ownerID;
  final Uint8List fileHeader;
  final Uint8List thumbHeader;
  final int creationTime;
  final int modificationTime;
  final int type;
  final int subType;
  final String title;
  final int? fileSize;
  final String? hash;

  final int? visibility;
  final int? durationInSec;
  final Location? location;

  final int? height;
  final int? width;
  final int? noThumb;
  final int? sv;
  final int? mediaType;
  final int? motionVideoIndex;

  String? caption;
  final String? uploaderName;

  RemoteAsset({
    required this.id,
    required this.ownerID,
    required this.thumbHeader,
    required this.fileHeader,
    required this.subType,
    required this.type,
    required this.creationTime,
    required this.modificationTime,
    required this.title,
    this.hash,
    this.visibility,
    this.durationInSec,
    this.location,
    this.height,
    this.width,
    this.sv,
    this.motionVideoIndex,
    this.noThumb,
    this.mediaType,
    this.uploaderName,
    this.fileSize,
    this.caption,
  });

  // Factory constructor for creating from metadata (if needed for migration)
  factory RemoteAsset.fromMetadata({
    required int id,
    required int ownerID,
    required Uint8List thumbHeader,
    required Uint8List fileHeader,
    required Metadata metadata,
    Metadata? privateMetadata,
    Metadata? publicMetadata,
    Info? info,
  }) {
    return RemoteAsset(
      id: id,
      ownerID: ownerID,
      thumbHeader: thumbHeader,
      fileHeader: fileHeader,
      creationTime: publicMetadata?.data[editTimeKey] ??
          metadata.data['creationTime'] ??
          0,
      title: publicMetadata?.data[editTimeKey] ?? metadata.data['title'] ?? "",
      modificationTime: metadata.data["modificationTime"] ??
          publicMetadata?.data[editTimeKey] ??
          metadata.data['creationTime'] ??
          0,
      hash: metadata.data['hash'],
      location: RemoteAsset.parseLocation(publicMetadata, metadata),
      durationInSec: metadata.data['duration'] ?? 0,
      fileSize: info?.fileSize,
      subType: metadata.data['subType'] ?? -1,
      type: metadata.data['type'] ?? -1,
      height: safeParseInt(publicMetadata?.data[heightKey], heightKey),
      width: safeParseInt(publicMetadata?.data[widthKey], widthKey),
      sv: publicMetadata?.data[streamVersionKey],
      motionVideoIndex: publicMetadata?.data[motionVideoIndexKey],
      noThumb: publicMetadata?.data[noThumbKey] ??
          metadata.data["hasStaticThumbnail"],
      caption: publicMetadata?.data[captionKey],
      mediaType: publicMetadata?.data[mediaTypeKey],
      uploaderName: publicMetadata?.data[uploaderNameKey],
      visibility: privateMetadata?.data[magicKeyVisibility],
    );
  }

  RemoteAsset copyWith({
    int? id,
    int? ownerID,
    Uint8List? thumbHeader,
    Uint8List? fileHeader,
    int? subType,
    int? type,
    int? creationTime,
    int? modificationTime,
    String? title,
    String? hash,
    int? visibility,
    int? durationInSec,
    Location? location,
    int? height,
    int? width,
    int? sv,
    int? motionVideoIndex,
    int? noThumb,
    int? mediaType,
    String? deviceFolder,
    String? uploaderName,
    int? fileSize,
    String? caption,
  }) {
    return RemoteAsset(
      id: id ?? this.id,
      ownerID: ownerID ?? this.ownerID,
      thumbHeader: thumbHeader ?? this.thumbHeader,
      fileHeader: fileHeader ?? this.fileHeader,
      subType: subType ?? this.subType,
      type: type ?? this.type,
      creationTime: creationTime ?? this.creationTime,
      modificationTime: modificationTime ?? this.modificationTime,
      title: title ?? this.title,
      hash: hash ?? this.hash,
      visibility: visibility ?? this.visibility,
      durationInSec: durationInSec ?? this.durationInSec,
      location: location ?? this.location,
      height: height ?? this.height,
      width: width ?? this.width,
      sv: sv ?? this.sv,
      motionVideoIndex: motionVideoIndex ?? this.motionVideoIndex,
      noThumb: noThumb ?? this.noThumb,
      mediaType: mediaType ?? this.mediaType,
      uploaderName: uploaderName ?? this.uploaderName,
      fileSize: fileSize ?? this.fileSize,
      caption: caption ?? this.caption,
    );
  }

  bool get isArchived {
    return visibility == archiveVisibility;
  }

  FileType get fileType {
    return getFileType(type);
  }

  static Location? parseLocation(Metadata? publicMetadata, Metadata metadata) {
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
}
