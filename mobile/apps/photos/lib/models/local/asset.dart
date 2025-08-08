import "package:photos/models/file/file_type.dart";
import "package:photos/models/location/location.dart";

class LocalAsset {
  /// The ID of the asset.
  ///  AssetEntity.id
  final String id;

  final FileType type;

  final int subType;

  final int width;
  final int height;
  final int durationInSec;
  final int orientation;

  /// Whether the asset is favorite on the device.
  /// See also:
  ///  * [AssetEntity.isFavorite]
  final bool isFavorite;

  final String title;

  /// See [AssetEntity.relativePath]
  final String? relativePath;

  final int createdAt;
  final int modifiedAt;
// /// See [AssetEntity.relativePath]
  final String? mimeType;

  final Location? location;
  final int scanState;
  final String? hash;
  final int? size;

  LocalAsset({
    required this.id,
    required this.type,
    required this.subType,
    required this.width,
    required this.height,
    required this.durationInSec,
    required this.orientation,
    required this.isFavorite,
    required this.title,
    this.relativePath,
    required this.createdAt,
    required this.modifiedAt,
    this.mimeType,
    this.location,
    required this.scanState,
    this.hash,
    this.size,
  });
}
