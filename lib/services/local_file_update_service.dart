// @dart=2.9

import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file.dart' as ente;
import 'package:photos/utils/file_uploader_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LocalFileUpdateService tracks all the potential local file IDs which have
// changed/modified on the device and needed to be uploaded again.
class LocalFileUpdateService {
  FileUpdationDB _fileUpdationDB;
  SharedPreferences _prefs;
  Logger _logger;
  static const isLocationMigrationComplete = "fm_isLocationMigrationComplete";
  static const isLocalImportDone = "fm_IsLocalImportDone";
  Completer<void> _existingMigration;

  LocalFileUpdateService._privateConstructor() {
    _logger = Logger((LocalFileUpdateService).toString());
    _fileUpdationDB = FileUpdationDB.instance;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static LocalFileUpdateService instance =
      LocalFileUpdateService._privateConstructor();

  bool isLocationMigrationCompleted() {
    return _prefs.get(isLocationMigrationComplete) ?? false;
  }

  Future<void> markUpdatedFilesForReUpload() async {
    if (_existingMigration != null) {
      _logger.info("migration is already in progress, skipping");
      return _existingMigration.future;
    }
    _existingMigration = Completer<void>();
    try {
      await _markFilesWhichAreActuallyUpdated();
    } catch (e, s) {
      _logger.severe('failed to perform migration', e, s);
    } finally {
      _existingMigration?.complete();
      _existingMigration = null;
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
    _logger.info("files to process ${localIDsToProcess.length} for reupload");
    final List<ente.File> localFiles =
        await FilesDB.instance.getLocalFiles(localIDsToProcess);
    final Set<String> processedIDs = {};
    for (ente.File file in localFiles) {
      if (processedIDs.contains(file.localID)) {
        continue;
      }
      MediaUploadData uploadData;
      try {
        uploadData = await getUploadData(file);
        if (uploadData != null &&
            uploadData.hashData != null &&
            file.hash != null &&
            (file.hash == uploadData.hashData.fileHash ||
                file.hash == uploadData.hashData.zipHash)) {
          _logger.info("Skip file update as hash matched ${file.tag}");
        } else {
          _logger.info(
            "Marking for file update as hash did not match ${file.tag}",
          );
          await FilesDB.instance.updateUploadedFile(
            file.localID,
            file.title,
            file.location,
            file.creationTime,
            file.modificationTime,
            null,
          );
        }
        processedIDs.add(file.localID);
      } catch (e) {
        _logger.severe("Failed to get file uploadData", e);
      } finally {}
    }
    debugPrint("Deleting files ${processedIDs.length}");
    await _fileUpdationDB.deleteByLocalIDs(
      processedIDs.toList(),
      FileUpdationDB.modificationTimeUpdated,
    );
  }

  Future<MediaUploadData> getUploadData(ente.File file) async {
    final mediaUploadData = await getUploadDataFromEnteFile(file);
    // delete the file from app's internal cache if it was copied to app
    // for upload. Shared Media should only be cleared when the upload
    // succeeds.
    if (Platform.isIOS &&
        mediaUploadData != null &&
        mediaUploadData.sourceFile != null) {
      await mediaUploadData.sourceFile.delete();
    }
    return mediaUploadData;
  }
}
