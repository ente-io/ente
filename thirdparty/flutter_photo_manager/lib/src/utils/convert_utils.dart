import 'package:photo_manager/photo_manager.dart';

class ConvertUtils {
  static List<AssetPathEntity> convertPath(
    Map data, {
    int type = 0,
    FilterOptionGroup? optionGroup,
  }) {
    List<AssetPathEntity> result = [];

    List list = data["data"];

    for (final Map item in list) {
      final entity = AssetPathEntity()
        ..id = item["id"]
        ..name = item["name"]
        ..typeInt = type
        ..isAll = item["isAll"]
        ..assetCount = item["length"]
        ..albumType = (item["albumType"] ?? 1)
        ..filterOption = optionGroup ?? FilterOptionGroup();

      final int? modifiedDate = item['modified'];

      if (modifiedDate != null) {
        entity.lastModified =
            DateTime.fromMillisecondsSinceEpoch(modifiedDate * 1000);
      }

      result.add(entity);
    }

    return result;
  }

  static List<AssetEntity> convertToAssetList(Map data) {
    List<AssetEntity> result = [];

    List list = data["data"];
    for (final Map item in list) {
      final asset = _convertMapToAsset(item);
      if (asset != null) {
        result.add(asset);
      }
    }

    return result;
  }

  static AssetEntity? convertToAsset(Map? map) {
    final Map? data = map?['data'];
    if (data == null) {
      return null;
    }

    return _convertMapToAsset(data);
  }

  static AssetEntity? _convertMapToAsset(Map? data) {
    if (data == null) {
      return null;
    }

    final result = AssetEntity(
      id: data['id'],
      typeInt: data['type'],
      width: data['width'],
      height: data['height'],
      duration: data['duration'] ?? 0,
      orientation: data['orientation'] ?? 0,
      isFavorite: data['favorite'] ?? false,
      title: data['title'],
      createDtSecond: data['createDt'],
      modifiedDateSecond: data['modifiedDt'],
      relativePath: data['relativePath'],
      latitude: data['lat'],
      longitude: data['lng'],
      mimeType: data['mimeType'],
    );

    return result;
  }
}
