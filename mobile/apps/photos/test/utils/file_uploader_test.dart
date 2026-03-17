import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:photos/models/backup/backup_item.dart";
import "package:photos/models/backup/backup_item_status.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/utils/file_uploader.dart";

void main() {
  group("FileUploader.reconcileAfterBackground", () {
    setUp(() {
      FileUploader.instance.resetForTesting();
    });

    test("completes handed off uploads and clears session bookkeeping",
        () async {
      const localID = "local-1";
      final pendingFile = EnteFile()
        ..generatedID = 42
        ..localID = localID
        ..title = "photo.jpg"
        ..deviceFolder = "Camera"
        ..creationTime = 1
        ..modificationTime = 1
        ..fileType = FileType.image;
      final uploadedFile = EnteFile()
        ..generatedID = 42
        ..localID = localID
        ..title = "photo.jpg"
        ..deviceFolder = "Camera"
        ..creationTime = 1
        ..modificationTime = 1
        ..fileType = FileType.image
        ..uploadedFileID = 99
        ..collectionID = 7;
      final completer = Completer<EnteFile>();

      FileUploader.instance.addPendingUploadForTesting(
        FileUploadItem(pendingFile, 7, completer),
        BackupItem(
          status: BackupItemStatus.inBackground,
          file: pendingFile,
          collectionID: 7,
          completer: completer,
        ),
      );

      await FileUploader.instance.reconcileAfterBackground(
        lookupFile: (generatedID) async =>
            generatedID == pendingFile.generatedID ? uploadedFile : null,
      );

      expect(completer.isCompleted, isTrue);
      expect(await completer.future, same(uploadedFile));
      expect(FileUploader.instance.hasActiveUploads, isFalse);
      expect(FileUploader.instance.getCurrentSessionUploadCount(), 0);
      expect(
        FileUploader.instance.allBackups[localID]!.status,
        BackupItemStatus.uploaded,
      );
      expect(
        FileUploader.instance.allBackups[localID]!.file.uploadedFileID,
        99,
      );
    });
  });
}
