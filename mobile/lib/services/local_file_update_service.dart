import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/utils/file_uploader_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LocalFileUpdateService tracks all the potential local file IDs which have
// changed/modified on the device and needed to be uploaded again.
class LocalFileUpdateService {
  late FileUpdationDB _fileUpdationDB;
  late SharedPreferences _prefs;
  late Logger _logger;

  final List<String> _oldMigrationKeys = [
    'fm_badCreationTime',
    'fm_badCreationTimeCompleted',
    'fm_missingLocationV2ImportDone',
    'fm_missingLocationV2MigrationDone',
    'fm_badLocationImportDone',
    'fm_badLocationMigrationDone',
    'fm_ios_live_photo_size',
    'fm_import_ios_live_photo_size',
    'fm_ios_live_photo_check',
    'fm_import_ios_live_photo_check',
    'fm_android_missing_gps_check_done',
  ];

  Completer<void>? _existingMigration;

  LocalFileUpdateService._privateConstructor() {
    _logger = Logger((LocalFileUpdateService).toString());
    _fileUpdationDB = FileUpdationDB.instance;
  }

  void init(SharedPreferences preferences) {
    _prefs = preferences;
  }

  static LocalFileUpdateService instance =
      LocalFileUpdateService._privateConstructor();

  Future<void> markUpdatedFilesForReUpload() async {
    if (_existingMigration != null) {
      _logger.info("migration is already in progress, skipping");
      return _existingMigration!.future;
    }
    _existingMigration = Completer<void>();
    try {
      await _markFilesWhichAreActuallyUpdated();
      _cleanUpOlderMigration().ignore();
    } catch (e, s) {
      _logger.severe('failed to perform migration', e, s);
    } finally {
      _existingMigration?.complete();
      _existingMigration = null;
    }
  }

  Future<void> _cleanUpOlderMigration() async {
    // check if any old_migration_keys are present in shared preferences
    bool hasOldMigrationKey = false;
    for (String key in _oldMigrationKeys) {
      if (_prefs.containsKey(key)) {
        hasOldMigrationKey = true;
        break;
      }
    }
    if (hasOldMigrationKey) {
      await _fileUpdationDB.deleteByReasons([
        'missing_location',
        'badCreationTime',
        'missingLocationV2',
        'badLocationCord',
        'livePhotoSize',
        'livePhotoCheck',
        'androidMissingGPS',
      ]);
      for (var element in _oldMigrationKeys) {
        await _prefs.remove(element);
      }
    }
  }

  // This method analyses all of local files for which the file
  // modification/update time was changed. It checks if the existing fileHash
  // is different from the hash of uploaded file. If fileHash are different,
  // then it marks the file for file update.
  Future<void> _markFilesWhichAreActuallyUpdated() async {
    final sTime = DateTime.now().microsecondsSinceEpoch;
    // singleRunLimit indicates number of files to check during single
    // invocation of this method. The limit act as a crude way to limit the
    // resource consumed by the method
    const int singleRunLimit = 10;
    final localIDsToProcess =
        await _fileUpdationDB.getLocalIDsForPotentialReUpload(
      singleRunLimit,
      FileUpdationDB.modificationTimeUpdated,
    );
    if (localIDsToProcess.isNotEmpty) {
      await _checkAndMarkFilesWithDifferentHashForFileUpdate(
        localIDsToProcess,
      );
      final eTime = DateTime.now().microsecondsSinceEpoch;
      final d = Duration(microseconds: eTime - sTime);
      _logger.info(
        'Performed hashCheck for ${localIDsToProcess.length} updated files '
        'completed in ${d.inSeconds.toString()} secs',
      );
    }
  }

  Future<void> _checkAndMarkFilesWithDifferentHashForFileUpdate(
    List<String> localIDsToProcess,
  ) async {
    final int userID = Configuration.instance.getUserID()!;
    final List<EnteFile> result =
        await FilesDB.instance.getLocalFiles(localIDsToProcess);
    final List<EnteFile> localFilesForUser = [];
    final Set<String> localIDsWithFile = {};
    for (EnteFile file in result) {
      if (file.ownerID == null || file.ownerID == userID) {
        localFilesForUser.add(file);
        localIDsWithFile.add(file.localID!);
      }
    }

    final Set<String> processedIDs = {};
    // if a file for localID doesn't exist, then mark it as processed
    // otherwise the app will be stuck in retrying same set of ids
    for (String localID in localIDsToProcess) {
      if (!localIDsWithFile.contains(localID)) {
        processedIDs.add(localID);
      }
    }
    _logger.info("files to process ${localIDsToProcess.length} for reupload, "
        "missing localFile cnt ${processedIDs.length}");

    for (EnteFile file in localFilesForUser) {
      if (processedIDs.contains(file.localID)) {
        continue;
      }
      if (!file.isUploaded) {
        _logger.info("File ${file.tag} is not uploaded, skipping hash check");
        processedIDs.add(file.localID!);
        continue;
      }
      MediaUploadData uploadData;
      try {
        uploadData = await getUploadData(file);
        if (uploadData.hashData != null &&
            file.hash != null &&
            (file.hash == uploadData.hashData!.fileHash ||
                file.hash == uploadData.hashData!.zipHash)) {
          _logger.info("Skip file update as hash matched ${file.tag}");
        } else {
          _logger.info(
            "Marking for file update as hash did not match ${file.tag}",
          );
          await clearCache(file);
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
        processedIDs.add(file.localID!);
      } on InvalidFileError catch (e) {
        if (e.reason == InvalidReason.livePhotoToImageTypeChanged ||
            e.reason == InvalidReason.imageToLivePhotoTypeChanged) {
          late FileType fileType;
          if (e.reason == InvalidReason.livePhotoToImageTypeChanged) {
            fileType = FileType.image;
          } else if (e.reason == InvalidReason.imageToLivePhotoTypeChanged) {
            fileType = FileType.livePhoto;
          }
          await FilesDB.instance.markFilesForReUpload(
            userID,
            file.localID!,
            file.title,
            file.location,
            file.creationTime!,
            file.modificationTime!,
            fileType,
          );
          _logger.info('fileType changed for ${file.tag} to ${e.reason} for ');
        } else {
          _logger.severe("failed to check hash: invalid file ${file.tag}", e);
        }
        processedIDs.add(file.localID!);
      } catch (e, s) {
        _logger.severe("Failed to check hash", e, s);
      } finally {}
    }
    await _fileUpdationDB.deleteByLocalIDs(
      processedIDs.toList(),
      FileUpdationDB.modificationTimeUpdated,
    );
  }

  Future<MediaUploadData> getUploadData(EnteFile file) async {
    final mediaUploadData = await getUploadDataFromEnteFile(file);
    // delete the file from app's internal cache if it was copied to app
    // for upload. Shared Media should only be cleared when the upload
    // succeeds.
    if (Platform.isIOS && mediaUploadData.sourceFile != null) {
      await mediaUploadData.sourceFile?.delete();
    }
    return mediaUploadData;
  }

  Future<(MediaUploadData, int)> getUploadDataWithSizeSize(
    EnteFile file,
  ) async {
    final mediaUploadData = await getUploadDataFromEnteFile(file);
    final int size = await mediaUploadData.sourceFile!.length();
    // delete the file from app's internal cache if it was copied to app
    // for upload. Shared Media should only be cleared when the upload
    // succeeds.
    if (Platform.isIOS && mediaUploadData.sourceFile != null) {
      await mediaUploadData.sourceFile?.delete();
    }
    return (mediaUploadData, size);
  }
}
