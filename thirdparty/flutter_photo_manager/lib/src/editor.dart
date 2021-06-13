part of '../photo_manager.dart';

class Editor {
  final _iOS = IosEditor();
  final _android = AndroidEditor();

  IosEditor get iOS {
    assert(Platform.isIOS, "the iOS editor just use in iOS.");
    return _iOS;
  }

  AndroidEditor get android {
    assert(Platform.isAndroid, "the android editor just use in android.");
    return _android;
  }

  /// All assets will be deleted. On iOS, assets in all albums will be deleted, not just the gallery you selected.
  Future<List<String>> deleteWithIds(List<String> ids) async {
    return _plugin.deleteWithIds(ids);
  }

  /// Save image to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is Picture.
  /// On Android 28 or lower, if the file is located in the external storage, it's path will be used in the MediaStore.
  /// On Android 29 or above, you can use [relativePath] to specify a RELATIVE_PATH used in the MediaStore.
  /// The mimeType will either be formed from the title if you pass one, or guessed by the system, which does not always work.
  Future<AssetEntity?> saveImage(
    Uint8List data, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    return _plugin.saveImage(data,
        title: title, desc: desc, relativePath: relativePath);
  }

  /// Save image to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is picture directory.
  /// On Android 28 or lower, if the file is located in the external storage, it's path will be used in the MediaStore.
  /// On Android 29 or above, you can use [relativePath] to specify a RELATIVE_PATH used in the MediaStore.
  Future<AssetEntity?> saveImageWithPath(
    String path, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    return _plugin.saveImageWithPath(
      path,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }

  /// Save video to gallery.
  ///
  /// in iOS is Recent.
  /// in Android is video directory.
  /// On Android 28 or lower, if the file is located in the external storage, it's path will be used in the MediaStore.
  /// On Android 29 or above, you can use [relativePath] to specify a RELATIVE_PATH used in the MediaStore.
  Future<AssetEntity?> saveVideo(
    File file, {
    String? title,
    String? desc,
    String? relativePath,
  }) async {
    return _plugin.saveVideo(
      file,
      title: title,
      desc: desc,
      relativePath: relativePath,
    );
  }

  /// Copy asset to another gallery.
  ///
  /// In iOS, just something similar to a shortcut, it points to the same asset.
  /// In android, the asset file will produce a copy.
  Future<AssetEntity?> copyAssetToPath({
    required AssetEntity asset,
    required AssetPathEntity pathEntity,
  }) {
    return _plugin.copyAssetToGallery(asset, pathEntity);
  }
}

/// For iOS
class IosEditor {
  /// [name] The folder name.
  ///
  /// [parent] is nullable, if it's null, the folder will be create in root. If isn't null, the [AssetPathEntity.albumType] must be 2.
  /// The only exception, Recent can be specified, but the same as null.
  Future<AssetPathEntity?> createFolder(
    String name, {
    AssetPathEntity? parent,
  }) async {
    if (parent == null || parent.isAll) {
      return _plugin.iosCreateFolder(name, true, null);
    } else {
      if (parent.albumType == 1) {
        assert(parent.albumType == 1, "The folder can't add");
        return null;
      }
      return _plugin.iosCreateFolder(name, false, parent);
    }
  }

  /// if [parent] is null, the album will be added in root.
  Future<AssetPathEntity?> createAlbum(
    String name, {
    AssetPathEntity? parent,
  }) async {
    if (parent == null || parent.isAll) {
      return _plugin.iosCreateAlbum(name, true, null);
    } else {
      if (parent.albumType == 1) {
        assert(parent.albumType == 1, "The folder can't add");
        return null;
      }
      return _plugin.iosCreateAlbum(name, false, parent);
    }
  }

  /// The [entity] and [path] isn't null.
  Future<bool> removeInAlbum(AssetEntity entity, AssetPathEntity path) async {
    if (path.albumType == 2 || path.isAll) {
      assert(path.albumType == 1, "The path must is album");
      assert(
        !path.isAll,
        "The ${path.name}'s asset can't be remove. Use PhotoManager.editor.deleteAsset",
      );
      return false;
    }
    return _plugin.iosRemoveInAlbum([entity], path);
  }

  /// Remove [list]'s items from [path] in batches.
  Future<bool> removeAssetsInAlbum(
    List<AssetEntity> list,
    AssetPathEntity path,
  ) async {
    if (list.isEmpty) {
      return false;
    }
    if (path.albumType == 2 || path.isAll) {
      assert(path.albumType == 1, "The path must is album");
      assert(
        !path.isAll,
        "The ${path.name} can't be remove. Use PhotoManager.editor.deleteAsset",
      );
      return false;
    }
    return _plugin.iosRemoveInAlbum(list, path);
  }

  /// Delete the [path].
  Future<bool> deletePath(AssetPathEntity path) async {
    return _plugin.iosDeleteCollection(path);
  }

  Future<bool> favoriteAsset({
    required AssetEntity entity,
    required bool favorite,
  }) async {
    final result = await _plugin.favoriteAsset(entity.id, favorite);
    if (result) {
      entity.isFavorite = favorite;
    }
    return result;
  }
}

class AndroidEditor {
  Future<bool> moveAssetToAnother({
    required AssetEntity entity,
    required AssetPathEntity target,
  }) async {
    if (!Platform.isAndroid) {
      assert(Platform.isAndroid);
      return false;
    }

    return _plugin.androidMoveAssetToPath(entity, target);
  }

  Future<bool> removeAllNoExistsAsset() async {
    assert(Platform.isAndroid);
    if (!Platform.isAndroid) {
      return false;
    }
    return _plugin.androidRemoveNoExistsAssets();
  }
}
