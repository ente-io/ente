import "package:photos/models/file/file_type.dart";

class AssetUploadQueue {
  final String id;
  final int destCollectionId;
  final String? pathId;
  final int ownerId;
  final bool manual;
  late FileType? fileType;
  late int? createdAt;

  AssetUploadQueue({
    required this.id,
    required this.destCollectionId,
    required this.pathId,
    required this.ownerId,
    this.manual = false,
    this.fileType,
    this.createdAt,
  });
}
