import "dart:io";

import "package:photo_manager/photo_manager.dart";
import "package:photos/models/file/file.dart";

class LocalDBMappers {
  const LocalDBMappers._();

  static List<Object?> assetsRow(AssetEntity entity) {
    return [
      entity.id,
      entity.type.index,
      entity.subtype,
      entity.width,
      entity.height,
      entity.duration,
      entity.orientation,
      entity.isFavorite ? 1 : 0,
      entity.title,
      entity.relativePath,
      entity.createDateTime.microsecondsSinceEpoch,
      entity.modifiedDateTime.microsecondsSinceEpoch,
      entity.mimeType,
      entity.latitude,
      entity.longitude,
      0, // scan_state
    ];
  }

  static AssetEntity asset(Map<String, dynamic> row) {
    return AssetEntity(
      id: row['id'] as String,
      typeInt: row['type'] as int,
      subtype: row['sub_type'] as int,
      width: row['width'] as int,
      height: row['height'] as int,
      duration: row['duration_in_sec'] as int,
      orientation: row['orientation'] as int,
      isFavorite: (row['is_fav'] as int) == 1,
      title: row['title'] as String?,
      relativePath: row['relative_path'] as String?,
      createDateSecond: (row['created_at'] as int),
      modifiedDateSecond: (row['modified_at'] as int),
      mimeType: row['mime_type'] as String?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
    );
  }

  static EnteFile assetRowToEnteFile(Map<String, dynamic> row) {
    final asset = AssetEntity(
      id: row['id'] as String,
      typeInt: row['type'] as int,
      subtype: row['sub_type'] as int,
      width: row['width'] as int,
      height: row['height'] as int,
      duration: row['duration_in_sec'] as int,
      orientation: row['orientation'] as int,
      isFavorite: (row['is_fav'] as int) == 1,
      title: row['title'] as String?,
      relativePath: row['relative_path'] as String?,
      createDateSecond: (row['created_at'] as int) ~/ 1000000,
      modifiedDateSecond: (row['modified_at'] as int) ~/ 1000000,
      mimeType: row['mime_type'] as String?,
      latitude: row['latitude'] as double?,
      longitude: row['longitude'] as double?,
    );
    return EnteFile.fromAssetSync(asset);
  }

  static List<Object?> devicePathRow(AssetPathEntity entity) {
    return [
      entity.id,
      entity.name,
      entity.albumType,
      entity.albumTypeEx?.darwin?.type?.index,
      entity.albumTypeEx?.darwin?.subtype?.index,
    ];
  }

  static AssetPathEntity assetPath(Map<String, dynamic> row) {
    return AssetPathEntity(
      id: row['path_id'] as String,
      name: row['name'] as String,
      albumType: row['album_type'] as int,
      albumTypeEx: AlbumType(
        darwin: !Platform.isAndroid
            ? DarwinAlbumType(
                type: PMDarwinAssetCollectionTypeExt.fromValue(
                  row['ios_album_type'] as int?,
                ),
                subtype: PMDarwinAssetCollectionSubtypeExt.fromValue(
                  row['darwin_subtype'] as int?,
                ),
              )
            : null,
      ),
    );
  }
}
