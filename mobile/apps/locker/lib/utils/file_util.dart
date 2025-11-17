import "dart:io";
import "dart:typed_data";

import "package:ente_ui/components/progress_dialog.dart";
import "package:ente_ui/utils/dialog_util.dart";
import "package:ente_ui/utils/toast_util.dart";
import "package:file_saver/file_saver.dart";
import "package:flutter/material.dart";
import "package:locker/l10n/l10n.dart";
import "package:locker/models/info/info_item.dart";
import "package:locker/services/collections/collections_service.dart";
import "package:locker/services/configuration.dart";
import "package:locker/services/files/download/file_downloader.dart";
import "package:locker/services/files/sync/models/file.dart";
import "package:locker/services/info_file_service.dart";
import "package:locker/ui/pages/account_credentials_page.dart";
import "package:locker/ui/pages/base_info_page.dart";
import "package:locker/ui/pages/emergency_contact_page.dart";
import "package:locker/ui/pages/personal_note_page.dart";
import "package:locker/ui/pages/physical_records_page.dart";
import "package:logging/logging.dart";
import "package:open_file/open_file.dart";
import "package:path/path.dart" as p;

class FileUtil {
  static final Logger _logger = Logger("FileUtil");

  static Future<void> openFile(BuildContext context, EnteFile file) async {
    if (InfoFileService.instance.isInfoFile(file)) {
      return _openInfoFile(context, file);
    }

    if (file.localPath != null) {
      final localFile = File(file.localPath!);
      if (await localFile.exists()) {
        await _launchFile(context, localFile, file.displayName);
        return;
      }
    }

    final String cachedFilePath =
        "${Configuration.instance.getCacheDirectory()}${file.displayName}";
    final File cachedFile = File(cachedFilePath);
    if (await cachedFile.exists()) {
      await _launchFile(context, cachedFile, file.displayName);
      return;
    }

    final dialog = createProgressDialog(
      context,
      context.l10n.downloading,
      isDismissible: false,
    );

    try {
      await dialog.show();
      final fileKey = await CollectionService.instance.getFileKey(file);
      final decryptedFile = await downloadAndDecrypt(
        file,
        fileKey,
        progressCallback: (downloaded, total) {
          if (total > 0 && downloaded >= 0) {
            final percentage =
                ((downloaded / total) * 100).clamp(0, 100).round();
            dialog.update(
              message: context.l10n.downloadingProgress(percentage),
            );
          } else {
            dialog.update(message: context.l10n.downloading);
          }
        },
        shouldUseCache: true,
      );

      await dialog.hide();

      if (decryptedFile != null) {
        await _launchFile(context, decryptedFile, file.displayName);
      } else {
        await showErrorDialog(
          context,
          context.l10n.downloadFailed,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
    } catch (e) {
      await dialog.hide();
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.errorOpeningFileMessage(e.toString()),
      );
    }
  }

  static Future<bool> downloadFile(
    BuildContext context,
    EnteFile file,
  ) {
    return _downloadFiles(context, [file]);
  }

  static Future<bool> downloadFiles(
    BuildContext context,
    List<EnteFile> files,
  ) {
    return _downloadFiles(context, files);
  }

  static Future<bool> _downloadFiles(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    if (files.isEmpty) {
      return false;
    }

    final total = files.length;
    final dialog = createProgressDialog(
      context,
      "${context.l10n.downloading} 0/$total",
      isDismissible: false,
    );

    await dialog.show();

    var index = 0;
    final savedNames = <String>[];
    final savedPaths = <String>[];
    var hasShownInfoSkipToast = false;

    try {
      for (final file in files) {
        index += 1;
        dialog.update(
          message:
              '${context.l10n.downloading} ${file.displayName} ($index/$total)',
        );

        // Skip info items for now; they are meant to be viewed in-app.
        if (InfoFileService.instance.isInfoFile(file)) {
          _logger.fine('Skipping info file download for ${file.displayName}');
          if (!hasShownInfoSkipToast) {
            hasShownInfoSkipToast = true;
            showToast(
              context,
              'Some items were skipped as they cannot be downloaded yet',
            );
          }
          continue;
        }

        final sanitizedName = _sanitizeFileName(file.displayName);
        final baseName = _baseNameWithoutExtension(sanitizedName);
        final fileExtension = _extensionWithoutDot(file.displayName);

        final String? savedPath = await _saveRegularFile(
          file: file,
          targetFileName:
              fileExtension.isEmpty ? baseName : "$baseName.$fileExtension",
          context: context,
          progressDialog: dialog,
          currentIndex: index,
          totalCount: total,
          fileExtension: fileExtension,
        );

        savedNames.add(file.displayName);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }

      if (savedNames.isNotEmpty) {
        final message = savedNames.length == 1
            ? '${savedNames.first} saved'
            : '${savedNames.length} files saved';
        _logger.info('Files saved: $savedPaths');
        showToast(context, message);
      }

      return true;
    } catch (e, s) {
      _logger.severe('Failed to save files', e, s);
      if (e is UnsupportedError) {
        showToast(
          context,
          'This file type is not supported for download',
        );
      } else {
        showToast(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
      return false;
    } finally {
      await dialog.hide();
    }
  }

  static Future<String?> _saveRegularFile({
    required EnteFile file,
    required String targetFileName,
    required BuildContext context,
    required ProgressDialog progressDialog,
    required int currentIndex,
    required int totalCount,
    required String fileExtension,
  }) async {
    final fileKey = await CollectionService.instance.getFileKey(file);

    final decryptedFile = await downloadAndDecrypt(
      file,
      fileKey,
      progressCallback: (downloaded, total) {
        if (total > 0 && downloaded >= 0) {
          final percentage = ((downloaded / total) * 100).clamp(0, 100).round();
          progressDialog.update(
            message:
                '${context.l10n.downloadingProgress(percentage)} ($currentIndex/$totalCount)',
          );
        }
      },
      shouldUseCache: false,
    );

    if (decryptedFile == null) {
      throw Exception('Failed to download ${file.displayName}');
    }

    try {
      // Use system file picker on both Android and iOS to let user
      // choose where to save the file.
      final fileBytes = await decryptedFile.readAsBytes();
      final baseName = _baseNameWithoutExtension(targetFileName);
      final savedPath = await _saveFile(
        bytes: fileBytes,
        fileName: baseName,
        fileExtension: fileExtension,
      );

      if (savedPath == null) {
        throw Exception('Failed to save file');
      }

      progressDialog.update(
        message:
            '${context.l10n.downloadingProgress(100)} ($currentIndex/$totalCount)',
      );
      return savedPath;
    } finally {
      try {
        await decryptedFile.delete();
      } catch (e) {
        _logger.fine(
          'Unable to delete temporary file ${decryptedFile.path}: $e',
        );
      }
    }
  }

  /// Saves files using the platform's system file picker.
  /// On Android and iOS this shows a system sheet allowing the user
  /// to choose where to save the file.
  static Future<String?> _saveFile({
    required Uint8List bytes,
    required String fileName,
    required String fileExtension,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.warning('File saving only supported on Android and iOS');
      return null;
    }

    try {
      final baseName = _baseNameWithoutExtension(fileName);

      final savedPath = await FileSaver.instance.saveAs(
        name: baseName,
        bytes: bytes,
        fileExtension: fileExtension,
        mimeType: MimeType.other,
      );

      _logger.info('File saved: $savedPath');
      return savedPath;
    } catch (e, s) {
      _logger.severe('Failed to save file', e, s);
      return null;
    }
  }

  static String _sanitizeFileName(String name) {
    final sanitized = name.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return sanitized.isEmpty ? "file" : sanitized;
  }

  static String _baseNameWithoutExtension(String name) {
    final base = p.basenameWithoutExtension(name).trim();
    return base.isEmpty ? "file" : base;
  }

  static String _extensionWithoutDot(String name) {
    final ext = p.extension(name);
    if (ext.isEmpty) {
      return '';
    }
    return ext.replaceAll('.', '').replaceAll(RegExp(r'[\\/:*?"<>|]'), '');
  }

  static Future<void> _openInfoFile(BuildContext context, EnteFile file) async {
    try {
      final infoItem = InfoFileService.instance.extractInfoFromFile(file);
      if (infoItem == null) {
        await showErrorDialog(
          context,
          context.l10n.errorOpeningFile,
          'Unable to extract information from this file',
        );
        return;
      }

      Widget page;
      switch (infoItem.type) {
        case InfoType.note:
          page = PersonalNotePage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.accountCredential:
          page = AccountCredentialsPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.physicalRecord:
          page = PhysicalRecordsPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
        case InfoType.emergencyContact:
          page = EmergencyContactPage(
            mode: InfoPageMode.view,
            existingFile: file,
          );
          break;
      }

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => page),
      );
    } catch (e) {
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        'Failed to open info file: ${e.toString()}',
      );
    }
  }

  static Future<void> _launchFile(
    BuildContext context,
    File file,
    String fileName,
  ) async {
    try {
      await OpenFile.open(file.path);
    } catch (e) {
      await showErrorDialog(
        context,
        context.l10n.errorOpeningFile,
        context.l10n.couldNotOpenFile(e.toString()),
      );
    }
  }
}
