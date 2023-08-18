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
import 'package:logging/logging.dart';

Future<void> showAegisImportInstruction(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: l10n.importFromApp("Aegis Authenticator"),
    body: l10n.importAegisGuide,
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
      await _pickRaivoJsonFile(context);
    } else {}
  }
}

Future<void> _pickRaivoJsonFile(BuildContext context) async {
  final l10n = context.l10n;
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result == null) {
    return;
  }
  final progressDialog = createProgressDialog(context, l10n.pleaseWait);
  await progressDialog.show();
  try {
    String path = result.files.single.path!;
    int? count = await _processRaivoExportFile(context, path);
    await progressDialog.hide();
    if (count != null) {
      await importSuccessDialog(context, count);
    }
  } catch (e, s) {
    Logger('AegisImport').severe('exception while processing for aegis', e, s);
    await progressDialog.hide();
    await showErrorDialog(
      context,
      context.l10n.sorry,
      context.l10n.importFailureDesc,
    );
  }
}

Future<int?> _processRaivoExportFile(BuildContext context, String path) async {
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
  final decodedJson = jsonDecode(jsonString);
  int version = decodedJson['db']['version'];
  final parsedCodes = [];
  for (var item in decodedJson['db']['entries']) {
    var kind = item['type'];
    var account = item['name'];
    var issuer = item['issuer'];
    var algorithm = item['info']['algo'];
    var secret = item['info']['secret'];
    var timer = item['info']['period'];
    var digits = item['info']['digits'];

    var counter = item['info']['counter'];

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

  for (final code in parsedCodes) {
    await CodeStore.instance.addCode(code, shouldSync: false);
  }
  unawaited(AuthenticatorService.instance.sync());
  int count = parsedCodes.length;
  return count;
}
