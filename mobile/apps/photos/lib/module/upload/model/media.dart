import "dart:io";
import "dart:typed_data";

import "package:photo_manager/photo_manager.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/local/shared_asset.dart";

// UploadMedia holds information about the actual media that's being uploaded.
// Apart from hash, this doesn't contain any metadata that will be reported to the server
// as part of the upload request. The metadata is handled separately in the UploadData class.
class UploadMedia {
  final File uploadFile;
  final FileType fileType;
  final Uint8List? thumbnail;
  final bool isDeleted;
  final String hash;
  final String? livePhotoImage;
  final String? livePhotoVideo;
  final AssetEntity? localAsset;
  final SharedAsset? sharedAsset;

  UploadMedia(
    this.uploadFile,
    this.thumbnail,
    this.isDeleted,
    this.fileType,
    this.hash, {
    this.livePhotoVideo,
    this.livePhotoImage,
    this.localAsset,
    this.sharedAsset,
  })  : assert(
          (localAsset != null && sharedAsset == null) ||
              (localAsset == null && sharedAsset != null),
          'Either localAsset or sharedAsset must be present, but not both',
        ),
        assert(
          fileType == FileType.livePhoto
              ? (livePhotoImage != null && livePhotoVideo != null)
              : (livePhotoImage == null && livePhotoVideo == null),
          'For live photos, both livePhotoImage and livePhotoVideo must be present. For other file types, both must be null',
        );

  // delete the original file that's fetched from the device. Also, clean up
  // the shared asset if the file is already uploaded.
  Future<void> delete() async {
    if (uploadFile.existsSync() && (Platform.isIOS || sharedAsset != null)) {
      await uploadFile.delete();
    }
    if (livePhotoImage != null && livePhotoVideo != null) {
      final livePhotoImageFile = File(livePhotoImage!);
      final livePhotoVideoFile = File(livePhotoVideo!);
      if (livePhotoImageFile.existsSync()) {
        await livePhotoImageFile.delete();
      }
      if (livePhotoVideoFile.existsSync()) {
        await livePhotoVideoFile.delete();
      }
    }
  }
}
