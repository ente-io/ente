import 'package:ente_auth/ui/settings/data/import/aegis_import.dart';
import 'package:ente_auth/ui/settings/data/import/bitwarden_import.dart';
import 'package:ente_auth/ui/settings/data/import/encrypted_ente_import.dart';
import 'package:ente_auth/ui/settings/data/import/google_auth_import.dart';
import 'package:ente_auth/ui/settings/data/import/lastpass_import.dart';
import 'package:ente_auth/ui/settings/data/import/plain_text_import.dart';
import 'package:ente_auth/ui/settings/data/import/proton_import.dart';
import 'package:ente_auth/ui/settings/data/import/raivo_plain_text_import.dart';
import 'package:ente_auth/ui/settings/data/import/two_fas_import.dart';
import 'package:ente_auth/ui/settings/data/import_page.dart';
import 'package:flutter/cupertino.dart';

class ImportService {
  static final ImportService _instance = ImportService._internal();

  factory ImportService() => _instance;

  ImportService._internal();

  Future<void> initiateImport(BuildContext context, ImportType type) async {
    switch (type) {
      case ImportType.plainText:
        await showImportInstructionDialog(context);
        break;
      case ImportType.encrypted:
        await showEncryptedImportInstruction(context);
        break;
      case ImportType.ravio:
        await showRaivoImportInstruction(context);
        break;
      case ImportType.googleAuthenticator:
        await showGoogleAuthInstruction(context);
        // showToast(context, 'coming soon');
        break;
      case ImportType.aegis:
        await showAegisImportInstruction(context);
        break;
      case ImportType.twoFas:
        await show2FasImportInstruction(context);
        break;
      case ImportType.bitwarden:
        await showBitwardenImportInstruction(context);
        break;
      case ImportType.lastpass:
        await showLastpassImportInstruction(context);
        break;
      case ImportType.proton:
        await showProtonImportInstruction(context);
        break;
    }
  }
}
