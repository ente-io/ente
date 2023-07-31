
import 'package:ente_auth/ui/settings/data/import/encrypted_ente_import.dart';
import 'package:ente_auth/ui/settings/data/import/plain_text_import.dart';
import 'package:ente_auth/ui/settings/data/import/raivo_plain_text_import.dart';
import 'package:ente_auth/ui/settings/data/import_page.dart';
import 'package:flutter/cupertino.dart';

class ImportService {

  static final ImportService _instance = ImportService._internal();
  factory ImportService() => _instance;
  ImportService._internal();

  Future<void> initiateImport(BuildContext context,ImportType type) async {
    if(type == ImportType.plainText) {
      showImportInstructionDialog(context);
    } else if(type == ImportType.ravio) {
      showRaivoImportInstruction(context);
    } else {
      showEncryptedImportInstruction(context);
    }
  }
}