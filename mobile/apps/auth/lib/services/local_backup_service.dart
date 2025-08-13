import 'dart:io'; 

import 'package:ente_auth/store/code_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalBackupService {
  static final LocalBackupService instance =
      LocalBackupService._privateConstructor();
  LocalBackupService._privateConstructor();

  Future<void> init() async {}

  Future<void> triggerAutomaticBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isEnabled = prefs.getBool('isAutoBackupEnabled') ?? false;    //checks if toggle is on
      if (!isEnabled) return;

      final backupPath = prefs.getString('autoBackupPath');
      if (backupPath == null) return;

      debugPrint("--- Change detected, triggering automatic backup... ---");

      final allCodes = await CodeStore.instance.getAllCodes(sortCodes: false);
      final validCodes = allCodes.where((code) => !code.hasError);
      String backupContent = "";
      for (final code in validCodes) {
        backupContent += "${code.toOTPAuthUrlFormat()}\n";
      }

      if (backupContent.trim().isEmpty) return;

      final fileName = 'ente-auth-auto-backup.txt';
      final filePath = '$backupPath/$fileName';
      final backupFile = File(filePath);
      await backupFile.writeAsString(backupContent);

      debugPrint('Automatic backup successful! Saved to: $filePath');
    } catch (e, s) {
      debugPrint('Silent error during automatic backup: $e\n$s');
    }
  }
}