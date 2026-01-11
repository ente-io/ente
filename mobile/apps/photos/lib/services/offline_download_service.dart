import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/utils/file_util.dart';

class OfflineDownloadService {
  static final Logger _logger = Logger('OfflineDownloadService');
  static final OfflineDownloadService _instance =
      OfflineDownloadService._privateConstructor();

  OfflineDownloadService._privateConstructor();

  static OfflineDownloadService get instance => _instance;

  bool _isSyncing = false;

  /// Downloads all files marked for offline access that are not yet cached locally.
  Future<void> sync() async {
    if (_isSyncing) {
      _logger.info('Offline sync already in progress');
      return;
    }

    _isSyncing = true;
    try {
      final files = await FilesDB.instance.getOfflineAvailableFiles();
      if (files.isEmpty) {
        return;
      }

      final offlineDir = await _getOfflineDirectory();
      if (!await offlineDir.exists()) {
        await offlineDir.create(recursive: true);
      }

      for (final file in files) {
        if (file.uploadedFileID == null) continue;

        final fileId = file.uploadedFileID.toString();
        final savePath = p.join(offlineDir.path, fileId);
        final savedFile = File(savePath);

        // Check if file exists and has content
        if (await savedFile.exists()) {
          final len = await savedFile.length();
          if (len > 0) {
            // If we have file size metadata, verify it
            if (file.fileSize != null && len == file.fileSize) {
              continue;
            } else if (file.fileSize == null) {
              // Assume it's fine if we don't know the size
              continue;
            }
          }
        }

        await _downloadFile(file, savedFile);
      }
    } catch (e, stack) {
      _logger.severe('Error syncing offline files', e, stack);
    } finally {
      _isSyncing = false;
    }
  }

  Future<Directory> _getOfflineDirectory() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return Directory(p.join(appDocDir.path, 'offline_media'));
  }

  Future<void> _downloadFile(EnteFile file, File targetFile) async {
    try {
      _logger.info('Downloading file ${file.uploadedFileID} (${file.title})');
      final File? decryptedFile = await getFile(file);
      if (decryptedFile != null && await decryptedFile.exists()) {
        await decryptedFile.copy(targetFile.path);
      } else {
        _logger.warning(
          'Failed to download/decrypt file ${file.uploadedFileID}',
        );
      }
    } catch (e) {
      _logger.warning('Exception downloading ${file.uploadedFileID}', e);
      // Clean up partial file
      if (await targetFile.exists()) {
        await targetFile.delete();
      }
    }
  }

  /// Returns the local File if it exists in the offline cache, null otherwise.
  Future<File?> getOfflineFile(EnteFile file) async {
    if (file.uploadedFileID == null) return null;
    final offlineDir = await _getOfflineDirectory();
    final savePath = p.join(offlineDir.path, file.uploadedFileID.toString());
    final f = File(savePath);
    if (await f.exists() && await f.length() > 0) return f;
    return null;
  }

  Future<void> markForOfflineAccess(List<EnteFile> files) async {
    final ids = files
        .where((f) => f.generatedID != null)
        .map((e) => e.generatedID!)
        .toList();
    await FilesDB.instance.setOfflineAvailability(ids, true);
    sync();
  }

  Future<void> unmarkForOfflineAccess(List<EnteFile> files) async {
    final ids = files
        .where((f) => f.generatedID != null)
        .map((e) => e.generatedID!)
        .toList();
    await FilesDB.instance.setOfflineAvailability(ids, false);
  }
}
