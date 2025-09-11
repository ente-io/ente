import 'dart:convert';
import 'dart:io';
import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';  //for time based file naming
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';
//we gonn change

class LocalBackupService {
  final _logger = Logger('LocalBackupService');
  static final LocalBackupService instance =
      LocalBackupService._privateConstructor();
  LocalBackupService._privateConstructor();

  static const int _maxBackups = 2;

  // to create an encrypted backup file if the toggle is on
  Future<void> triggerAutomaticBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;
      if (!isEnabled) {
        return;
      }

      final backupPath = prefs.getString('autoBackupPath');
      if (backupPath == null) {
        return;
      }
      
      const storage = FlutterSecureStorage();
      final password = await storage.read(key: 'autoBackupPassword');
      if (password == null || password.isEmpty) {
        _logger.warning("Automatic backup skipped: password not set.");
        return;
      }

      _logger.info("Change detected, triggering automatic encrypted backup...");


      String rawContent = await CodeStore.instance.getCodesForExport();

      List<String> lines = rawContent.split('\n');
      List<String> cleanedLines = [];

      for (String line in lines) {
        if (line.trim().isEmpty) continue;
  
        String cleanUrl;
        if (line.startsWith('"') && line.endsWith('"')) {
          cleanUrl = jsonDecode(line); 
        }

        else {
          cleanUrl = line;
        }

        cleanedLines.add(cleanUrl);
      }

      final plainTextContent = cleanedLines.join('\n');

      if (plainTextContent.trim().isEmpty) {
        return;
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

      final EnteAuthExport data = EnteAuthExport(
        version: 1,
        encryptedData: encContent,
        encryptionNonce: encNonce,
        kdfParams: KDFParams(
          memLimit: derivedKeyResult.memLimit,
          opsLimit: derivedKeyResult.opsLimit,
          salt: CryptoUtil.bin2base64(kekSalt),
        ),
      );
      
      final encryptedJson = jsonEncode(data.toJson());

      final now = DateTime.now();
      final formatter = DateFormat('yyyy-MM-dd_HH-mm-ss');
      final formattedDate = formatter.format(now);
      final fileName = 'ente-auth-auto-backup-$formattedDate.json';

      final filePath = '$backupPath/$fileName';
      final backupFile = File(filePath);
      
      await backupFile.writeAsString(encryptedJson);
      await _manageOldBackups(backupPath);

      _logger.info('Automatic encrypted backup successful! Saved to: $filePath');
    } catch (e, s) {
      _logger.severe('Silent error during automatic backup', e, s);
    }
  }

  Future<void> _manageOldBackups(String backupPath) async {
    try {
      _logger.info("Checking for old backups to clean up...");
      final directory = Directory(backupPath);

      // fetch all filenames in the folder, filter out ente backup files
      final files = directory.listSync()
          .where((entity) =>
              entity is File &&
              entity.path.split('/').last.startsWith('ente-auth-auto-backup-'),)
          .map((entity) => entity as File)
          .toList();

      // sort the fetched files in asc order (oldest first because the name is a timestamp)
      files.sort((a, b) => a.path.compareTo(b.path));

      // if we have more files than our limit, delete the oldest ones (current limit=_maxBackups)
      while (files.length > _maxBackups) {
  // remove the oldest file (at index 0) from the list
  final fileToDelete = files.removeAt(0); 
  // and delete it from the device's storage..
  await fileToDelete.delete(); 
  _logger.info('Deleted old backup: ${fileToDelete.path}');
}
_logger.info('Backup count is now ${files.length}. Cleanup complete.');
    } catch (e, s) {
      _logger.severe('Error during old backup cleanup', e, s);
    }
  }

  Future<void> deleteAllBackupsIn(String path) async {
    try {
      _logger.info("Deleting all backups in old location: $path");
      final directory = Directory(path);

      if (!await directory.exists()) {
        _logger.warning("Old backup directory not found. Nothing to delete.");
        return;
      }

      final files = directory.listSync()
          .where((entity) =>
              entity is File &&
              entity.path.split('/').last.startsWith('ente-auth-auto-backup-'),)
          .map((entity) => entity as File)
          .toList();

      if (files.isEmpty) {
        _logger.info("No old backup files found to delete.");
        return;
      }
      
      for (final file in files) {
        await file.delete();
        _logger.info('Deleted: ${file.path}');
      }
      _logger.info("Successfully cleaned up old backup location.");

    } catch (e, s) {
      _logger.severe('Error during full backup cleanup of old directory', e, s);
    }
  }
}