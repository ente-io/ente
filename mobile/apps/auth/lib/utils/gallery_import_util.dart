import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_qr/ente_qr.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

/// Prompts the user to pick an image and tries to extract an OTP code from it.
/// Returns the parsed code when successful, otherwise null.
Future<Code?> pickCodeFromGallery(
  BuildContext context, {
  Logger? logger,
}) async {
  final l10n = context.l10n;

  try {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result == null || result.files.single.path == null) {
      return null;
    }

    final String imagePath = result.files.single.path!;
    final enteQr = EnteQr();
    final QrScanResult qrResult = await enteQr.scanQrFromImage(imagePath);

    if (qrResult.success && qrResult.content != null) {
      try {
        return Code.fromOTPAuthUrl(qrResult.content!);
      } catch (e, stackTrace) {
        logger?.severe('Error adding code from QR scan', e, stackTrace);
        await showErrorDialog(
          context,
          l10n.errorInvalidQRCode,
          l10n.errorInvalidQRCodeBody,
        );
        return null;
      }
    } else {
      logger?.warning('QR scan failed: ${qrResult.error}');
      await showErrorDialog(
        context,
        l10n.errorNoQRCode,
        qrResult.error ?? l10n.errorNoQRCode,
      );
      return null;
    }
  } catch (e, stackTrace) {
    logger?.severe('Failed to import from gallery', e, stackTrace);
    await showErrorDialog(
      context,
      l10n.errorGenericTitle,
      l10n.errorGenericBody,
    );
    return null;
  }
}
