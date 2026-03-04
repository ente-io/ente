import "dart:async";
import "dart:io";

import "package:ente_crypto/ente_crypto.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/background_upload_verification_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/background_upload_verification_event.dart";
import "package:photos/main.dart" show isProcessBg;
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/services/sync/ios26_background_upload_router.dart";
import "package:photos/utils/file_download_util.dart";
import "package:photos/utils/file_uploader_util.dart";

class BackgroundUploadVerificationError implements Exception {
  final String message;

  const BackgroundUploadVerificationError(this.message);

  @override
  String toString() => message;
}

class BackgroundUploadVerificationService {
  final _logger = Logger("BackgroundUploadVerificationService");
  final _db = BackgroundUploadVerificationDB.instance;
  Completer<void>? _existingRun;

  BackgroundUploadVerificationService._privateConstructor();
  static final BackgroundUploadVerificationService instance =
      BackgroundUploadVerificationService._privateConstructor();

  Future<void> enqueueForVerification(
    EnteFile file, {
    required String? expectedHash,
    required String? expectedZipHash,
  }) async {
    if (!Platform.isIOS ||
        file.uploadedFileID == null ||
        file.localID == null ||
        file.collectionID == null) {
      return;
    }
    await _db.upsertPending(
      uploadedFileID: file.uploadedFileID!,
      localID: file.localID!,
      collectionID: file.collectionID!,
      expectedHash: expectedHash,
      expectedZipHash: expectedZipHash,
    );
  }

  Future<bool> hasPendingVerification(int uploadedFileID) {
    return _db.hasPendingForUploadID(uploadedFileID);
  }

  Future<bool> hasVerificationRecord(int uploadedFileID) {
    return _db.hasRecordForUploadID(uploadedFileID);
  }

  Future<String?> getFailedVerificationError(int uploadedFileID) {
    return _db.getFailedErrorForUploadID(uploadedFileID);
  }

  Future<void> runPendingVerifications({int limit = 5}) async {
    if (!Platform.isIOS || isProcessBg) {
      return;
    }
    if (_existingRun != null) {
      return _existingRun!.future;
    }
    _existingRun = Completer<void>();
    try {
      final pending = await _db.getPending(limit: limit);
      if (pending.isEmpty) {
        return;
      }
      _logger.info("Running ${pending.length} pending verification jobs");
      for (final record in pending) {
        await _verifyRecord(record);
      }
    } catch (e, s) {
      _logger.severe("Failed to run verification jobs", e, s);
    } finally {
      _existingRun?.complete();
      _existingRun = null;
    }
  }

  Future<void> _verifyRecord(BackgroundUploadVerificationRecord record) async {
    EnteFile? file;
    File? decryptedFile;
    try {
      await _db.markInProgress(record.uploadedFileID);
      file = await _findFileForVerification(record);
      if (file == null) {
        throw const BackgroundUploadVerificationError(
          "File entry not found for verification",
        );
      }

      final expectedHash = await _resolveExpectedHash(record, file);
      if (expectedHash == null || expectedHash.isEmpty) {
        throw const BackgroundUploadVerificationError("Expected hash is empty");
      }

      decryptedFile = await downloadAndDecrypt(
        file,
        forceResumableDownload: true,
        throwOnFailure: true,
      );
      if (decryptedFile == null || !decryptedFile.existsSync()) {
        throw const BackgroundUploadVerificationError(
          "Failed to download/decrypt uploaded file",
        );
      }

      final nativeHashVerified = await IOS26BackgroundUploadRouter.instance
          .verifyDecryptedFileHash(
        filePath: decryptedFile.path,
        expectedHash: expectedHash,
      );
      if (nativeHashVerified == false) {
        throw const BackgroundUploadVerificationError(
          "Hash mismatch for decrypted payload",
        );
      }

      if (nativeHashVerified == null) {
        final downloadedHash = CryptoUtil.bin2base64(
          await CryptoUtil.getHash(decryptedFile),
        );
        if (downloadedHash != expectedHash) {
          throw BackgroundUploadVerificationError(
            "Hash mismatch expected=$expectedHash downloaded=$downloadedHash",
          );
        }
      }

      await _db.markVerified(record.uploadedFileID);
      Bus.instance.fire(
        BackgroundUploadVerificationEvent(
          file: file,
          outcome: BackgroundUploadVerificationOutcome.verified,
        ),
      );
    } catch (e, s) {
      _logger.severe(
        "Verification failed for uploadedFileID=${record.uploadedFileID}",
        e,
        s,
      );
      await _db.markFailed(record.uploadedFileID, e.toString());
      if (file != null) {
        await _markForReupload(file);
        Bus.instance.fire(
          BackgroundUploadVerificationEvent(
            file: file,
            outcome: BackgroundUploadVerificationOutcome.failed,
            error: e,
          ),
        );
      }
    } finally {
      try {
        if (decryptedFile?.existsSync() == true) {
          await decryptedFile!.delete();
        }
      } catch (_) {}
    }
  }

  Future<EnteFile?> _findFileForVerification(
    BackgroundUploadVerificationRecord record,
  ) async {
    final userID = Configuration.instance.getUserID();
    if (userID == null) {
      return null;
    }
    final files = await FilesDB.instance.getFilesInAllCollection(
      record.uploadedFileID,
      userID,
    );
    if (files.isEmpty) {
      return FilesDB.instance.getUploadedFile(
        record.uploadedFileID,
        record.collectionID,
      );
    }
    for (final file in files) {
      if (file.canReUpload(userID)) {
        return file;
      }
    }
    return files.first;
  }

  Future<String?> _resolveExpectedHash(
    BackgroundUploadVerificationRecord record,
    EnteFile file,
  ) async {
    if ((record.expectedZipHash ?? "").isNotEmpty) {
      return record.expectedZipHash;
    }
    if ((record.expectedHash ?? "").isNotEmpty) {
      return record.expectedHash;
    }

    final uploadData = await getUploadDataFromEnteFile(file);
    if (file.isLivePhoto) {
      return uploadData.hashData?.zipHash ?? uploadData.hashData?.fileHash;
    }
    return uploadData.hashData?.fileHash;
  }

  Future<void> _markForReupload(EnteFile file) async {
    final userID = Configuration.instance.getUserID();
    if (userID == null ||
        file.localID == null ||
        file.creationTime == null ||
        file.modificationTime == null) {
      return;
    }
    await FilesDB.instance.markFilesForReUpload(
      userID,
      file.localID!,
      file.title,
      file.location,
      file.creationTime!,
      file.modificationTime!,
      file.fileType,
    );
  }
}
