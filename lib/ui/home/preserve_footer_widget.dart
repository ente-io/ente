import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/settings/backup/backup_folder_selection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class PreserveFooterWidget extends StatelessWidget {
  const PreserveFooterWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: GradientButton(
        onTap: () async {
          if (LocalSyncService.instance.hasGrantedLimitedPermissions()) {
            await PhotoManager.presentLimited();
          } else {
            unawaited(
              routeToPage(
                context,
                const BackupFolderSelectionPage(
                  buttonText: "Preserve",
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
