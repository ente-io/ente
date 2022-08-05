import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/db/ignored_files_db.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/ignored_file.dart';

class IgnoredFilesService {
  final _logger = Logger("IgnoredFilesService");
  final _db = IgnoredFilesDB.instance;

  IgnoredFilesService._privateConstructor();

  static final IgnoredFilesService instance =
      IgnoredFilesService._privateConstructor();

  Future<Set<String>> _ignoredIDs;

  Future<Set<String>> get ignoredIDs async {
    // lazily instantiate the db the first time it is accessed
    _ignoredIDs ??= _loadExistingIDs();
    return _ignoredIDs;
  }

  Future<void> cacheAndInsert(List<IgnoredFile> ignoredFiles) async {
    final existingIDs = await ignoredIDs;
    existingIDs.addAll(
      ignoredFiles
          .map((e) => _idForIgnoredFile(e))
          .where((id) => id != null)
          .toSet(),
    );
    return _db.insertMultiple(ignoredFiles);
  }

  // shouldSkipUpload takes IDs to ignore and file for which it will return
  // whether either true or false. This helper method takes ignoredIDs as input
  // to avoid making it async in nature.
  // This syntax is intentional as we want to ensure that ignoredIDs are loaded
  // from the DB before calling this method.
  bool shouldSkipUpload(Set<String> ignoredIDs, File file) {
    final id = _getIgnoreID(file.localID, file.deviceFolder, file.title);
    if (id != null && id.isNotEmpty) {
      return ignoredIDs.contains(id);
    }
    return false;
  }

  Future<void> removeIgnoredMappings(List<File> files) async {
    List<IgnoredFile> ignoredFiles = [];
    Set<String> idsToRemoveFromCache = {};
    for (var file in files) {
      var ignoredFile = IgnoredFile.fromFile(file);
      if (ignoredFile != null) {
        ignoredFiles.add(ignoredFile);
        var id = _idForIgnoredFile(ignoredFile);
        if (id != null) {
          idsToRemoveFromCache.add(id);
        }
      }
    }
    if (ignoredFiles.isNotEmpty) {
      await _db.removeIgnoredEntries(ignoredFiles);
      final existingIDs = await ignoredIDs;
      existingIDs.removeAll(idsToRemoveFromCache);
    }
    return;
  }

  Future<Set<String>> _loadExistingIDs() async {
    _logger.fine('loading existing IDs');
    final result = await _db.getAll();
    return result
        .map((e) => _idForIgnoredFile(e))
        .where((id) => id != null)
        .toSet();
  }

  String _idForIgnoredFile(IgnoredFile ignoredFile) {
    return _getIgnoreID(
      ignoredFile.localID,
      ignoredFile.deviceFolder,
      ignoredFile.title,
    );
  }

  // _computeIgnoreID will return null if don't have sufficient information
  // to ignore the file based on the platform. Uploads from web or files shared to
  // end usually don't have local id.
  // For Android: It returns deviceFolder-title as ID for Android.
  // For iOS, it returns localID as localID is uuid and the title or deviceFolder (aka
  // album name) can be missing due to various reasons.
  String _getIgnoreID(String localID, String deviceFolder, String title) {
    // file was not uploaded from mobile device
    if (localID == null || localID.isEmpty) {
      return null;
    }
    if (Platform.isAndroid) {
      if (deviceFolder == null || title == null) {
        return null;
      }
      return '$deviceFolder-$title';
    } else {
      return localID;
    }
  }
}
