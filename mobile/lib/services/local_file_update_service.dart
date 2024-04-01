import 'dart:async';
import 'dart:core';
import 'dart:io';

import 'package:logging/logging.dart';
import "package:photo_manager/photo_manager.dart";
import "package:photos/core/configuration.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/db/file_updation_db.dart';
import 'package:photos/db/files_db.dart';
import "package:photos/extensions/list.dart";
import "package:photos/extensions/stop_watch.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/services/files_service.dart";
import 'package:photos/utils/file_uploader_util.dart';
import 'package:photos/utils/file_util.dart';
import 'package:shared_preferences/shared_preferences.dart';

// LocalFileUpdateService tracks all the potential local file IDs which have
// changed/modified on the device and needed to be uploaded again.
class LocalFileUpdateService {
  late FileUpdationDB _fileUpdationDB;
  late SharedPreferences _prefs;
  late Logger _logger;
  final String _iosLivePhotoSizeMigrationDone = 'fm_ios_live_photo_check';
  final String _doneLivePhotoImport = 'fm_import_ios_live_photo_check';
  final String _androidMissingGPSImportDone =
      'fm_android_missing_gps_import_done';
  final String _androidMissingGPSCheckDone =
      'fm_android_missing_gps_check_done';
  static int twoHundredKb = 200 * 1024;
  final List<String> _oldMigrationKeys = [
    'fm_badCreationTime',
    'fm_badCreationTimeCompleted',
    'fm_missingLocationV2ImportDone',
    'fm_missingLocationV2MigrationDone',
    'fm_badLocationImportDone',
    'fm_badLocationMigrationDone',
    'fm_ios_live_photo_size',
    'fm_import_ios_live_photo_size',
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
      if (!Platform.isAndroid) {
        await _handleLivePhotosSizedCheck();
      }
      if (Platform.isAndroid) {
        await _androidMissingGPSCheck();
      }
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
          final int count = await FilesDB.instance.markFilesForReUpload(
            userID,
            file.localID!,
            file.title,
            file.location,
            file.creationTime!,
            file.modificationTime!,
            fileType,
          );
          _logger.fine('fileType changed for ${file.tag} to ${e.reason} for '
              '$count files');
        } else {
          _logger.severe("failed to check hash: invalid file ${file.tag}", e);
        }
        processedIDs.add(file.localID!);
      } catch (e) {
        _logger.severe("Failed to check hash", e);
      } finally {}
    }
    await _fileUpdationDB.deleteByLocalIDs(
      processedIDs.toList(),
      FileUpdationDB.modificationTimeUpdated,
    );
  }

  Future<void> checkLivePhoto(EnteFile file) async {
    if (file.localID == null ||
        file.localID!.isEmpty ||
        !file.isUploaded ||
        file.fileType != FileType.livePhoto ||
        !file.isOwner) {
      return;
    }
    if (_prefs.containsKey(_iosLivePhotoSizeMigrationDone)) {
      return;
    }
    final hasEntry = await _fileUpdationDB.isExisting(
      file.localID!,
      FileUpdationDB.livePhotoCheck,
    );
    if (hasEntry) {
      _logger.info('eager checkLivePhoto ${file.tag}');
      await _checkLivePhotoWithLowOrUnknownSize([file.localID!]);
    }
  }

  Future<void> _handleLivePhotosSizedCheck() async {
    try {
      if (_prefs.containsKey(_iosLivePhotoSizeMigrationDone)) {
        return;
      }
      await _importLivePhotoReUploadCandidates();

      // singleRunLimit indicates number of files to check during single
      // invocation of this method. The limit act as a crude way to limit the
      // resource consumed by the method
      const int singleRunLimit = 500;
      final localIDsToProcess =
          await _fileUpdationDB.getLocalIDsForPotentialReUpload(
        singleRunLimit,
        FileUpdationDB.livePhotoCheck,
      );
      if (localIDsToProcess.isNotEmpty) {
        final chunksOf50 = localIDsToProcess.chunks(50);
        for (final chunk in chunksOf50) {
          final sTime = DateTime.now().microsecondsSinceEpoch;
          final List<Future> futures = [];
          final chunkOf10 = chunk.chunks(10);
          for (final smallChunk in chunkOf10) {
            futures.add(_checkLivePhotoWithLowOrUnknownSize(smallChunk));
          }
          await Future.wait(futures);
          final eTime = DateTime.now().microsecondsSinceEpoch;
          final d = Duration(microseconds: eTime - sTime);
          _logger.info(
            'Performed hashCheck for ${chunk.length} livePhoto files '
            'completed in ${d.inSeconds.toString()} secs',
          );
        }
      } else {
        await _prefs.setBool(_iosLivePhotoSizeMigrationDone, true);
      }
    } catch (e, s) {
      _logger.severe('error while checking livePhotoSize check', e, s);
    }
  }

  Future<void> _checkLivePhotoWithLowOrUnknownSize(
    List<String> localIDsToProcess,
  ) async {
    final int userID = Configuration.instance.getUserID()!;
    final List<EnteFile> result =
        await FilesDB.instance.getLocalFiles(localIDsToProcess);
    final List<EnteFile> localFilesForUser = [];
    final Set<String> localIDsWithFile = {};
    final Set<int> missingSizeIDs = {};
    final Set<String> processedIDs = {};
    for (EnteFile file in result) {
      if (file.ownerID == null || file.ownerID == userID) {
        localFilesForUser.add(file);
        localIDsWithFile.add(file.localID!);
        if (file.isUploaded && file.fileSize == null) {
          missingSizeIDs.add(file.uploadedFileID!);
        }
        if (file.isUploaded && file.updationTime == null) {
          // file already queued for re-upload
          processedIDs.add(file.localID!);
        }
      }
    }
    if (missingSizeIDs.isNotEmpty) {
      await FilesService.instance.backFillSizes(missingSizeIDs.toList());
      _logger.info('sizes back fill for ${missingSizeIDs.length} files');
      // return early, let the check run in the next batch
      return;
    }

    // if a file for localID doesn't exist, then mark it as processed
    // otherwise the app will be stuck in retrying same set of ids

    for (String localID in localIDsToProcess) {
      if (!localIDsWithFile.contains(localID)) {
        processedIDs.add(localID);
      }
    }
    _logger.info(" check ${localIDsToProcess.length} files for livePhotoSize, "
        "missing file cnt ${processedIDs.length}");

    for (EnteFile file in localFilesForUser) {
      if (file.fileSize == null) {
        _logger.info('fileSize still null, skip this file');
        continue;
      } else if (file.fileType != FileType.livePhoto) {
        _logger.severe('fileType is not livePhoto, skip this file');
        processedIDs.add(file.localID!);
        continue;
      }
      if (processedIDs.contains(file.localID)) {
        continue;
      }
      try {
        late MediaUploadData uploadData;
        late int mediaUploadSize;
        (uploadData, mediaUploadSize) = await getUploadDataWithSizeSize(file);
        if ((file.fileSize! - mediaUploadSize).abs() > twoHundredKb) {
          _logger.info(
            'Re-upload livePhoto localHash ${uploadData.hashData?.fileHash ?? "null"} & localSize: $mediaUploadSize'
            ' and remoteHash ${file.hash ?? "null"} & removeSize: ${file.fileSize!}',
          );
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
          // let existing file update check handle this case
          _fileUpdationDB.insertMultiple(
            [file.localID!],
            FileUpdationDB.modificationTimeUpdated,
          ).ignore();
        } else {
          _logger.severe("livePhoto check failed: invalid file ${file.tag}", e);
        }
        processedIDs.add(file.localID!);
      } catch (e) {
        _logger.severe("livePhoto check failed", e);
      } finally {}
    }
    _logger.info('completed check for ${localIDsToProcess.length} files');
    await _fileUpdationDB.deleteByLocalIDs(
      processedIDs.toList(),
      FileUpdationDB.livePhotoCheck,
    );
  }

  Future<void> _importLivePhotoReUploadCandidates() async {
    if (_prefs.containsKey(_doneLivePhotoImport)) {
      return;
    }
    _logger.info('_importLivePhotoReUploadCandidates');
    final EnteWatch watch = EnteWatch("_importLivePhotoReUploadCandidates");
    final int ownerID = Configuration.instance.getUserID()!;
    final List<String> localIDs =
        await FilesDB.instance.getLivePhotosForUser(ownerID);
    await _fileUpdationDB.insertMultiple(
      localIDs,
      FileUpdationDB.livePhotoCheck,
    );
    watch.log("imported ${localIDs.length} files");
    await _prefs.setBool(_doneLivePhotoImport, true);
  }

  //#region Android Missing GPS specific methods ###

  Future<void> _androidMissingGPSCheck() async {
    if (_prefs.containsKey(_androidMissingGPSCheckDone)) {
      return;
    }
    await _importAndroidBadGPSCandidate();
    // singleRunLimit indicates number of files to check during single
    // invocation of this method. The limit act as a crude way to limit the
    // resource consumed by the method
    const int singleRunLimit = 500;
    final localIDsToProcess =
        await _fileUpdationDB.getLocalIDsForPotentialReUpload(
      singleRunLimit,
      FileUpdationDB.androidMissingGPS,
    );
    if (localIDsToProcess.isNotEmpty) {
      final chunksOf50 = localIDsToProcess.chunks(50);
      for (final chunk in chunksOf50) {
        final sTime = DateTime.now().microsecondsSinceEpoch;
        final List<Future> futures = [];
        final chunkOf10 = chunk.chunks(10);
        for (final smallChunk in chunkOf10) {
          futures.add(_checkForMissingGPS(smallChunk));
        }
        await Future.wait(futures);
        final eTime = DateTime.now().microsecondsSinceEpoch;
        final d = Duration(microseconds: eTime - sTime);
        _logger.info(
          'Performed missing GPS Location check for ${chunk.length} files '
          'completed in ${d.inSeconds.toString()} secs',
        );
      }
    } else {
      _logger.info('Completed android missing GPS check');
      await _prefs.setBool(_androidMissingGPSCheckDone, true);
    }
  }

  Future<void> _checkForMissingGPS(List<String> localIDs) async {
    try {
      final List<EnteFile> localFiles =
          await FilesDB.instance.getLocalFiles(localIDs);
      final ownerID = Configuration.instance.getUserID()!;
      final Set<String> localIDsWithFile = {};
      final Set<String> reuploadCandidate = {};
      final Set<String> processedIDs = {};
      for (EnteFile file in localFiles) {
        if (file.localID == null) continue;
        // ignore files that are not uploaded or have different owner
        if (!file.isUploaded || file.ownerID! != ownerID) {
          processedIDs.add(file.localID!);
        }
        if (file.hasLocation) {
          processedIDs.add(file.localID!);
        }
      }
      for (EnteFile enteFile in localFiles) {
        try {
          if (enteFile.localID == null ||
              processedIDs.contains(enteFile.localID!)) {
            continue;
          }

          final localID = enteFile.localID!;
          localIDsWithFile.add(localID);
          final AssetEntity? entity = await AssetEntity.fromId(localID);
          if (entity == null) {
            processedIDs.add(localID);
          } else {
            final latLng = await entity.latlngAsync();
            if ((latLng.longitude ?? 0) == 0 || (latLng.latitude ?? 0) == 0) {
              processedIDs.add(localID);
            } else {
              reuploadCandidate.add(localID);
              processedIDs.add(localID);
            }
          }
        } catch (e, s) {
          processedIDs.add(enteFile.localID!);
          _logger.severe('lat/long check file ${enteFile.toString()}', e, s);
        }
      }
      for (String id in localIDs) {
        // if the file with given localID doesn't exist, consider it as done.
        if (!localIDsWithFile.contains(id)) {
          processedIDs.add(id);
        }
      }
      await FileUpdationDB.instance.insertMultiple(
        reuploadCandidate.toList(),
        FileUpdationDB.modificationTimeUpdated,
      );
      await FileUpdationDB.instance.deleteByLocalIDs(
        processedIDs.toList(),
        FileUpdationDB.androidMissingGPS,
      );
    } catch (e, s) {
      _logger.severe('error while checking missing GPS', e, s);
    }
  }

  Future<void> _importAndroidBadGPSCandidate() async {
    if (_prefs.containsKey(_androidMissingGPSImportDone)) {
      return;
    }
    final sTime = DateTime.now().microsecondsSinceEpoch;
    _logger.info('importing files without missing GPS');
    final int ownerID = Configuration.instance.getUserID()!;
    final fileLocalIDs =
        await FilesDB.instance.getLocalFilesBackedUpWithoutLocation(ownerID);
    await _fileUpdationDB.insertMultiple(
      fileLocalIDs,
      FileUpdationDB.androidMissingGPS,
    );
    final eTime = DateTime.now().microsecondsSinceEpoch;
    final d = Duration(microseconds: eTime - sTime);
    _logger.info(
      'importing completed, total files count ${fileLocalIDs.length} and took ${d.inSeconds.toString()} seconds',
    );
    await _prefs.setBool(_androidMissingGPSImportDone, true);
  }

  //#endregion Android Missing GPS specific methods ###

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
