import "dart:io";

import "package:photo_manager/photo_manager.dart";

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
    ];
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
      id: row['id'] as String,
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
