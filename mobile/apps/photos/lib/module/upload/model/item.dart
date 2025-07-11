import "dart:async";

import "package:photos/models/file/file.dart";
import "package:photos/models/local/asset_upload_queue.dart";

class FileUploadItem {
  final EnteFile file;
  final int collectionID;
  final Completer<EnteFile> completer;
  final AssetUploadQueue? queue;
  UploadStatus status;

  FileUploadItem(
    this.file,
    this.collectionID,
    this.completer, {
      this.queue,
    this.status = UploadStatus.notStarted,
  });
}

enum UploadStatus { notStarted, inProgress, inBackground, completed }

enum ProcessType {
  background,
  foreground,
}
