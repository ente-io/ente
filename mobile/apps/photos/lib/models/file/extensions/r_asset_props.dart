import "package:photos/models/file/remote/asset.dart";

extension RemoteAssetExtension on RemoteAsset {
  bool get isMotionPhoto {
    return (motionVideoIndex ?? 0) > 0;
  }
}
