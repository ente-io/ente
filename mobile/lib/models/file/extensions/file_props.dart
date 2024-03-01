import "package:photos/core/configuration.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/services/collections_service.dart";

extension FilePropsExtn on EnteFile {
  bool get isLivePhoto => fileType == FileType.livePhoto;

  bool get isMotionPhoto => (pubMagicMetadata?.mvi ?? 0) > 0;

  bool get isLiveOrMotionPhoto => isLivePhoto || isMotionPhoto;

  bool get isOwner =>
      (ownerID == null) || (ownerID == Configuration.instance.getUserID());

  bool get canEditMetaInfo => isUploaded && isOwner;

  bool get isTrash => this is TrashFile;

  // Return true if the file was uploaded via collect photos workflow
  bool get isCollect => uploaderName != null;

  String? get uploaderName => pubMagicMetadata?.uploaderName;

  bool canReUpload(int userID) =>
      localID != null &&
      localID!.isNotEmpty &&
      isOwner &&
      collectionID != null &&
      (CollectionsService.instance
              .getCollectionByID(collectionID!)
              ?.isOwner(userID) ??
          false);
}
