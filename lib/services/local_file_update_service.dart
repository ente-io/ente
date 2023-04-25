import 'dart:async';
import 'dart:core';
import 'dart:io';

import "package:collection/collection.dart";
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/extensions/stop_watch.dart';
import 'package:photos/models/file.dart' as ente;
import "package:photos/models/location/location.dart";
import "package:photos/models/magic_metadata.dart";
import "package:photos/services/file_magic_service.dart";
import "package:photos/utils/exif_util.dart";
import 'package:photos/utils/file_uploader_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LocalFileUpdateService tracks all the potential local file IDs which have
// changed/modified on the device and needed to be uploaded again.
class LocalFileUpdateService {
  late FileUpdationDB _fileUpdationDB;
  late SharedPreferences _prefs;
  late Logger _logger;
  static const isBadCreationTimeImportDone = 'fm_badCreationTime';
  static const isBadCreationTimeMigrationComplete =
      'fm_badCreationTimeCompleted';
  static const isMissingLocationV2ImportDone = "fm_missingLocationV2ImportDone";
  static const isMissingLocationV2MigrationDone =
      "fm_missingLocationV2MigrationDone";

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

  bool isBadCreationMigrationCompleted() {
    return (_prefs.getBool(isBadCreationTimeMigrationComplete) ?? false);
  }

  Future<void> markUpdatedFilesForReUpload() async {
    if (_existingMigration != null) {
      _logger.info("migration is already in progress, skipping");
      return _existingMigration!.future;
    }
    _existingMigration = Completer<void>();
    try {
      await _markFilesWhichAreActuallyUpdated();
      if (Platform.isAndroid) {
        await _migrationFilesWithMissingLocationV2();
      }
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
          await FilesDB.instance.updateUploadedFile(
            file.localID!,
            file.title,
            file.location,
            file.creationTime!,
            file.modificationTime!,
            null,
          );
        }
        processedIDs.add(file.localID!);
      } on InvalidFileError {
        // if we fail to get the file, we can ignore the update
        processedIDs.add(file.localID!);
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
    if (Platform.isIOS && mediaUploadData.sourceFile != null) {
      await mediaUploadData.sourceFile?.delete();
    }
    return mediaUploadData;
  }

  Future<void> _migrationFilesWithMissingLocationV2() async {
    if (_prefs.containsKey(isMissingLocationV2MigrationDone)) {
      return;
    }
    await _importForMissingLocationV2();
    const int singleRunLimit = 10;
    final List<String> processedIDs = [];
    try {
      final localIDs = await _fileUpdationDB.getLocalIDsForPotentialReUpload(
        singleRunLimit,
        FileUpdationDB.missingLocationV2,
      );
      if (localIDs.isEmpty) {
        // everything is done
        await _prefs.setBool(isMissingLocationV2MigrationDone, true);
        return;
      }

      final List<ente.File> enteFiles = await FilesDB.instance
          .getFilesForLocalIDs(localIDs, Configuration.instance.getUserID()!);
      // fine localIDs which are not present in enteFiles
      final List<String> missingLocalIDs = [];
      for (String localID in localIDs) {
        if (enteFiles.firstWhereOrNull((e) => e.localID == localID) == null) {
          missingLocalIDs.add(localID);
        }
      }
      processedIDs.addAll(missingLocalIDs);

      final List<ente.File> remoteFilesToUpdate = [];
      final Map<int, Map<String, double>> fileIDToUpdateMetadata = {};

      for (ente.File file in enteFiles) {
        final Location? location = await tryLocationFromExif(file);
        if (location != null &&
            (location.latitude ?? 0) != 0.0 &&
            (location.longitude ?? 0) != 0.0) {
          remoteFilesToUpdate.add(file);
          fileIDToUpdateMetadata[file.uploadedFileID!] = {
            pubMagicKeyLat: location.latitude!,
            pubMagicKeyLong: location.longitude!
          };
        } else if (file.localID != null) {
          processedIDs.add(file.localID!);
        }
      }
      if (remoteFilesToUpdate.isNotEmpty) {
        await FileMagicService.instance.updatePublicMagicMetadata(
          remoteFilesToUpdate,
          null,
          metadataUpdateMap: fileIDToUpdateMetadata,
        );
        for (ente.File file in remoteFilesToUpdate) {
          if (file.localID != null) {
            processedIDs.add(file.localID!);
          }
        }
      }
    } catch (e) {
      _logger.severe("Failed to fix bad creationTime", e);
    } finally {
      await _fileUpdationDB.deleteByLocalIDs(
        processedIDs,
        FileUpdationDB.missingLocationV2,
      );
    }
  }

  Future<void> _importForMissingLocationV2() async {
    if (_prefs.containsKey(isMissingLocationV2ImportDone)) {
      return;
    }
    _logger.info('_importForMissingLocationV2');
    final EnteWatch watch = EnteWatch("_importForMissingLocationV2");
    final int ownerID = Configuration.instance.getUserID()!;
    final List<String> localIDs =
        await FilesDB.instance.getLocalIDsForFilesWithoutLocation(ownerID);

    await _fileUpdationDB.insertMultiple(
      localIDs,
      FileUpdationDB.missingLocationV2,
    );
    watch.log("imported ${localIDs.length} files");
    await _prefs.setBool(isMissingLocationV2ImportDone, true);
  }
}
