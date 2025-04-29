import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/services/authenticator_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/ui/settings/data/import/import_success.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

Future<void> showEncryptedImportInstruction(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialogWidget(
    context: context,
    title: l10n.importFromApp("Ente Auth"),
    body: l10n.importEnteEncGuide,
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
      await _pickEnteJsonFile(context);
    } else {}
  }
}

Future<void> _decryptExportData(
  BuildContext context,
  EnteAuthExport enteAuthExport, {
  String? password,
}) async {
  final l10n = context.l10n;
  bool isPasswordIncorrect = false;
  int? importedCodeCount;
  await showTextInputDialog(
    context,
    title: l10n.passwordForDecryptingExport,
    submitButtonLabel: l10n.importLabel,
    hintText: l10n.enterYourPasswordHint,
    isPasswordInput: true,
    alwaysShowSuccessState: false,
    showOnlyLoadingState: true,
    onSubmit: (String password) async {
      if (password.isEmpty) {
        showToast(context, l10n.passwordEmptyError);
        Future.delayed(const Duration(seconds: 0), () {
          _decryptExportData(context, enteAuthExport, password: password);
        });
        return;
      }
      if (password.isNotEmpty) {
        final progressDialog = createProgressDialog(context, l10n.pleaseWait);
        try {
          await progressDialog.show();
          final derivedKey = await CryptoUtil.deriveKey(
            utf8.encode(password),
            CryptoUtil.base642bin(enteAuthExport.kdfParams.salt),
            enteAuthExport.kdfParams.memLimit,
            enteAuthExport.kdfParams.opsLimit,
          );
          Uint8List? decryptedContent;
          // Encrypt the key with this derived key
          try {
            decryptedContent = await CryptoUtil.decryptData(
              CryptoUtil.base642bin(enteAuthExport.encryptedData),
              derivedKey,
              CryptoUtil.base642bin(enteAuthExport.encryptionNonce),
            );
          } catch (e, s) {
            Logger("encryptedImport").warning('failed to decrypt', e, s);
            showToast(context, l10n.incorrectPasswordTitle);
            isPasswordIncorrect = true;
          }
          if (isPasswordIncorrect) {
            await progressDialog.hide();

            Future.delayed(const Duration(seconds: 0), () {
              _decryptExportData(context, enteAuthExport, password: password);
            });
            return;
          }
          String content = utf8.decode(decryptedContent!);
          List<String> splitCodes = content.split("\n");
          final parsedCodes = [];
          for (final code in splitCodes) {
            try {
              parsedCodes.add(Code.fromOTPAuthUrl(code));
            } catch (e) {
              Logger('EncryptedText').severe("Could not parse code", e);
            }
          }
          for (final code in parsedCodes) {
            await CodeStore.instance.addCode(code, shouldSync: false);
          }
          unawaited(AuthenticatorService.instance.onlineSync());
          importedCodeCount = parsedCodes.length;
          await progressDialog.hide();
        } catch (e, s) {
          await progressDialog.hide();
          Logger("ExportWidget").severe(e, s);
          showToast(context, "Error while exporting codes.");
        }
      }
    },
  );
  if (importedCodeCount != null) {
    await importSuccessDialog(context, importedCodeCount!);
  }
}

Future<void> _pickEnteJsonFile(BuildContext context) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();
  if (result == null) {
    return;
  }

  try {
    File file = File(result.files.single.path!);
    final jsonString = await file.readAsString();
    EnteAuthExport exportedData =
        EnteAuthExport.fromJson(jsonDecode(jsonString));
    await _decryptExportData(context, exportedData);
  } catch (e) {
    await showErrorDialog(
      context,
      context.l10n.sorry,
      context.l10n.importFailureDescNew,
    );
  }
}
