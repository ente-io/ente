import 'dart:async';
import "dart:io";

import 'package:flutter/material.dart';
import "package:flutter/services.dart";
import "package:logging/logging.dart";
import 'package:photo_manager/photo_manager.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/settings/backup/backup_folder_selection_page.dart';
import "package:photos/utils/dialog_util.dart";
import 'package:photos/utils/navigation_util.dart';

class PreserveFooterWidget extends StatelessWidget {
  const PreserveFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: GradientButton(
        onTap: () async {
          try {
            final PermissionState state =
                await PhotoManager.requestPermissionExtend();
            await LocalSyncService.instance.onUpdatePermission(state);
          } on Exception catch (e) {
            Logger("PreserveFooterWidget").severe(
              "Failed to request permission: ${e.toString()}",
              e,
            );
          }
          if (!LocalSyncService.instance.hasGrantedFullPermission()) {
            if (Platform.isAndroid) {
              await PhotoManager.openSetting();
            } else {
              final bool hasGrantedLimit =
                  LocalSyncService.instance.hasGrantedLimitedPermissions();
              showChoiceActionSheet(
                context,
                title: S.of(context).preserveMore,
                body: S.of(context).grantFullAccessPrompt,
                firstButtonLabel: S.of(context).openSettings,
                firstButtonOnTap: () async {
                  await PhotoManager.openSetting();
                },
                secondButtonLabel: hasGrantedLimit
                    ? S.of(context).selectMorePhotos
                    : S.of(context).cancel,
                secondButtonOnTap: () async {
                  if (hasGrantedLimit) {
                    await PhotoManager.presentLimited();
                  }
                },
              );
            }
          } else {
            unawaited(
              routeToPage(
                context,
                 BackupFolderSelectionPage(
                  buttonText: S.of(context).backup,
                ),
              ),
            );
          }
        },
        text: S.of(context).preserveMore,
        iconData: Icons.cloud_upload_outlined,
      ),
    );
  }
}
