class AssetUploadQueue {
  final String id;
  final int destCollectionId;
  final String? pathId;
  final int ownerId;
  final bool manual;

  AssetUploadQueue({
    required this.id,
    required this.destCollectionId,
    required this.pathId,
    required this.ownerId,
    this.manual = false,
  });
}
