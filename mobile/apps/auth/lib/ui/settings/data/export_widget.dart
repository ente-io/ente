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
import 'package:ente_auth/ui/settings/data/html_export.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/share_utils.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: context.l10n.plainHTML,
        buttonSize: ButtonSize.large,
        isInAlert: true,
        buttonAction: ButtonAction.third,
      ),
    ],
  );
  if (result?.action != null && result!.action != ButtonAction.cancel) {
    if (result.action == ButtonAction.first) {
      await _requestForEncryptionPassword(context);
    } else if (result.action == ButtonAction.second) {
      await _showExportWarningDialog(context, "txt");
    } else if (result.action == ButtonAction.third) {
      await _showExportWarningDialog(context, "html");
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
            utf8.encode(password),
            kekSalt,
          );
          String exportPlainText = await _getAuthDataForExport();
          // Encrypt the key with this derived key
          final encResult = await CryptoUtil.encryptData(
            utf8.encode(exportPlainText),
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
          // get json value of data
          await _exportCodes(context, jsonEncode(data.toJson()), "txt");
        } catch (e) {
          showToast(context, "Error while exporting codes.");
        }
      }
    },
  );
}

Future<void> _showExportWarningDialog(BuildContext context, String type) async {
  await showChoiceActionSheet(
    context,
    title: context.l10n.warning,
    body: context.l10n.exportWarningDesc,
    isCritical: true,
    firstButtonOnTap: () async {
      if (type == "html") {
        final data = await generateHtml(context);
        await _exportCodes(context, data, type);
      } else {
        final data = await _getAuthDataForExport();
        await _exportCodes(context, data, type);
      }
    },
    secondButtonLabel: context.l10n.cancel,
    firstButtonLabel: context.l10n.iUnderStand,
  );
}

Future<void> _exportCodes(
  BuildContext context,
  String fileContent,
  String extension,
) async {
  DateTime now = DateTime.now().toUtc();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  String exportFileName = 'ente-auth-codes-$formattedDate';
  final hasAuthenticated = await LocalAuthenticationService.instance
      .requestLocalAuthentication(context, context.l10n.authToExportCodes);
  await PlatformUtil.refocusWindows();
  if (!hasAuthenticated) {
    return;
  }
  Future.delayed(
    const Duration(milliseconds: 1200),
    () async => await shareDialog(
      context,
      context.l10n.exportCodes,
      saveAction: () async {
        await PlatformUtil.shareFile(
          exportFileName,
          extension,
          CryptoUtil.strToBin(fileContent),
          MimeType.text,
        );
      },
      sendAction: () async {
        final codeFile = File(
          "${Configuration.instance.getTempDirectory()}$exportFileName.$extension",
        );
        if (codeFile.existsSync()) {
          await codeFile.delete();
        }
        codeFile.writeAsStringSync(fileContent);
        final Size size = MediaQuery.of(context).size;
        await SharePlus.instance.share(
          ShareParams(
            files: <XFile>[
              XFile(codeFile.path, mimeType: 'text/plain'),
            ],
            sharePositionOrigin:
                Rect.fromLTWH(0, 0, size.width, size.height / 2),
          ),
        );
        Future.delayed(const Duration(seconds: 30), () async {
          if (codeFile.existsSync()) {
            codeFile.deleteSync();
          }
        });
      },
    ),
  );
}

Future<String> _getAuthDataForExport() async {
  final allCodes = await CodeStore.instance.getAllCodes();
  String data = "";
  for (final code in allCodes) {
    if (code.hasError) continue;
    data +=
        "${code.rawData.replaceAll('algorithm=Algorithm.', 'algorithm=').replaceAll(',', '%2C')}\n";
  }

  return data;
}
