import 'package:photo_manager/photo_manager.dart';

class PhotoProvider {
  PhotoProvider._privateConstructor();
  static final PhotoProvider instance = PhotoProvider._privateConstructor();

  List<AssetPathEntity> list = [];

  Future<void> refreshGalleryList(
      final int fromTimestamp, final int toTimestamp) async {
    var result = await PhotoManager.requestPermission();
    if (!result) {
      print("Did not get permission");
    }
    final filterOptionGroup = FilterOptionGroup();
    filterOptionGroup.setOption(AssetType.image, FilterOption(needTitle: true));
    filterOptionGroup.dateTimeCond = DateTimeCond(
      min: DateTime.fromMicrosecondsSinceEpoch(fromTimestamp),
      max: DateTime.fromMicrosecondsSinceEpoch(toTimestamp),
    );
    var galleryList = await PhotoManager.getAssetPathList(
      hasAll: true,
      type: RequestType.image,
      filterOption: filterOptionGroup,
    );

    galleryList.sort((s1, s2) {
      return s2.assetCount.compareTo(s1.assetCount);
    });

    this.list.clear();
    this.list.addAll(galleryList);
  }
}
