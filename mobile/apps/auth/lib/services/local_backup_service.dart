import 'dart:convert';
import 'dart:io';
import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';  //for time based file naming
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  final _logger = Logger('LocalBackupService');
  static final LocalBackupService instance =
      LocalBackupService._privateConstructor();
  LocalBackupService._privateConstructor();

  // to create an encrypted backup file if the toggle is on
  Future<void> triggerAutomaticBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;
      if (!isEnabled) return;

      final backupPath = prefs.getString('autoBackupPath');
      if (backupPath == null) return;
      
      const storage = FlutterSecureStorage();
      final password = await storage.read(key: 'autoBackupPassword');
      if (password == null || password.isEmpty) {
        _logger.warning("Automatic backup skipped: password not set.");
        return;
      }

      _logger.info("Change detected, triggering automatic encrypted backup...");

      final plainTextContent = await CodeStore.instance.getCodesForExport();

      if (plainTextContent.trim().isEmpty) return;

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
      final fileName = 'ente-auth-auto-backup-$formattedDate.txt';

      final filePath = '$backupPath/$fileName';
      final backupFile = File(filePath);
      
      await backupFile.writeAsString(encryptedJson);

      _logger.info('Automatic encrypted backup successful! Saved to: $filePath');
    } catch (e, s) {
      _logger.severe('Silent error during automatic backup', e, s);
    }
  }
}