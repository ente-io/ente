import "package:photos/core/configuration.dart";
import 'package:photos/models/file/extensions/r_asset_props.dart';
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/services/collections_service.dart";

extension FilePropsExtn on EnteFile {
  bool get isLivePhoto => fileType == FileType.livePhoto;

  bool get isMotionPhoto => rAsset?.isMotionPhoto ?? false;

  bool get isLiveOrMotionPhoto => isLivePhoto || isMotionPhoto;

  bool get isOwner =>
      (ownerID == null) || (ownerID == Configuration.instance.getUserID());

  bool get isVideo => fileType == FileType.video;

  bool get hasDims => height > 0 && width > 0;

  // return true if the file can be a panorama image, null if the dimensions are not available
  bool? isPanorama() {
    if (fileType != FileType.image) {
      return false;
    }
    if (rAsset?.mediaType != null) {
      return (rAsset!.mediaType! & 1) == 1;
    }
    return null;
  }

  bool canBePanorama() {
    if (hasDims) {
      if (height < 8000 && width < 8000) return false;
      if (height > width) {
        return height / width >= 2.0;
      }
      return width / height >= 2.0;
    }
    return false;
  }

  bool get canEditMetaInfo => isUploaded && isOwner;

  bool get isTrash => trashTime != null;

  // Return true if the file was uploaded via collect photos workflow
  bool get isCollect => uploaderName != null;

  String? get uploaderName => rAsset?.uploaderName;

  bool get skipIndex => !isUploaded || fileType == FileType.other;

  bool canReUpload(int userID) =>
      lAsset != null &&
      cf != null &&
      isOwner &&
      (CollectionsService.instance
              .getCollectionByID(cf!.collectionID)
              ?.isOwner(userID) ??
          false);
}
