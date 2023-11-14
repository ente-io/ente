import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/settings/data/import/import_success.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<void> showBitwardenImportInstruction(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: l10n.importFromApp("Bitwarden"),
    body: l10n.importBitwardenGuide,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: l10n.importSelectJsonFile,
        isInAlert: true,
        buttonSize: ButtonSize.large,
        buttonAction: ButtonAction.first,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.cancel,
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    if (result.action == ButtonAction.first) {
      await _pickBitwardenJsonFile(context);
    } else {}
  }
}

Future<void> _pickBitwardenJsonFile(BuildContext context) async {
  final l10n = context.l10n;
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result == null) {
    return;
  }
  final progressDialog = createProgressDialog(context, l10n.pleaseWait);
  await progressDialog.show();
  try {
    String path = result.files.single.path!;
    int? count = await _processBitwardenExportFile(context, path);
    await progressDialog.hide();
    if (count != null) {
      await importSuccessDialog(context, count);
    }
  } catch (e) {
    await progressDialog.hide();
    await showErrorDialog(
      context,
      context.l10n.sorry,
      context.l10n.importFailureDesc,
    );
  }
}

Future<int?> _processBitwardenExportFile(
  BuildContext context,
  String path,
) async {
  File file = File(path);
  if (path.endsWith('.zip')) {
    await showErrorDialog(
      context,
      context.l10n.sorry,
      "We don't support zip files yet. Please unzip the file and try again.",
    );
    return null;
  }
  final jsonString = await file.readAsString();
  List<dynamic> jsonArray = jsonDecode(jsonString);
  final parsedCodes = [];
  for (var item in jsonArray) {
    if (item['login']['totp'] != null) {
      var issuer = item['name'];
      var account = item['login']['username'];
      var secret = item['login']['totp'];

      // Build the OTP URL
      String otpUrl;

      if (kind.toLowerCase() == 'totp') {
        otpUrl =
            'otpauth://$kind/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&period=$timer';
      } else if (kind.toLowerCase() == 'hotp') {
        otpUrl =
            'otpauth://$kind/$issuer:$account?secret=$secret&issuer=$issuer&algorithm=$algorithm&digits=$digits&counter=$counter';
      } else {
        throw Exception('Invalid OTP type');
      }
      parsedCodes.add(Code.fromRawData(otpUrl));
    }
  }

  for (final code in parsedCodes) {
    await CodeStore.instance.addCode(code, shouldSync: false);
  }
  unawaited(AuthenticatorService.instance.onlineSync());
  int count = parsedCodes.length;
  return count;
}
