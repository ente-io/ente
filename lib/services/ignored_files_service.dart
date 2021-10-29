import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:photos/db/ignored_files_db.dart';
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
    existingIDs.addAll(ignoredFiles.map((e) => _iDForIgnoredFile(e)).toSet());
    return _db.insertMultiple(ignoredFiles);
  }

  Future<Set<String>> _loadExistingIDs() async {
    final result = await _db.getAll();
    return result.map((e) => _iDForIgnoredFile(e)).toSet();
  }

  String _iDForIgnoredFile(IgnoredFile ignoredFile) {
    return _geIgnoreID(
        ignoredFile.localID, ignoredFile.deviceFolder, ignoredFile.title);
  }

  // _computeIgnoreID will return null if don't have sufficient information
  // to ignore the file based on the platform
  String _geIgnoreID(String localID, String deviceFolder, String title) {
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
