import "package:photos/models/file/remote/asset.dart";
import "package:photos/models/metadata/file_magic.dart";

extension RemoteAssetExtension on RemoteAsset {
  bool get isMotionPhoto {
    return publicMetadata?.data[motionVideoIndexKey] ?? 0 > 0;
  }

  int? get streamingVersion {
    return publicMetadata?.data[streamVersionKey];
  }
}
