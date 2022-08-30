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
  SharedPreferences _prefs;
  Logger _logger;
  static const isLocationMigrationComplete = "fm_isLocationMigrationComplete";
  static const isLocalImportDone = "fm_IsLocalImportDone";
  Completer<void> _existingMigration;

  FileMigrationService._privateConstructor() {
    _logger = Logger((FileMigrationService).toString());
    _filesDB = FilesDB.instance;
    _filesMigrationDB = FilesMigrationDB.instance;
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static FileMigrationService instance =
      FileMigrationService._privateConstructor();

  Future<bool> _markLocationMigrationAsCompleted() async {
    _logger.info('marking migration as completed');
    return _prefs.setBool(isLocationMigrationComplete, true);
  }

  bool isLocationMigrationCompleted() {
    return _prefs.get(isLocationMigrationComplete) ?? false;
  }

  Future<void> runMigration() async {
    if (_existingMigration != null) {
      _logger.info("migration is already in progress, skipping");
      return _existingMigration.future;
    }
    _logger.info("start migration");
    _existingMigration = Completer<void>();
    try {
      await _runMigrationForFilesWithMissingLocation();
      _existingMigration.complete();
      _existingMigration = null;
    } catch (e, s) {
      _logger.severe('failed to perform migration', e, s);
      _existingMigration.complete();
      _existingMigration = null;
    }
  }

  Future<void> _runMigrationForFilesWithMissingLocation() async {
    if (!Platform.isAndroid) {
      return;
    }
    // migration only needs to run if Android API Level is 29 or higher
    final int version = int.parse(await PhotoManager.systemVersion());
    final bool isMigrationRequired = version >= 29;
    if (isMigrationRequired) {
      await _importLocalFilesForMigration();
      final sTime = DateTime.now().microsecondsSinceEpoch;
      bool hasData = true;
      const int limitInBatch = 100;
      while (hasData) {
        final localIDsToProcess = await _filesMigrationDB
            .getLocalIDsForPotentialReUpload(limitInBatch);
        if (localIDsToProcess.isEmpty) {
          hasData = false;
        } else {
          await _checkAndMarkFilesForReUpload(localIDsToProcess);
        }
      }
      final eTime = DateTime.now().microsecondsSinceEpoch;
      final d = Duration(microseconds: eTime - sTime);
      _logger.info(
        'filesWithMissingLocation migration completed in ${d.inSeconds.toString()} seconds',
      );
    }
    await _markLocationMigrationAsCompleted();
  }

  Future<void> _checkAndMarkFilesForReUpload(
    List<String> localIDsToProcess,
  ) async {
    _logger.info("files to process ${localIDsToProcess.length}");
    final localIDsWithLocation = <String>[];
    for (var localID in localIDsToProcess) {
      bool hasLocation = false;
      try {
        final assetEntity = await AssetEntity.fromId(localID);
        if (assetEntity == null) {
          continue;
        }
        final latLng = await assetEntity.latlngAsync();
        if ((latLng.longitude ?? 0.0) != 0.0 ||
            (latLng.longitude ?? 0.0) != 0.0) {
          _logger.finest(
            'found lat/long ${latLng.longitude}/${latLng.longitude} for  ${assetEntity.title} ${assetEntity.relativePath} with id : $localID',
          );
          hasLocation = true;
        }
      } catch (e, s) {
        _logger.severe('failed to get asset entity with id $localID', e, s);
      }
      if (hasLocation) {
        localIDsWithLocation.add(localID);
      }
    }
    _logger.info('marking ${localIDsWithLocation.length} files for re-upload');
    await _filesDB.markForReUploadIfLocationMissing(localIDsWithLocation);
    await _filesMigrationDB.deleteByLocalIDs(localIDsToProcess);
  }

  Future<void> _importLocalFilesForMigration() async {
    if (_prefs.containsKey(isLocalImportDone)) {
      return;
    }
    final sTime = DateTime.now().microsecondsSinceEpoch;
    _logger.info('importing files without location info');
    final fileLocalIDs = await _filesDB.getLocalFilesBackedUpWithoutLocation();
    await _filesMigrationDB.insertMultiple(fileLocalIDs);
    final eTime = DateTime.now().microsecondsSinceEpoch;
    final d = Duration(microseconds: eTime - sTime);
    _logger.info(
      'importing completed, total files count ${fileLocalIDs.length} and took ${d.inSeconds.toString()} seconds',
    );
    _prefs.setBool(isLocalImportDone, true);
  }
}
