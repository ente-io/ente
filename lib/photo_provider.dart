import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import 'main.dart';

class PhotoProvider extends ChangeNotifier {
  List<AssetPathEntity> list = [];

  RequestType type = RequestType.all;

  DateTime dt = DateTime.now();

  var hasAll = true;

  var onlyAll = false;

  Map<AssetPathEntity, PathProvider> pathProviderMap = {};

  bool _notifying = false;

  bool _needTitle = false;

  bool get needTitle => _needTitle;

  set needTitle(bool needTitle) {
    _needTitle = needTitle;
    notifyListeners();
  }

  bool get notifying => _notifying;

  Duration _minDuration = Duration(seconds: 10);

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

  set notifying(bool notifying) {
    _notifying = notifying;
    notifyListeners();
  }

  void changeType(RequestType type) {
    this.type = type;
    notifyListeners();
  }

  void changeHasAll(bool value) {
    this.hasAll = value;
    notifyListeners();
  }

  void changeOnlyAll(bool value) {
    this.onlyAll = value;
    notifyListeners();
  }

  void changeDateToNow() {
    this.dt = DateTime.now();
    notifyListeners();
  }

  void changeDate(DateTime pickDt) {
    this.dt = pickDt;
    notifyListeners();
  }

  void reset() {
    this.list.clear();
    pathProviderMap.clear();
  }

  Future<void> refreshGalleryList() async {
    reset();
    var result = await PhotoManager.requestPermission();
    if (!result) {
      print("Did not get permission");
    }
    final filterOptionGroup = FilterOptionGroup();
    filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
    var galleryList = await PhotoManager.getAssetPathList(
        type: RequestType.image, filterOption: filterOptionGroup);

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.clear();
    this.list.addAll(galleryList);
  }

  Future<void> refreshAllGalleryProperties() async {
    for (var gallery in list) {
      await gallery.refreshPathProperties();
    }
    notifyListeners();
  }

  PathProvider getOrCreatePathProvider(AssetPathEntity pathEntity) {
    pathProviderMap[pathEntity] ??= PathProvider(pathEntity);
    return pathProviderMap[pathEntity];
  }
}

class PathProvider extends ChangeNotifier {
  static const loadCount = 50;

  bool isInit = false;

  final AssetPathEntity path;
  PathProvider(this.path);

  List<AssetEntity> list = [];

  var page = 0;

  int get showItemCount {
    if (list.length == path.assetCount) {
      return path.assetCount;
    } else {
      return path.assetCount;
    }
  }

  Future onRefresh() async {
    final list = await path.getAssetListPaged(0, loadCount);
    page = 0;
    this.list.clear();
    this.list.addAll(list);
    isInit = true;
    notifyListeners();
    printListLength("onRefresh");
  }

  Future<void> onLoadMore() async {
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
      await Future.delayed(Duration(seconds: 3));
      await provider.refreshAllGalleryProperties();
      final list =
          await path.getAssetListRange(start: 0, end: this.list.length);
      printListLength("deleted");
      this.list.clear();
      this.list.addAll(list);
    }
  }

  void printListLength(String tag) {
    print("$tag length : ${list.length}");
  }
}
