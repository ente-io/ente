import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/db/file_migration_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FileMigrationService {
  FilesDB _filesDB;
  FilesMigrationDB _filesMigrationDB;
  Future<SharedPreferences> _prefs;
  Logger _logger;
  static const isLocationMigrationComplete = "fm_isLocationMigrationComplete";
  static const isLocalImportDone = "fm_IsLocalImportDone";
  Completer<void> _existingMigration;

  FileMigrationService._privateConstructor() {
    assert(Platform.isAndroid, "platform should be Android only");
    _logger = Logger((FileMigrationService).toString());
    _filesDB = FilesDB.instance;
    _filesMigrationDB = FilesMigrationDB.instance;
    _prefs = SharedPreferences.getInstance();
  }

  static FileMigrationService instance =
      FileMigrationService._privateConstructor();

  Future<bool> _markLocationMigrationAsCompleted() async {
    _logger.info('marking migration as completed');
    var sharedPreferences = await _prefs;
    return sharedPreferences.setBool(isLocationMigrationComplete, true);
  }

  Future<bool> isMigrationComplete() async {
    var sharedPreferences = await _prefs;
    return sharedPreferences.get(isLocationMigrationComplete) ?? false;
  }

  Future<void> Migrate() async {
    if (_existingMigration != null) {
      _logger.info("Migration is already in progress, skipping");
      return _existingMigration.future;
    }
    _logger.info("Start file migration");
    _existingMigration = Completer<void>();
    try {
      _importLocalFilesForMigration();
      bool hasData = true;
      while (hasData) {
        var localIDsToProcess =
            await _filesMigrationDB.getLocalIDsForPotentialReUpload(limit: 100);
        if (localIDsToProcess.isEmpty) {
          hasData = false;
        }
        await _checkAndMarkFilesForReUpload(localIDsToProcess);
      }
      await _markLocationMigrationAsCompleted();
      _existingMigration.complete();
      _existingMigration = null;
    } catch (e, s) {
      _logger.severe('failed to perform migration', e, s);
      _existingMigration.complete();
      _existingMigration = null;
    }
  }

  Future<void> _checkAndMarkFilesForReUpload(
      List<String> localIDsToProcess) async {
    _logger.info("Files to process ${localIDsToProcess.length}");
    var localIDsWithLocation = <String>[];
    for (var localID in localIDsToProcess) {
      bool hasLocation = false;
      try {
        var assetEntity = await AssetEntity.fromId(localID);
        if (assetEntity == null) {
          continue;
        }
        var latLng = await assetEntity.latlngAsync();
        if (latLng.latitude != null || latLng.longitude != null) {
          _logger.finest(
              'found lat long for  ${assetEntity.title} ${assetEntity.relativePath} with id : $localID');
          hasLocation = true;
        }
      } catch (e, s) {
        _logger.severe('failed to get asset entity with id $localID', e, s);
      }
      if (hasLocation) {
        localIDsWithLocation.add(localID);
      }
    }
    _logger.info('Marking ${localIDsWithLocation.length} files for re-upload');
    // await _filesDB.markForReUploadIfLocationMissing(localIDsWithLocation);
    await _filesMigrationDB.deleteByLocaIDs(localIDsToProcess);
  }

  Future<void> _importLocalFilesForMigration() async {
    if ((await _prefs).containsKey(isLocalImportDone)) {
      return;
    }
    _logger.info('importing files without location info');
    var fileLocalIDs = await _filesDB.getLocalFilesBackedUpWithoutLocation();
    await _filesMigrationDB.insertMultiple(fileLocalIDs);
    _logger.info('importing completed, total files count $fileLocalIDs');
    (await _prefs).setBool(isLocalImportDone, true);
  }
}
