import 'dart:io';

import 'package:backup_exclusion/backup_exclusion.dart';
import 'package:ente_auth/l10n/l10n.dart';
import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/utils/dialog_util.dart';
import 'package:ente_qr/ente_qr.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const _pickedImagesDirectoryName = 'picked_images';

Future<Directory> _getPickedImagesDirectory({
  Future<Directory> Function()? documentsDirectoryProvider,
}) async {
  final documentsDirectory =
      await (documentsDirectoryProvider ?? getApplicationDocumentsDirectory)();
  return Directory(
    p.join(documentsDirectory.path, _pickedImagesDirectoryName),
  );
}

Future<File?> _getManagedPickedGalleryImage(
  String imagePath, {
  Future<Directory> Function()? documentsDirectoryProvider,
}) async {
  if (!Platform.isIOS) {
    return null;
  }

  final pickedImagesDirectory = await _getPickedImagesDirectory(
    documentsDirectoryProvider: documentsDirectoryProvider,
  );
  if (!p.isWithin(
    p.normalize(pickedImagesDirectory.path),
    p.normalize(imagePath),
  )) {
    return null;
  }
  return File(imagePath);
}

Future<void> _clearPickedImagesDirectoryContents(
  Directory pickedImagesDirectory, {
  Logger? logger,
}) async {
  try {
    await for (final entity in pickedImagesDirectory.list()) {
      await entity.delete(recursive: true);
    }
  } catch (e, stackTrace) {
    logger?.warning(
      'Failed to clear stale picked_images contents',
      e,
      stackTrace,
    );
  }
}

Future<void> _cleanupPickedGalleryImageIfNeeded(
  File imageFile, {
  Logger? logger,
}) async {
  if (!await imageFile.exists()) {
    return;
  }

  try {
    await imageFile.delete();
  } catch (e, stackTrace) {
    logger?.warning('Failed to delete picked gallery image', e, stackTrace);
  }
}

Future<void> cleanupPickedImagesOnStartup({
  Logger? logger,
}) async {
  if (!Platform.isIOS) {
    return;
  }

  final pickedImagesDirectory = await _getPickedImagesDirectory();
  if (!await pickedImagesDirectory.exists()) {
    return;
  }

  await excludeFromBackup(pickedImagesDirectory.path);
  await _clearPickedImagesDirectoryContents(
    pickedImagesDirectory,
    logger: logger,
  );
}

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
    final managedPickedImage = await _getManagedPickedGalleryImage(imagePath);
    if (managedPickedImage != null) {
      await excludeFromBackup(managedPickedImage.parent.path);
    }

    try {
      final qrResult = await EnteQr().scanQrFromImage(imagePath);

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
    } finally {
      if (managedPickedImage != null) {
        await _cleanupPickedGalleryImageIfNeeded(
          managedPickedImage,
          logger: logger,
        );
      }
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
