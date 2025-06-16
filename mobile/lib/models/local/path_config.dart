import "package:photos/models/upload_strategy.dart";

class PathConfig {
  final String pathID;
  final int ownerId;
  // the target collection ID where the assets in this path will be uploaded
  // if null, the client will try to map to existing collection based on the path
  // or create a new collection if no mapping exists
  final int? destCollectionID;
  final bool shouldBackup;
  final UploadStrategy uploadStrategy;

  PathConfig(
    this.pathID,
    this.ownerId,
    this.destCollectionID,
    this.shouldBackup,
    this.uploadStrategy,
  );
}
