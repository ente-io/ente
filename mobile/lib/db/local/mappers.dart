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
}
