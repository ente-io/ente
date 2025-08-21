import "dart:async";

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/generated/l10n.dart';
import "package:photos/service_locator.dart";
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/settings/backup/backup_folder_selection_page.dart';
import 'package:photos/utils/navigation_util.dart';

class StartBackupHookWidget extends StatelessWidget {
  final Widget headerWidget;

  const StartBackupHookWidget({super.key, required this.headerWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        headerWidget,
        Padding(
          padding: const EdgeInsets.only(top: 64),
          child: Image.asset(
            "assets/onboarding_safe.png",
            height: 206,
          ),
        ),
        Text(
          AppLocalizations.of(context).noPhotosAreBeingBackedUpRightNow,
          style: Theme.of(context)
              .textTheme
              .bodySmall!
              .copyWith(fontFamily: 'Inter-Medium', fontSize: 16),
        ),
        Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: double.infinity,
              height: 64,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: GradientButton(
                onTap: () async {
                  if (permissionService.hasGrantedLimitedPermissions()) {
                    unawaited(PhotoManager.presentLimited());
                  } else {
                    // ignore: unawaited_futures
                    routeToPage(
                      context,
                      const BackupFolderSelectionPage(
                        isFirstBackup: true,
                      ),
                    );
                  }
                },
                text: AppLocalizations.of(context).startBackup,
              ),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(50)),
      ],
    );
  }
}
