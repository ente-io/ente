import "dart:async";

import "package:photos/models/file/file.dart";
import "package:photos/models/local/asset_upload_queue.dart";

class FileUploadItem {
  final EnteFile file;
  final int collectionID;
  final Completer<EnteFile> completer;
  final AssetUploadQueue? assetQueue;
  UploadStatus status;

  FileUploadItem(
    this.file,
    this.collectionID,
    this.completer, {
    this.assetQueue,
    this.status = UploadStatus.notStarted,
  });

  String get lockKey => assetQueue?.id ?? file.localID!;
}

enum UploadStatus { notStarted, inProgress, inBackground, completed }

enum ProcessType {
  background,
  foreground,
}
