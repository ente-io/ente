import 'dart:io';

import 'package:locker/services/configuration.dart';
import 'package:locker/services/files/sync/models/file.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _offlineEncryptedDirName = 'offline_documents';
final _logger = Logger('OfflineFileStorage');

String _safeExtension(String fileName) {
  final ext = p.extension(p.basename(fileName));
  if (ext.isEmpty) return '';
  final sanitized = ext.replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  return sanitized == '.' ? '' : sanitized;
}

String getCachedEncryptedFilePath(EnteFile file) {
  final String cacheDir = Configuration.instance.getCacheDirectory();
  return "$cacheDir${file.uploadedFileID}.encrypted";
}

String getCachedDecryptedFilePath(EnteFile file) {
  final String cacheDir = Configuration.instance.getCacheDirectory();
  final String extension = _safeExtension(file.displayName);
  return "$cacheDir${file.uploadedFileID}.decrypted$extension";
}

Future<Directory> _getOfflineEncryptedDirectory() async {
  final supportDirectory = await getApplicationSupportDirectory();
  final directory = Directory(
    p.join(supportDirectory.path, _offlineEncryptedDirName),
  );
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }
  return directory;
}

Future<String> getOfflineEncryptedFilePath(EnteFile file) async {
  final directory = await _getOfflineEncryptedDirectory();
  return p.join(directory.path, '${file.uploadedFileID}.encrypted');
}

Future<File?> getCurrentOfflineEncryptedCopy(EnteFile file) async {
  final finalPath = await getOfflineEncryptedFilePath(file);
  final encryptedFile = File(finalPath);
  if (await encryptedFile.exists()) {
    final encryptedSize = await encryptedFile.length();
    if (encryptedSize > 0) {
      return encryptedFile;
    }
    _logger.warning(
      'Deleting empty offline encrypted copy for ${file.uploadedFileID}',
    );
    await encryptedFile.delete();
  }

  return null;
}

Future<void> removeOfflineFileCopiesFromDisk(
  Iterable<int> fileIds, {
  bool removeWorkingCopies = true,
}) async {
  final ids = fileIds.toSet();
  if (ids.isEmpty) {
    return;
  }

  _logger.fine(
    'Removing offline file copies for ${ids.length} files'
    ' (removeWorkingCopies=$removeWorkingCopies)',
  );

  await _deleteFilesFromDirectory(await _getOfflineEncryptedDirectory(), (
    baseName,
  ) {
    final fileId = _parseEncryptedFileId(baseName);
    return fileId != null && ids.contains(fileId);
  });

  if (!removeWorkingCopies) {
    return;
  }

  await _deleteCachedFileCopies(ids);
}

Future<void> clearAllOfflineFileCopies() async {
  _logger.info('Clearing all offline file copies');
  await _deleteFilesFromDirectory(
    await _getOfflineEncryptedDirectory(),
    (_) => true,
  );

  final cacheDirectory = Directory(Configuration.instance.getCacheDirectory());
  await _deleteFilesFromDirectory(cacheDirectory, _isOfflineWorkingCopyBaseName);
}

Future<void> cleanupOfflineWorkingFiles({
  Duration olderThan = Duration.zero,
}) async {
  _logger.fine('Cleaning offline working files older than $olderThan');
  final directory = Directory(Configuration.instance.getCacheDirectory());
  if (!await directory.exists()) {
    return;
  }

  final now = DateTime.now();
  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File) {
      continue;
    }

    final baseName = p.basename(entity.path);
    if (!_isOfflineWorkingCopyBaseName(baseName)) {
      continue;
    }

    try {
      if (olderThan > Duration.zero) {
        final stat = await entity.stat();
        if (now.difference(stat.modified) < olderThan) {
          continue;
        }
      }
      await entity.delete();
    } catch (e, s) {
      _logger.warning('Failed to delete cached offline working file', e, s);
    }
  }
}

bool _isOfflineWorkingCopyBaseName(String baseName) {
  return _parseEncryptedFileId(baseName) != null ||
      _parseCachedDecryptedFileId(baseName) != null;
}

int? _parseEncryptedFileId(String baseName) {
  final match = RegExp(r'^(\d+)\.encrypted$').firstMatch(baseName);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

int? _parseCachedDecryptedFileId(String baseName) {
  final match = RegExp(r'^(\d+)\.decrypted').firstMatch(baseName);
  if (match == null) {
    return null;
  }
  return int.tryParse(match.group(1)!);
}

Future<void> _deleteCachedFileCopies(Set<int> ids) async {
  final cacheDirectory = Directory(Configuration.instance.getCacheDirectory());
  await _deleteFilesFromDirectory(cacheDirectory, (baseName) {
    final encryptedId = _parseEncryptedFileId(baseName);
    if (encryptedId != null && ids.contains(encryptedId)) {
      return true;
    }

    final decryptedId = _parseCachedDecryptedFileId(baseName);
    return decryptedId != null && ids.contains(decryptedId);
  });
}

Future<void> _deleteFilesFromDirectory(
  Directory directory,
  bool Function(String baseName) shouldDelete,
) async {
  if (!await directory.exists()) {
    return;
  }

  await for (final entity in directory.list(followLinks: false)) {
    if (entity is! File) {
      continue;
    }

    final baseName = p.basename(entity.path);
    if (!shouldDelete(baseName)) {
      continue;
    }

    try {
      await entity.delete();
    } catch (e, s) {
      _logger.warning('Failed to delete offline file copy ${entity.path}', e, s);
    }
  }
}
