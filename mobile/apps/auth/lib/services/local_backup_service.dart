import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/services/secure_storage_service.dart';
import 'package:ente_auth/services/security_bookmark_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:saf_stream/saf_stream.dart';
import 'package:saf_util/saf_util.dart';
import 'package:security_scoped_resource/security_scoped_resource.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  LocalBackupService._();

  final _logger = Logger('LocalBackupService');
  static final LocalBackupService instance = LocalBackupService._();

  static const int _maxBackups = 5;
  static const _lastBackupDayKey = 'lastBackupDay';
  static const _iosBookmarkKey = 'autoBackupIosBookmark';

  Future<bool> triggerAutomaticBackup({bool isManual = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_isBackupEnabled(prefs)) return false;
      if (!isManual && _hasBackedUpToday(prefs)) return false;

      final _BackupTarget? target = _resolveTarget(prefs);
      if (target == null) return false;

      final String? password = await _readPassword();
      if (password == null || password.isEmpty) {
        _logger.warning('Automatic backup skipped: password not set.');
        return false;
      }

      final String? encryptedJson = await _buildEncryptedPayload(password);
      if (encryptedJson == null) return false;

      final now = DateTime.now();
      final fileName = _buildFileName(now, isManual: isManual);
      final writeSuccess = await _writeBackup(
        target: target,
        fileName: fileName,
        content: encryptedJson,
      );

      if (writeSuccess && !isManual) {
        await _recordBackupDay(prefs, now);
      }
      return writeSuccess;
    } catch (e, s) {
      if (isManual) {
        _logger.severe('Manual backup failed', e, s);
        rethrow;
      }
      _logger.severe('Silent error during automatic backup', e, s);
      return false;
    }
  }

  Future<bool> triggerDailyBackupIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (_hasBackedUpToday(prefs)) return false;
    return triggerAutomaticBackup();
  }

  /// Write backup to a directory that we already have scoped access to.
  /// Used on iOS where security-scoped access is held by caller.
  Future<bool> writeBackupToDirectory(String directoryPath) async {
    try {
      final String? password = await _readPassword();
      if (password == null || password.isEmpty) {
        _logger.warning('Backup skipped: password not set.');
        return false;
      }

      final String? encryptedJson = await _buildEncryptedPayload(password);
      if (encryptedJson == null) {
        _logger.warning('Backup skipped: no data to backup.');
        return false;
      }

      final now = DateTime.now();
      final fileName = _buildFileName(now, isManual: true);
      final filePath = '$directoryPath/$fileName';

      _logger.info('Writing backup to: $filePath');
      final backupFile = File(filePath);
      await backupFile.writeAsString(encryptedJson);
      _logger.info('Backup written successfully');

      await _manageOldBackups(directoryPath);

      final prefs = await SharedPreferences.getInstance();
      await _recordBackupDay(prefs, now);

      return true;
    } catch (e, s) {
      _logger.severe('Failed to write backup to directory: $e', e, s);
      return false;
    }
  }

  Future<bool> _writeBackup({
    required _BackupTarget target,
    required String fileName,
    required String content,
  }) async {
    try {
      if (target.treeUri != null) {
        await _writeBackupWithSaf(target.treeUri!, fileName, content);
        await _pruneSafBackups(target.treeUri!, limit: _maxBackups);
        return true;
      }

      final scopedDir = Directory(target.path!);
      // On iOS, saved path is the parent; we write to EnteAuthBackups subdirectory
      final backupDir = Platform.isIOS
          ? Directory('${scopedDir.path}/EnteAuthBackups')
          : scopedDir;

      Future<bool> doWrite() async {
        _logger.info('Creating backup directory: ${backupDir.path}');
        await backupDir.create(recursive: true);
        _logger.info('Backup directory created/exists');

        final filePath = '${backupDir.path}/$fileName';

        _logger.info('Writing backup file: $filePath');
        final backupFile = File(filePath);
        await backupFile.writeAsString(content);
        _logger.info('Backup file written successfully');

        await _manageOldBackups(backupDir.path);
        _logger
            .info('Automatic encrypted backup successful! Saved to: $filePath');
        return true;
      }

      // On iOS, we need to use security-scoped access
      if (Platform.isIOS) {
        final bookmark = target.iosBookmark;
        bool hasAccess = false;
        bool usingBookmark = false;

        // Try bookmark-based access first
        if (bookmark != null && bookmark.isNotEmpty) {
          _logger.info('iOS: Starting access via bookmark');
          final accessResult = await SecurityBookmarkService.instance
              .startAccessingBookmark(bookmark);
          if (accessResult != null && accessResult.success) {
            hasAccess = true;
            usingBookmark = true;
            if (accessResult.isStale) {
              _logger.warning(
                'iOS: Bookmark is stale, user may need to re-select directory',
              );
            }
            _logger.info('iOS: Scoped access granted via bookmark');
          } else {
            _logger.warning('iOS: Bookmark access failed, trying path-based');
          }
        }

        // Fallback to path-based access
        if (!hasAccess) {
          _logger.info('iOS: Trying path-based access for: ${scopedDir.path}');
          hasAccess = await SecurityScopedResource.instance
              .startAccessingSecurityScopedResource(scopedDir);
          _logger.info('iOS: Path-based access result: $hasAccess');
        }

        if (!hasAccess) {
          _logger
              .severe('iOS: All access methods failed for: ${scopedDir.path}');
          return false;
        }

        try {
          return await doWrite();
        } finally {
          if (usingBookmark && bookmark != null) {
            await SecurityBookmarkService.instance
                .stopAccessingBookmark(bookmark);
          } else {
            await SecurityScopedResource.instance
                .stopAccessingSecurityScopedResource(scopedDir);
          }
        }
      }

      return await doWrite();
    } catch (e, s) {
      _logger.severe('Failed to write backup: $e', e, s);
      return false;
    }
  }

  Future<void> _writeBackupWithSaf(
    String treeUri,
    String fileName,
    String content,
  ) async {
    final safStream = SafStream();
    await safStream.writeFileBytes(
      treeUri,
      fileName,
      'application/octet-stream',
      Uint8List.fromList(utf8.encode(content)),
      overwrite: true,
    );
    _logger.info('Automatic encrypted backup saved via SAF: $fileName');
  }

  Future<void> _pruneSafBackups(String treeUri, {required int limit}) async {
    try {
      final safUtil = SafUtil();
      final entries = await safUtil.list(treeUri);
      final backupFiles = entries
          .where((file) => !file.isDir && _isBackupFile(file.name))
          .toList();

      backupFiles.sort((a, b) {
        final timeCompare = a.lastModified.compareTo(b.lastModified);
        if (timeCompare != 0) return timeCompare;
        return a.name.compareTo(b.name);
      });

      while (backupFiles.length > limit) {
        final file = backupFiles.removeAt(0);
        await safUtil.delete(file.uri, file.isDir);
        _logger.info('Deleted old backup via SAF: ${file.name}');
      }
    } catch (e, s) {
      _logger.severe('Error pruning SAF backups', e, s);
    }
  }

  Future<void> _manageOldBackups(String backupPath) async {
    try {
      final directory = Directory(backupPath);
      final files = directory
          .listSync()
          .where(
            (entity) =>
                entity is File && _isBackupFile(entity.path.split('/').last),
          )
          .map((entity) => entity as File)
          .toList();

      files.sort((a, b) {
        final mtimeCompare =
            a.lastModifiedSync().compareTo(b.lastModifiedSync());
        if (mtimeCompare != 0) {
          return mtimeCompare;
        }
        return a.path.compareTo(b.path);
      });

      while (files.length > _maxBackups) {
        final fileToDelete = files.removeAt(0);
        await fileToDelete.delete();
        _logger.info('Deleted old backup: ${fileToDelete.path}');
      }
      _logger.info('Backup count is now ${files.length}. Cleanup complete.');
    } catch (e, s) {
      _logger.severe('Error during old backup cleanup', e, s);
    }
  }

  Future<void> deleteAllBackupsIn(String path, {String? iosBookmark}) async {
    try {
      final scopedDir = Directory(path);
      // On iOS, saved path is the parent; backups are in EnteAuthBackups subdirectory
      final backupDir =
          Platform.isIOS ? Directory('$path/EnteAuthBackups') : scopedDir;

      Future<void> doDelete() async {
        if (!await backupDir.exists()) {
          _logger.warning('Old backup directory not found. Nothing to delete.');
          return;
        }

        final files = backupDir
            .listSync()
            .where(
              (entity) =>
                  entity is File && _isBackupFile(entity.path.split('/').last),
            )
            .map((entity) => entity as File)
            .toList();

        if (files.isEmpty) {
          _logger.info('No old backup files found to delete.');
          return;
        }

        for (final file in files) {
          await file.delete();
          _logger.info('Deleted: ${file.path}');
        }
        _logger.info('Successfully cleaned up old backup location.');
      }

      // On iOS, we need to use security-scoped access
      if (Platform.isIOS) {
        bool hasAccess = false;
        bool usingBookmark = false;

        // Try bookmark-based access first
        if (iosBookmark != null && iosBookmark.isNotEmpty) {
          _logger.info('iOS: Starting access via bookmark for deletion');
          final accessResult = await SecurityBookmarkService.instance
              .startAccessingBookmark(iosBookmark);
          if (accessResult != null && accessResult.success) {
            hasAccess = true;
            usingBookmark = true;
            _logger.info('iOS: Scoped access granted via bookmark');
          } else {
            _logger.warning('iOS: Bookmark access failed, trying path-based');
          }
        }

        // Fallback to path-based access
        if (!hasAccess) {
          _logger.info('iOS: Trying path-based access for: ${scopedDir.path}');
          hasAccess = await SecurityScopedResource.instance
              .startAccessingSecurityScopedResource(scopedDir);
          _logger.info('iOS: Path-based access result: $hasAccess');
        }

        if (!hasAccess) {
          _logger
              .severe('iOS: All access methods failed for: ${scopedDir.path}');
          return;
        }

        try {
          await doDelete();
        } finally {
          if (usingBookmark && iosBookmark != null) {
            await SecurityBookmarkService.instance
                .stopAccessingBookmark(iosBookmark);
          } else {
            await SecurityScopedResource.instance
                .stopAccessingSecurityScopedResource(scopedDir);
          }
        }
      } else {
        await doDelete();
      }
    } catch (e, s) {
      _logger.severe('Error during full backup cleanup of old directory', e, s);
    }
  }

  bool _isBackupEnabled(SharedPreferences prefs) =>
      prefs.getBool('isAutoBackupEnabled') ?? false;

  _BackupTarget? _resolveTarget(SharedPreferences prefs) {
    final path = prefs.getString('autoBackupPath');
    final treeUri = prefs.getString('autoBackupTreeUri');
    final iosBookmark = prefs.getString(_iosBookmarkKey);

    if (treeUri != null && treeUri.isNotEmpty) {
      return _BackupTarget.saf(treeUri);
    }
    if (path != null && path.isNotEmpty) {
      return _BackupTarget.file(path, iosBookmark: iosBookmark);
    }
    return null;
  }

  Future<String?> _readPassword() async {
    try {
      return SecureStorageService.instance
          .read(SecureStorageService.autoBackupPasswordKey);
    } catch (e, s) {
      _logger.severe('Unable to read backup password', e, s);
      return null;
    }
  }

  Future<String?> _buildEncryptedPayload(String password) async {
    final rawContent = await CodeStore.instance.getCodesForExport();
    final cleanedLines = rawContent
        .split('\n')
        .map((line) {
          if (line.trim().isEmpty) return null;
          if (line.startsWith('"') && line.endsWith('"')) {
            return jsonDecode(line);
          }
          return line;
        })
        .whereType<String>()
        .toList();

    final plainTextContent = cleanedLines.join('\n');
    if (plainTextContent.trim().isEmpty) {
      return null;
    }

    final kekSalt = CryptoUtil.getSaltToDeriveKey();
    final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
      utf8.encode(password),
      kekSalt,
    );

    final encResult = await CryptoUtil.encryptData(
      utf8.encode(plainTextContent),
      derivedKeyResult.key,
    );

    final encContent = CryptoUtil.bin2base64(encResult.encryptedData!);
    final encNonce = CryptoUtil.bin2base64(encResult.header!);

    final data = EnteAuthExport(
      version: 1,
      encryptedData: encContent,
      encryptionNonce: encNonce,
      kdfParams: KDFParams(
        memLimit: derivedKeyResult.memLimit,
        opsLimit: derivedKeyResult.opsLimit,
        salt: CryptoUtil.bin2base64(kekSalt),
      ),
    );

    return jsonEncode(data.toJson());
  }

  String _buildFileName(DateTime now, {required bool isManual}) {
    final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final formattedDate = formatter.format(now);
    return isManual
        ? 'ente-auth-manual-backup-$formattedDate.json'
        : 'ente-auth-daily-backup-$formattedDate.json';
  }

  bool _hasBackedUpToday(SharedPreferences prefs) {
    final todayKey = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final last = prefs.getString(_lastBackupDayKey);
    return last == todayKey;
  }

  Future<void> _recordBackupDay(SharedPreferences prefs, DateTime now) async {
    final dayKey = DateFormat('yyyy-MM-dd').format(now);
    await prefs.setString(_lastBackupDayKey, dayKey);
  }

  bool _isBackupFile(String fileName) {
    return fileName.startsWith('ente-auth-daily-backup-') ||
        fileName.startsWith('ente-auth-manual-backup-') ||
        fileName.startsWith('ente-auth-auto-backup-');
  }
}

class _BackupTarget {
  const _BackupTarget.file(this.path, {this.iosBookmark}) : treeUri = null;
  const _BackupTarget.saf(this.treeUri)
      : path = null,
        iosBookmark = null;

  final String? path;
  final String? treeUri;
  final String? iosBookmark;

  bool get isSaf => treeUri != null;
}
