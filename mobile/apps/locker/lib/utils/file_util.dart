import "dart:convert";
import "dart:io";
import "dart:typed_data";

import "package:ente_ui/components/progress_dialog.dart";
import "package:ente_ui/utils/dialog_util.dart";
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
import "package:locker/utils/snack_bar_utils.dart";
import "package:logging/logging.dart";
import "package:open_file/open_file.dart";
import "package:path/path.dart" as p;
import "package:photo_manager/photo_manager.dart";

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

  static Future<bool> downloadFilesToDownloads(
    BuildContext context,
    List<EnteFile> files,
  ) async {
    if (files.isEmpty) {
      return false;
    }

    if (!(Platform.isAndroid || Platform.isIOS)) {
      SnackBarUtils.showWarningSnackBar(
        context,
        'Downloads are only supported on Android and iOS',
      );
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

    try {
      for (final file in files) {
        index += 1;
        dialog.update(
          message:
              '${context.l10n.downloading} ${file.displayName} ($index/$total)',
        );

        final sanitizedName = _sanitizeFileName(file.displayName);
        final baseName = _baseNameWithoutExtension(sanitizedName);

        final extension = _extensionWithoutDot(sanitizedName);
        if (InfoFileService.instance.isInfoFile(file)) {
          final infoFileName =
              baseName.endsWith('.json') ? baseName : "$baseName.json";
          final savedPath = await _saveInfoFile(
            file: file,
            fileName: infoFileName,
            context: context,
            progressDialog: dialog,
            currentIndex: index,
            totalCount: total,
          );
          savedNames.add(file.displayName);
          if (savedPath != null) {
            savedPaths.add(savedPath);
          }
          continue;
        }

        if (!_isSupportedExtension(extension)) {
          throw UnsupportedError('Unsupported file type for download');
        }

        final targetFileName =
            extension.isEmpty ? baseName : "$baseName.$extension";

        final savedPath = await _saveRegularFile(
          file: file,
          targetFileName: targetFileName,
          context: context,
          progressDialog: dialog,
          currentIndex: index,
          totalCount: total,
          extension: extension,
        );
        savedNames.add(file.displayName);
        if (savedPath != null) {
          savedPaths.add(savedPath);
        }
      }

      if (savedNames.isNotEmpty) {
        final message = savedNames.length == 1
            ? '${savedNames.first} saved to Downloads'
            : '${savedNames.length} files saved to Downloads';
        _logger.info('Files saved: $savedPaths');
        SnackBarUtils.showInfoSnackBar(context, message);
      }

      return true;
    } catch (e, s) {
      _logger.severe('Failed to save files to Downloads', e, s);
      if (e is UnsupportedError) {
        SnackBarUtils.showWarningSnackBar(
          context,
          'This file type is not supported for download',
        );
      } else {
        SnackBarUtils.showWarningSnackBar(
          context,
          context.l10n.failedToDownloadOrDecrypt,
        );
      }
      return false;
    } finally {
      await dialog.hide();
    }
  }

  static Future<String?> _saveInfoFile({
    required EnteFile file,
    required String fileName,
    required BuildContext context,
    required ProgressDialog progressDialog,
    required int currentIndex,
    required int totalCount,
  }) async {
    final infoItem = InfoFileService.instance.extractInfoFromFile(file);
    if (infoItem == null) {
      throw Exception('Unable to extract information from ${file.displayName}');
    }

    final payload = <String, dynamic>{
      'title': file.displayName,
      'type': infoItem.type.name,
      'data': infoItem.data.toJson(),
    };

    if (file.creationTime != null) {
      payload['createdAt'] =
          DateTime.fromMillisecondsSinceEpoch(file.creationTime!)
              .toUtc()
              .toIso8601String();
    }
    if (file.modificationTime != null) {
      payload['updatedAt'] =
          DateTime.fromMillisecondsSinceEpoch(file.modificationTime!)
              .toUtc()
              .toIso8601String();
    }

    const encoder = JsonEncoder.withIndent('  ');
    final bytes = Uint8List.fromList(utf8.encode(encoder.convert(payload)));

    // Save JSON file to Downloads directory
    final String? savedPath = await _saveFileToDownloads(
      bytes: bytes,
      fileName: fileName,
      extension: 'json',
    );

    if (savedPath == null) {
      throw Exception('Unable to save ${file.displayName}');
    }

    progressDialog.update(
      message:
          '${context.l10n.downloadingProgress(100)} ($currentIndex/$totalCount)',
    );

    return savedPath;
  }

  static Future<String?> _saveRegularFile({
    required EnteFile file,
    required String targetFileName,
    required BuildContext context,
    required ProgressDialog progressDialog,
    required int currentIndex,
    required int totalCount,
    required String extension,
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
      // Determine file type and use appropriate save method
      final isImage = _isImageExtension(extension);
      String? savedPath;

      if (isImage) {
        // Save images to gallery using PhotoManager
        final assetEntity = await PhotoManager.editor.saveImageWithPath(
          decryptedFile.path,
          title: targetFileName,
        );
        savedPath = assetEntity.relativePath;
      } else {
        // For PDFs, text files, and other non-image files
        final fileBytes = await decryptedFile.readAsBytes();
        savedPath = await _saveFileToDownloads(
          bytes: fileBytes,
          fileName: targetFileName,
          extension: extension,
        );
        if (savedPath == null) {
          throw Exception('Failed to save file to Downloads');
        }
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

  static bool _isImageExtension(String extension) {
    const imageExtensions = <String>{
      'png',
      'jpg',
      'jpeg',
      'gif',
      'heic',
      'heif',
      'webp',
      'svg',
    };
    return imageExtensions.contains(extension.toLowerCase());
  }

  /// Saves non-image files (PDF, TXT, JSON) to Downloads folder
  /// Returns the path where the file was saved, or null if it failed
  static Future<String?> _saveFileToDownloads({
    required Uint8List bytes,
    required String fileName,
    required String extension,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      _logger.warning('Downloads folder only supported on Android and iOS');
      return null;
    }

    if (Platform.isAndroid) {
      // For Android, use direct file write to Downloads
      // This works for Android 10 and below with WRITE_EXTERNAL_STORAGE permission
      // For Android 11+, we rely on the app having MANAGE_EXTERNAL_STORAGE or use SAF
      try {
        const downloadsPath = '/storage/emulated/0/Download';
        final sanitizedName = _sanitizeFileName(fileName);
        final fullFileName =
            extension.isEmpty ? sanitizedName : '$sanitizedName.$extension';
        final targetFile = File('$downloadsPath/$fullFileName');

        await targetFile.writeAsBytes(bytes);
        _logger.info('File saved to: ${targetFile.path}');
        return targetFile.path;
      } catch (e, s) {
        _logger.severe('Failed to save file to Downloads on Android', e, s);
        return null;
      }
    } else {
      // iOS doesn't have a public Downloads folder accessible to apps
      // Files must be saved to app-specific directories
      _logger.warning('iOS does not support saving to public Downloads folder');
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

  static bool _isSupportedExtension(String extension) {
    const supported = <String>{
      'png',
      'jpg',
      'jpeg',
      'gif',
      'heic',
      'heif',
      'webp',
      'svg',
      'pdf',
      'txt',
    };
    return supported.contains(extension.toLowerCase());
  }
}
