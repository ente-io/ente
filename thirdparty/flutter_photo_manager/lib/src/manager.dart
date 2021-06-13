part of '../photo_manager.dart';

Plugin _plugin = Plugin();

/// use the class method to help user load asset list and asset info.
///
/// 这个类是整个库的核心类
class PhotoManager {
  /// in android WRITE_EXTERNAL_STORAGE  READ_EXTERNAL_STORAGE
  ///
  /// in ios request the photo permission
  ///
  /// Use [requestPermissionExtend] to instead;
  // @Deprecated("Use requestPermissionExtend")
  static Future<bool> requestPermission() async {
    return (await requestPermissionExtend()).isAuth;
  }

  /// Android: WRITE_EXTERNAL_STORAGE, READ_EXTERNAL_STORAGE, MEDIA_LOCATION
  ///
  /// iOS: NSPhotoLibraryUsageDescription of info.plist
  ///
  /// macOS of Release.entitlements:
  ///  - com.apple.security.assets.movies.read-write
  ///  - com.apple.security.assets.music.read-write
  ///
  /// Also see [PermissionState].
  static Future<PermissionState> requestPermissionExtend({
    PermisstionRequestOption requestOption = const PermisstionRequestOption(),
  }) async {
    final int resultIndex =
        await _plugin.requestPermissionExtend(requestOption);
    return PermissionState.values[resultIndex];
  }

  /// Prompts the user to update their limited library selection.
  ///
  /// This method just support iOS(14.0+).
  ///
  /// See document of [Apple doc][].
  ///
  /// [Apple doc]: https://developer.apple.com/documentation/photokit/phphotolibrary/3616113-presentlimitedlibrarypickerfromv/
  static Future<void> presentLimited() async {
    await _plugin.presentLimited();
  }

  static Editor editor = Editor();

  /// get gallery list
  ///
  /// 获取相册"文件夹" 列表
  ///
  /// [hasAll] contains all path, such as "Camera Roll" on ios or "Recent" on android.
  /// [hasAll] 包含所有项目的相册
  ///
  /// [onlyAll] If true, Return only one album with all resources.
  /// [onlyAll] 如果为真, 则只返回一个包含所有项目的相册
  static Future<List<AssetPathEntity>> getAssetPathList({
    bool hasAll = true,
    bool onlyAll = false,
    RequestType type = RequestType.common,
    FilterOptionGroup? filterOption,
  }) async {
    if (onlyAll) {
      assert(hasAll, "If only is true, then the hasAll must be not null.");
    }
    filterOption ??= FilterOptionGroup();

    assert(
        type.index != 0, 'The request type must have video, image or audio.');

    if (type.index == 0) {
      return [];
    }

    return _plugin.getAllGalleryList(
      type: type.index,
      hasAll: hasAll,
      onlyAll: onlyAll,
      optionGroup: filterOption,
    );
  }

  /// Use [getAssetPathList] replaced.
  @Deprecated("Use getAssetPathList replaced.")
  static Future<List<AssetPathEntity>> getImageAsset() {
    return getAssetPathList(type: RequestType.image);
  }

  /// Use [getAssetPathList] replaced.
  @Deprecated("Use getAssetPathList replaced.")
  static Future<List<AssetPathEntity>> getVideoAsset() {
    return getAssetPathList(type: RequestType.video);
  }

  static Future<void> setLog(bool isLog) {
    return _plugin.setLog(isLog);
  }

  /// Ignore permission checks at runtime, you can use third-party permission plugins to request permission. Default is false.
  ///
  /// For Android, a typical usage scenario may be to use it in Service, because Activity cannot be used in Service to detect runtime permissions, but it should be noted that deleting resources above android10 require activity to accept the result, so the delete system does not apply to this Attributes.
  ///
  /// For iOS, this feature is only added, please explore the specific application scenarios by yourself
  static Future<void> setIgnorePermissionCheck(bool ignore) async {
    await _plugin.ignorePermissionCheck(ignore);
  }

  /// get video asset
  /// open setting page
  static void openSetting() {
    _plugin.openSetting();
  }

  static Future<List<AssetEntity>> _getAssetListPaged(
    AssetPathEntity entity,
    int page,
    int pageCount,
  ) async {
    return _plugin.getAssetWithGalleryIdPaged(
      entity.id,
      page: page,
      pageCount: pageCount,
      type: entity.typeInt,
      optionGroup: entity.filterOption,
    );
  }

  static Future<List<AssetEntity>> _getAssetWithRange({
    required AssetPathEntity entity,
    required int start,
    required int end,
  }) {
    if (end > entity.assetCount) {
      end = entity.assetCount;
    }
    return _plugin.getAssetWithRange(
      entity.id,
      typeInt: entity.typeInt,
      start: start,
      end: end,
      optionGroup: entity.filterOption,
    );
  }

  /// Release all native(ios/android) caches, normally no calls are required.
  ///
  /// The main purpose is to help clean up problems where memory usage may be too large when there are too many pictures.
  ///
  /// Warning:
  ///
  ///   Once this method is invoked, unless you call the [getAssetPathList] method again, all the [AssetEntity] and [AssetPathEntity] methods/fields you have acquired will fail or produce unexpected results.
  ///
  ///   This method should only be invoked when you are sure you really want to do so.
  ///
  ///   This method is asynchronous, and calling [getAssetPathList] before the Future of this method returns causes an error.
  ///
  ///
  /// 释放资源的方法,一般情况下不需要调用
  ///
  /// 主要目的是帮助清理当图片过多时,内存占用可能过大的问题
  ///
  /// 警告:
  ///
  /// 一旦调用这个方法,除非你重新调用  [getAssetPathList] 方法,否则你已经获取的所有[AssetEntity]/[AssetPathEntity]的所有字段都将失效或产生无法预期的效果
  ///
  /// 这个方法应当只在你确信你真的需要这么做的时候再调用
  ///
  /// 这个方法是异步的,在本方法的Future返回前调用getAssetPathList 可能会产生错误
  static Future releaseCache() async {
    await _plugin.releaseCache();
  }

  /// Notification class for managing photo changes.
  static _NotifyManager _notifyManager = _NotifyManager();

  /// see [_NotifyManager]
  static void addChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.addCallback(callback);

  /// see [_NotifyManager]
  static void removeChangeCallback(ValueChanged<MethodCall> callback) =>
      _notifyManager.removeCallback(callback);

  /// see [_NotifyManager]
  static void startChangeNotify() => _notifyManager.startHandleNotify();

  /// see [_NotifyManager]
  static void stopChangeNotify() => _notifyManager.stopHandleNotify();

  static Future<File?> _getFileWithId(
    String id, {
    bool isOrigin = false,
    PMProgressHandler? progressHandler,
  }) async {
    if (Platform.isIOS || Platform.isMacOS || Platform.isAndroid) {
      final path = await _plugin.getFullFile(
        id,
        isOrigin: isOrigin,
        progressHandler: progressHandler,
      );
      if (path == null) {
        return null;
      }
      return File(path);
    }
    return null;
  }

  static Future<Uint8List?> _getFullDataWithId(String id) async {
    return _plugin.getOriginBytes(id);
  }

  static _getThumbDataWithOption(
    String id,
    ThumbOption option,
    PMProgressHandler? progressHandler,
  ) {
    return _plugin.getThumb(
      id: id,
      option: option,
      progressHandler: progressHandler,
    );
  }

  static Future<bool> _assetExistsWithId(String id) {
    return _plugin.assetExistsWithId(id);
  }

  /// [AssetPathEntity.refreshPathProperties]
  static Future<AssetPathEntity?> fetchPathProperties({
    required AssetPathEntity entity,
    required FilterOptionGroup filterOptionGroup,
  }) async {
    final result = await _plugin.fetchPathProperties(
      entity.id,
      entity.typeInt,
      entity.filterOption,
    );
    if (result == null) {
      return null;
    }
    final list = result["data"];
    if (list is List && list.isNotEmpty) {
      return ConvertUtils.convertPath(
        result,
        type: entity.typeInt,
        optionGroup: entity.filterOption,
      )[0];
    } else {
      return null;
    }
  }

  /// Only valid for Android 29. The API of API 28 must be used with the property of `requestLegacyExternalStorage`.
  static Future<void> forceOldApi() async {
    await _plugin.forceOldApi();
  }

  static Future<bool> _isAndroidQ() async {
    if (!Platform.isAndroid) {
      return false;
    }
    final systemVersion = await _plugin.getSystemVersion();
    return int.parse(systemVersion) >= 29;
  }

  /// Get system version
  static Future<String> systemVersion() async {
    return _plugin.getSystemVersion();
  }

  /// Clear all file cache.
  static Future<void> clearFileCache() async {
    await _plugin.clearFileCache();
  }

  /// When set to true, origin bytes in Android Q will be cached as a file. When use again, the file will be read.
  static Future<bool> setCacheAtOriginBytes(bool cache) =>
      _plugin.cacheOriginBytes(cache);

  static Future<Uint8List?> _getOriginBytes(
    AssetEntity assetEntity, {
    PMProgressHandler? progressHandler,
  }) async {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    if (Platform.isAndroid) {
      if (await _isAndroidQ()) {
        return _plugin.getOriginBytes(
          assetEntity.id,
          progressHandler: progressHandler,
        );
      } else {
        return (await assetEntity.originFile)?.readAsBytes();
      }
    } else if (Platform.isIOS || Platform.isMacOS) {
      final file = await assetEntity.originFile;
      return file?.readAsBytes();
    }
    return null;
  }

  static Future<String?> _getMediaUrl(AssetEntity assetEntity) {
    assert(Platform.isAndroid || Platform.isIOS || Platform.isMacOS);
    return _plugin.getMediaUrl(assetEntity);
  }

  static Future<List<AssetPathEntity>> _getSubPath(
      AssetPathEntity assetPathEntity) {
    assert(Platform.isIOS || Platform.isMacOS);
    return _plugin.getSubPathEntities(assetPathEntity);
  }

  /// Refresh the property of asset.
  static Future<AssetEntity?> refreshAssetProperties(String id) async {
    final Map? map = await _plugin.getPropertiesFromAssetEntity(id);

    final asset = ConvertUtils.convertToAsset(map);

    if (asset == null) {
      return null;
    }

    return asset;
  }
}
