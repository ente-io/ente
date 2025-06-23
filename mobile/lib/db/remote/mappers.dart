import "dart:typed_data";

import "package:photos/models/api/diff/diff.dart";
import "package:photos/models/api/diff/trash_time.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/file/remote/collection_file.dart";
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

EnteFile trashRowToEnteFile(Map<String, Object?> row) {
  final RemoteAsset asset = fromRow(row);
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
