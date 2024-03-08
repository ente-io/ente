import 'dart:convert';
import 'dart:io';

import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/crypto_util.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sodium/flutter_sodium.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'package:share_plus/share_plus.dart';

Future<void> handleExportClick(BuildContext context) async {
  final result = await showDialogWidget(
    context: context,
    title: context.l10n.selectExportFormat,
    body: context.l10n.exportDialogDesc,
    buttons: [
      ButtonWidget(
        buttonType: ButtonType.primary,
        labelText: context.l10n.encrypted,
        isInAlert: true,
        buttonSize: ButtonSize.large,
        buttonAction: ButtonAction.first,
      ),
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.plainText,
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.second,
      ),
    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    if (result.action == ButtonAction.first) {
      await _requestForEncryptionPassword(context);
    } else {
      await _showExportWarningDialog(context);
    }
  }
}

Future<void> _requestForEncryptionPassword(
  BuildContext context, {
  String? password,
}) async {
  final l10n = context.l10n;
  await showTextInputDialog(
    context,
    title: l10n.passwordToEncryptExport,
    submitButtonLabel: l10n.export,
    hintText: l10n.enterPassword,
    isPasswordInput: true,
    alwaysShowSuccessState: false,
    onSubmit: (String password) async {
      if (password.isEmpty || password.length < 4) {
        showToast(context, "Password must be at least 4 characters long.");
        Future.delayed(const Duration(seconds: 0), () {
          _requestForEncryptionPassword(context, password: password);
        });
        return;
      }
      if (password.isNotEmpty) {
        try {
          final kekSalt = CryptoUtil.getSaltToDeriveKey();
          final derivedKeyResult = await CryptoUtil.deriveSensitiveKey(
            utf8.encode(password) as Uint8List,
            kekSalt,
          );
          String exportPlainText = await _getAuthDataForExport();
          // Encrypt the key with this derived key
          final encResult = await CryptoUtil.encryptChaCha(
            utf8.encode(exportPlainText) as Uint8List,
            derivedKeyResult.key,
          );
          final encContent = Sodium.bin2base64(encResult.encryptedData!);
          final encNonce = Sodium.bin2base64(encResult.header!);
          final EnteAuthExport data = EnteAuthExport(
            version: 1,
            encryptedData: encContent,
            encryptionNonce: encNonce,
            kdfParams: KDFParams(
              memLimit: derivedKeyResult.memLimit,
              opsLimit: derivedKeyResult.opsLimit,
              salt: Sodium.bin2base64(kekSalt),
            ),
          );
          // get json value of data
          await _exportCodes(context, jsonEncode(data.toJson()));
        } catch (e, s) {
          Logger("ExportWidget").severe(e, s);
          showToast(context, "Error while exporting codes.");
        }
      }
    },
  );
}

Future<void> _showExportWarningDialog(BuildContext context) async {
  await showChoiceActionSheet(
    context,
    title: context.l10n.warning,
    body: context.l10n.exportWarningDesc,
    isCritical: true,
    firstButtonOnTap: () async {
      final data = await _getAuthDataForExport();
      await _exportCodes(context, data);
    },
    secondButtonLabel: context.l10n.cancel,
    firstButtonLabel: context.l10n.iUnderStand,
  );
}

Future<void> _exportCodes(BuildContext context, String fileContent) async {
  DateTime now = DateTime.now().toUtc();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  String exportFileName = 'ente-auth-codes-$formattedDate.txt';
  final _codeFile = File(
    Configuration.instance.getTempDirectory() + exportFileName,
  );
  final hasAuthenticated = await LocalAuthenticationService.instance
      .requestLocalAuthentication(context, context.l10n.authToExportCodes);
  if (!hasAuthenticated) {
    return;
  }
  if (_codeFile.existsSync()) {
    await _codeFile.delete();
  }
  _codeFile.writeAsStringSync(fileContent);
  final Size size = MediaQuery.of(context).size;

  if (Platform.isAndroid) {
    await FileSaver.instance.saveAs(
      name: exportFileName,
      filePath: _codeFile.path,
      mimeType: MimeType.text,
      ext: 'txt',
    );
  } else {
    await Share.shareFiles(
      [_codeFile.path],
      sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
    );
  }
  Future.delayed(const Duration(seconds: 30), () async {
    if (_codeFile.existsSync()) {
      _codeFile.deleteSync();
    }
  });
}

Future<String> _getAuthDataForExport() async {
  final codes = await CodeStore.instance.getAllCodes();
  String data = "";
  for (final code in codes) {
    data += code.rawData + "\n";
  }
  return data;
}
