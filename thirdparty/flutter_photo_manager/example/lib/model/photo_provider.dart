import 'package:flutter/foundation.dart';
import 'package:image_scanner_example/main.dart';

import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  RequestType type = RequestType.common;

  var hasAll = true;

  var onlyAll = false;

  Map<AssetPathEntity, AssetPathProvider> pathProviderMap = {};

  bool _notifying = false;

  bool _needTitle = false;

  bool get needTitle => _needTitle;

  set needTitle(bool? needTitle) {
    if (needTitle == null) {
      return;
    }
    _needTitle = needTitle;
    notifyListeners();
  }

  bool _containsEmptyAlbum = false;

  bool get containsEmptyAlbum => _containsEmptyAlbum;

  set containsEmptyAlbum(bool containsEmptyAlbum) {
    _containsEmptyAlbum = containsEmptyAlbum;
    notifyListeners();
  }

  bool _containsPathModified = false;

  bool get containsPathModified => _containsPathModified;

  set containsPathModified(bool containsPathModified) {
    _containsPathModified = containsPathModified;
    notifyListeners();
  }

  DateTime _startDt = DateTime(2005); // Default Before 8 years

  DateTime get startDt => _startDt;

  set startDt(DateTime startDt) {
    _startDt = startDt;
    notifyListeners();
  }

  DateTime _endDt = DateTime.now();

  DateTime get endDt => _endDt;

  set endDt(DateTime endDt) {
    _endDt = endDt;
    notifyListeners();
  }

  bool _asc = false;

  bool get asc => _asc;

  set asc(bool? asc) {
    if (asc == null) {
      return;
    }
    _asc = asc;
    notifyListeners();
  }

  var _thumbFormat = ThumbFormat.png;

  ThumbFormat get thumbFormat => _thumbFormat;

  set thumbFormat(thumbFormat) {
    _thumbFormat = thumbFormat;
    notifyListeners();
  }

  bool get notifying => _notifying;

  String minWidth = "0";
  String maxWidth = "10000";
  String minHeight = "0";
  String maxHeight = "10000";
  bool _ignoreSize = true;

  bool get ignoreSize => _ignoreSize;

  set ignoreSize(bool? ignoreSize) {
    if (ignoreSize == null) {
      return;
    }
    _ignoreSize = ignoreSize;
    notifyListeners();
  }

  Duration _minDuration = Duration.zero;

  Duration get minDuration => _minDuration;

  set minDuration(Duration minDuration) {
    _minDuration = minDuration;
    notifyListeners();
  }

  Duration _maxDuration = Duration(hours: 1);

  Duration get maxDuration => _maxDuration;

  set maxDuration(Duration maxDuration) {
    _maxDuration = maxDuration;
    notifyListeners();
  }

  set notifying(bool? notifying) {
    if (notifying == null) {
      return;
    }
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(RequestType type) {
    this.type = type;
    notifyListeners();
  }

  void changeHasAll(bool? value) {
    if (value == null) {
      return;
    }
    this.hasAll = value;
    notifyListeners();
  }

  void changeOnlyAll(bool? value) {
    if (value == null) {
      return;
    }
    this.onlyAll = value;
    notifyListeners();
  }

  void changeContainsEmptyAlbum(bool? value) {
    if (value == null) {
      return;
    }
    this.containsEmptyAlbum = value;
    notifyListeners();
  }

  void changeContainsPathModified(bool? value) {
    if (value == null) {
      return;
    }
    this.containsPathModified = value;
  }

  void reset() {
    this.list.clear();
    pathProviderMap.clear();
  }

  Future<void> refreshGalleryList() async {
    final option = makeOption();

    reset();
    var galleryList = await PhotoManager.getAssetPathList(
      type: type,
      hasAll: hasAll,
      onlyAll: onlyAll,
      filterOption: option,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.clear();
    this.list.addAll(galleryList);
  }

  AssetPathProvider getOrCreatePathProvider(AssetPathEntity pathEntity) {
    pathProviderMap[pathEntity] ??= AssetPathProvider(pathEntity);
    return pathProviderMap[pathEntity]!;
  }

  FilterOptionGroup makeOption() {
    final option = FilterOption(
      sizeConstraint: SizeConstraint(
        minWidth: int.tryParse(minWidth) ?? 0,
        maxWidth: int.tryParse(maxWidth) ?? 100000,
        minHeight: int.tryParse(minHeight) ?? 0,
        maxHeight: int.tryParse(maxHeight) ?? 100000,
        ignoreSize: ignoreSize,
      ),
      durationConstraint: DurationConstraint(
        min: minDuration,
        max: maxDuration,
      ),
      needTitle: needTitle,
    );

    final createDtCond = DateTimeCond(
      min: startDt,
      max: endDt,
      ignore: false,
    );

    return FilterOptionGroup()
      ..setOption(AssetType.video, option)
      ..setOption(AssetType.image, option)
      ..setOption(AssetType.audio, option)
      ..createTimeCond = createDtCond
      ..containsEmptyAlbum = _containsEmptyAlbum
      ..containsPathModified = _containsPathModified
      ..addOrderOption(
        OrderOption(
          type: OrderOptionType.updateDate,
          asc: asc,
        ),
      );
  }

  Future<void> refreshAllGalleryProperties() async {
    for (var gallery in list) {
      await gallery.refreshPathProperties();
    }
    notifyListeners();
  }

  void changeThumbFormat() {
    if (thumbFormat == ThumbFormat.jpeg) {
      thumbFormat = ThumbFormat.png;
    } else {
      thumbFormat = ThumbFormat.jpeg;
    }
  }
}

class AssetPathProvider extends ChangeNotifier {
  static const loadCount = 50;

  bool isInit = false;

  final AssetPathEntity path;
  AssetPathProvider(this.path);

  List<AssetEntity> list = [];

  var page = 0;

  int get showItemCount {
    if (list.length == path.assetCount) {
      return path.assetCount;
    } else {
      return path.assetCount;
    }
  }

  bool refreshing = false;

  Future onRefresh() async {
    if (refreshing) {
      return;
    }

    refreshing = true;
    await path.refreshPathProperties(
      maxDateTimeToNow: false,
    );
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength("onRefresh");

    refreshing = false;
  }

  Future<void> onLoadMore() async {
    if (refreshing) {
      return;
    }
    if (showItemCount > path.assetCount) {
      print("already max");
      return;
    }
    final list = await path.getAssetListPaged(page + 1, loadCount);
    page = page + 1;
    this.list.addAll(list);
    notifyListeners();
    printListLength("loadmore");
  }

  void delete(AssetEntity entity) async {
    final result = await PhotoManager.editor.deleteWithIds([entity.id]);
    if (result.isNotEmpty) {
      final rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final list = await path.getAssetListRange(start: 0, end: rangeEnd);
      this.list.clear();
      this.list.addAll(list);
      printListLength("deleted");
    }
  }

  void deleteSelectedAssets(List<AssetEntity> entity) async {
    final ids = entity.map((e) => e.id).toList();
    await PhotoManager.editor.deleteWithIds(ids);
    await path.refreshPathProperties();
    showToast('The path ${path.name} asset count have :${path.assetCount}');
    notifyListeners();
  }

  void removeInAlbum(AssetEntity entity) async {
    if (await PhotoManager.editor.iOS.removeInAlbum(entity, path)) {
      final rangeEnd = this.list.length;
      await provider.refreshAllGalleryProperties();
      final list = await path.getAssetListRange(start: 0, end: rangeEnd);
      this.list.clear();
      this.list.addAll(list);
      printListLength("removeInAlbum");
    }
  }

  void printListLength(String tag) {
    print("$tag length : ${list.length}");
  }
}
