import "dart:typed_data";

import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/diff/trash_time.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
import "package:photos/models/file/remote/rl_mapping.dart";
import "package:photos/models/location/location.dart";

RemoteAsset fromTrashRow(Map<String, dynamic> row) {
  final metadata = Metadata.fromEncodedJson(row['metadata']);
  final privateMetadata = Metadata.fromEncodedJson(row['priv_metadata']);
  final publicMetadata = Metadata.fromEncodedJson(row['pub_metadata']);
  final info = Info.fromEncodedJson(row['info']);
  return RemoteAsset.fromMetadata(
    id: row['id'],
    ownerID: row['owner_id'],
    thumbHeader: row['thumb_header'],
    fileHeader: row['file_header'],
    metadata: metadata!,
    privateMetadata: privateMetadata,
    publicMetadata: publicMetadata,
    info: info,
  );
}

List<Object?> remoteAssetToRow(RemoteAsset asset) {
  return [
    asset.id,
    asset.ownerID,
    asset.fileHeader,
    asset.thumbHeader,
    asset.creationTime,
    asset.modificationTime,
    asset.type,
    asset.subType,
    asset.title,
    asset.fileSize,
    asset.hash,
    asset.visibility,
    asset.durationInSec,
    asset.location?.latitude,
    asset.location?.longitude,
    asset.height,
    asset.width,
    asset.noThumb,
    asset.sv,
    asset.mediaType,
    asset.motionVideoIndex,
    asset.caption,
    asset.uploaderName,
  ];
}

RemoteAsset fromFilesRow(Map<String, Object?> row) {
  return RemoteAsset(
    id: row['id'] as int,
    ownerID: row['owner_id'] as int,
    thumbHeader: row['thumb_header'] as Uint8List,
    fileHeader: row['file_header'] as Uint8List,
    creationTime: row['creation_time'] as int,
    modificationTime: row['modification_time'] as int,
    type: row['type'] as int,
    subType: row['subtype'] as int,
    title: row['title'] as String,
    fileSize: row['size'] as int?,
    hash: row['hash'] as String?,
    visibility: row['visibility'] as int?,
    durationInSec: row['durationInSec'] as int?,
    location: Location(
      latitude: (row['lat'] as num?)?.toDouble(),
      longitude: (row['lng'] as num?)?.toDouble(),
    ),
    height: row['height'] as int?,
    width: row['width'] as int?,
    noThumb: row['no_thumb'] as int?,
    sv: row['sv'] as int?,
    mediaType: row['media_type'] as int?,
    motionVideoIndex: row['motion_video_index'] as int?,
    caption: row['caption'] as String?,
    uploaderName: row['uploader_name'] as String?,
  );
}

RLMapping rowToUploadLocalMapping(Map<String, Object?> row) {
  return RLMapping(
    remoteUploadID: row['file_id'] as int,
    localID: row['local_id'] as String,
    localCloudID: row['local_cloud_id'] as String?,
    mappingType:
        MappingTypeExtension.fromName(row['local_mapping_src'] as String),
  );
}

EnteFile trashRowToEnteFile(Map<String, Object?> row) {
  final RemoteAsset asset = fromTrashRow(row);
  final TrashTime time = TrashTime(
    createdAt: row['created_at'] as int,
    updatedAt: row['updated_at'] as int,
    deleteBy: row['delete_by'] as int,
  );
  final cf = CollectionFile(
    fileID: asset.id,
    collectionID: row['collection_id'] as int,
    encFileKey: row['enc_key'] as Uint8List,
    encFileKeyNonce: row['enc_key_nonce'] as Uint8List,
    updatedAt: time.updatedAt,
    createdAt: time.createdAt,
  );
  final file = EnteFile.fromRemoteAsset(asset, cf);
  file.trashTime = time;
  return file;
}
