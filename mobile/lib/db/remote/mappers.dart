import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/rl_mapping.dart";

RemoteAsset fromRow(Map<String, dynamic> row) {
  final metadata = Metadata.fromEncodedJson(row['metadata']);
  final privateMetadata = Metadata.fromEncodedJson(row['pri_metadata']);
  final publicMetadata = Metadata.fromEncodedJson(row['pub_metadata']);
  final info = Info.fromEncodedJson(row['info']);
  return RemoteAsset(
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

RLMapping rowToUploadLocalMapping(Map<String, Object?> row) {
  return RLMapping(
    remoteUploadID: row['file_id'] as int,
    localID: row['local_id'] as String,
    localCloudID: row['local_clould_id'] as String?,
    mappingType:
        MappingTypeExtension.fromName(row['local_mapping_src'] as String),
  );
}
