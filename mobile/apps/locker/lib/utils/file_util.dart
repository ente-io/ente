import "dart:io";

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
import "package:open_file/open_file.dart";

class FileUtil {
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
