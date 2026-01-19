import 'dart:collection';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file/local_attributes.dart';
import 'package:photos/models/location/location.dart';
import 'package:photos/utils/exif_util.dart';
import 'package:photos/utils/file_uploader_util.dart';

class LocalFileAttributesService {
  static final LocalFileAttributesService instance =
      LocalFileAttributesService._privateConstructor();

  LocalFileAttributesService._privateConstructor();

  final _logger = Logger('LocalFileAttributesService');
  final _filesDB = FilesDB.instance;
  final Queue<String> _queue = Queue<String>();
  final Set<String> _queuedLocalIDs = {};
  bool _isProcessing = false;

  void enqueueLocalIDs(Iterable<String?> localIDs) {
    if (!kDebugMode) {
      return;
    }
    var added = 0;
    for (final localID in localIDs) {
      if (localID == null || localID.isEmpty) {
        continue;
      }
      if (_queuedLocalIDs.add(localID)) {
        _queue.add(localID);
        added++;
      }
    }
    if (added > 0) {
      _processQueue();
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) {
      return;
    }
    _isProcessing = true;
    try {
      while (_queue.isNotEmpty) {
        final batch = <String>[];
        while (_queue.isNotEmpty && batch.length < 10) {
          final localID = _queue.removeFirst();
          _queuedLocalIDs.remove(localID);
          batch.add(localID);
        }
        final files = await _filesDB.getLocalFiles(
          batch,
          dedupeByLocalID: true,
        );
        for (final file in files) {
          if (file.localID == null || file.isUploaded) {
            continue;
          }
          await _applyLocalAttributes(file);
        }
      }
    } finally {
      _isProcessing = false;
    }
  }

  Future<bool> _applyLocalAttributes(EnteFile file) async {
    try {
      final mediaUploadData = await getUploadDataFromEnteFile(
        file,
        parseExif: true,
        includeHash: true,
        prepareLivePhotoUpload: false,
      );
      final exifTime = await tryParseExifDateTime(
        null,
        mediaUploadData.exifData,
      );
      await file.applyDerivedAttributes(
        mediaUploadData,
        exifTime,
        includeHash: false,
      );
      final Location? location =
          await _resolveLocalLocation(file, mediaUploadData);

      int? fileSize;
      if (mediaUploadData.sourceFile != null) {
        fileSize = await mediaUploadData.sourceFile!.length();
      }

      file.localAttributes = LocalFileAttributes(
        width: mediaUploadData.width,
        height: mediaUploadData.height,
        fileSize: fileSize,
        hash: mediaUploadData.hashData?.fileHash,
        latitude: location?.latitude,
        longitude: location?.longitude,
        cameraMake: mediaUploadData.cameraMake,
        cameraModel: mediaUploadData.cameraModel,
        motionPhotoStartIndex: mediaUploadData.motionPhotoStartIndex,
        isPanorama: mediaUploadData.isPanorama,
        noThumb: mediaUploadData.thumbnail == null,
        dateTime: exifTime?.dateTime,
        offsetTime: exifTime?.offsetTime,
      );
      file.localAttributesJson = file.localAttributes?.toEncodedJson();
      if (file.localID != null && file.localAttributesJson != null) {
        await _filesDB.upsertLocalAttributes(
          file.localID!,
          file.localAttributesJson!,
        );
      }
      await _deleteIosOriginFileIfNeeded(file, mediaUploadData.sourceFile);
      return true;
    } catch (e, s) {
      _logger.warning(
        'Failed to update local attributes for ${file.tag}',
        e,
        s,
      );
      return false;
    }
  }

  Future<Location?> _resolveLocalLocation(
    EnteFile file,
    MediaUploadData mediaUploadData,
  ) async {
    if (file.hasLocation) {
      return file.location;
    }
    final asset = await file.getAsset;
    if (asset != null) {
      final latLong = await asset.latlngAsync();
      final Location latLongLocation =
          Location(latitude: latLong.latitude, longitude: latLong.longitude);
      if (Location.isValidLocation(latLongLocation)) {
        return latLongLocation;
      }
    }
    if (file.fileType == FileType.video &&
        Platform.isAndroid &&
        mediaUploadData.sourceFile != null) {
      final props = await getVideoPropsAsync(mediaUploadData.sourceFile!);
      if (props?.location != null) {
        return props!.location;
      }
    }
    if (Platform.isAndroid && mediaUploadData.exifData != null) {
      final Location? exifLocation =
          locationFromExif(mediaUploadData.exifData!);
      if (Location.isValidLocation(exifLocation)) {
        return exifLocation;
      }
    }
    return null;
  }

  Future<void> _deleteIosOriginFileIfNeeded(
    EnteFile file,
    File? sourceFile,
  ) async {
    if (!Platform.isIOS || file.isSharedMediaToAppSandbox) {
      return;
    }
    if (sourceFile == null) {
      return;
    }
    try {
      if (await sourceFile.exists()) {
        await sourceFile.delete();
      }
    } catch (e, s) {
      _logger.warning('Failed to delete iOS origin file', e, s);
    }
  }
}
