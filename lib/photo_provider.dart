import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoProvider extends ChangeNotifier {
  PhotoProvider._privateConstructor();
  static final PhotoProvider instance = PhotoProvider._privateConstructor();

  List<AssetPathEntity> list = [];

  Future<void> refreshGalleryList() async {
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
}
