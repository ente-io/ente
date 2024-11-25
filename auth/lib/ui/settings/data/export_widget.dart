import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:ente_auth/core/configuration.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/models/export/ente.dart';
import 'package:ente_auth/services/local_authentication_service.dart';
import 'package:ente_auth/store/code_store.dart';
import 'package:ente_auth/ui/components/buttons/button_widget.dart';
import 'package:ente_auth/ui/components/dialog_widget.dart';
import 'package:ente_auth/ui/components/models/button_type.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_auth/utils/platform_util.dart';
import 'package:ente_auth/utils/share_utils.dart';
import 'package:ente_auth/utils/toast_util.dart';
import 'package:ente_crypto_dart/ente_crypto_dart.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
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
      const ButtonWidget(
        buttonType: ButtonType.secondary,
        labelText: "HTML",
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
  String exportFileExtension = extension;
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
          exportFileExtension,
          CryptoUtil.strToBin(fileContent),
          MimeType.text,
        );
      },
      sendAction: () async {
        final codeFile = File(
          "${Configuration.instance.getTempDirectory()}$exportFileName.$exportFileExtension",
        );
        if (codeFile.existsSync()) {
          await codeFile.delete();
        }
        codeFile.writeAsStringSync(fileContent);
        final Size size = MediaQuery.of(context).size;
        await Share.shareXFiles(
          [XFile(codeFile.path)],
          sharePositionOrigin: Rect.fromLTWH(0, 0, size.width, size.height / 2),
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

Future<String> generateOTPEntryHtml(
  Code code,
  BuildContext context,
) async {
  final qrBase64 = await generateQRImageBase64(
    code.rawData,
  );
  return '''
      <div class="otp-entry">
        <p class="details">
          <p><span class="label">Account:</span> ${code.account}</p>
          <p><span class="label">Issuer:</span> ${code.issuer}</p>
          <p><span class="label">Type:</span> ${code.type.toString()}</p>
          <p><span class="label">Algorithm:</span> ${code.algorithm.toString()}</p>
          <p><span class="label">Digits:</span> ${code.digits}</p>
        </p>
        <p><span class="qr-code">
          <img src="data:image/png;base64,$qrBase64" alt="QR Code">
        </span></p>
      </div>
    ''';
}

Future<String> generateQRImageBase64(String data) async {
  final qrPainter = QrPainter(
    data: data,
    version: QrVersions.auto,
    eyeStyle: const QrEyeStyle(
      eyeShape: QrEyeShape.square,
      color: Colors.black,
    ),
    dataModuleStyle: const QrDataModuleStyle(
      dataModuleShape: QrDataModuleShape.square,
      color: Colors.black,
    ),
  );

  const size = 250.0;
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  qrPainter.paint(canvas, const Size(size, size));
  final picture = recorder.endRecording();
  final img = await picture.toImage(size.toInt(), size.toInt());
  final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
  final pngBytes = byteData!.buffer.asUint8List();

  return base64Encode(pngBytes);
}

Future<String> generateHtml(BuildContext context) async {
  DateTime now = DateTime.now().toUtc();
  String formattedDate = DateFormat('yyyy-MM-dd').format(now);
  final allCodes = await CodeStore.instance.getAllCodes();
  final List<String> enteries = [];

  for (final code in allCodes) {
    if (code.hasError) continue;
    final entry = await generateOTPEntryHtml(code, context);
    enteries.add(entry);
  }

  return '''
    <!DOCTYPE html>
    <html>
    <head>
      <title>OTP Data Export</title>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <style>
        html {
          font-size: 62.5%;
          box-sizing: border-box;
        }

        *, *:before, *:after {
          box-sizing: inherit;
        }

        body {
          font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif, "Apple Color Emoji", "Segoe UI Emoji", "Segoe UI Symbol";
          font-size: 1.6rem;
          line-height: 1.5;
          max-width: 80rem;
          margin: 0 auto;
          padding: 2rem;
          background-color: #f8f9fa;
          color: #212529;
        }

        .otp-entry {
          background: white;
          border-radius: 1.2rem;
          margin: 2.4rem 0;
          padding: 2.4rem;
          box-shadow: 0 0.2rem 1rem rgba(0, 0, 0, 0.08);
          transition: transform 0.2s ease, box-shadow 0.2s ease;
        }

        .otp-entry:hover {
          transform: translateY(-0.2rem);
          box-shadow: 0 0.4rem 1.5rem rgba(0, 0, 0, 0.12);
        }

        h1 {
          font-size: 3.2rem;
          font-weight: 700;
          color: #1a1a1a;
          text-align: center;
          margin: 3.2rem 0;
          letter-spacing: -0.02em;
        }

        h2 {
          font-size: 2.4rem;
          font-weight: 600;
          color: #2d2d2d;
          margin: 0 0 1.6rem 0;
          letter-spacing: -0.01em;
        }

        .details {
          margin: 1.6rem 0;
          font-size: 1.4rem;
        }

        .label {
          color: #6c757d;
          font-weight: 500;
          margin-right: 1.2rem;
          display: inline-block;
          min-width: 12rem;
        }

        .qr-code {
          margin-top: 2.4rem;
          text-align: center;
        }

        .qr-code img {
          max-width: 30rem;
          height: auto;
          border-radius: 0.8rem;
          box-shadow: 0 0.2rem 0.8rem rgba(0, 0, 0, 0.06);
        }

        p {
          margin: 0.8rem 0;
          line-height: 1.5;
        }

        .timestamp {
          text-align: center;
          color: #6c757d;
          margin: 2.4rem 0 4rem;
          font-size: 1.4rem;
          font-weight: 500;
        }

        @media (max-width: 600px) {
          html {
            font-size: 56.25%;
          }

          body {
            padding: 1.6rem;
          }

          .otp-entry {
            padding: 1.6rem;
            margin: 1.6rem 0;
          }

          .label {
            min-width: 9rem;
          }
        }
      </style>
    </head>
    <body>
      <h1>Ente OTP Codes Export</h1>
      <p class="timestamp">Export Date: $formattedDate</p>
      ${enteries.join('\n')}
    </body>
    </html>
  ''';
}

Future<String> _getAuthDataForExport() async {
  final allCodes = await CodeStore.instance.getAllCodes();
  String data = "";
  for (final code in allCodes) {
    if (code.hasError) continue;
    data += "${code.rawData.replaceAll(',', '%2C')}\n";
  }

  return data;
}
