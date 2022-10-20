import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/common/gradient_button.dart';
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
          'No photos are being backed up right now',
          style: Theme.of(context)
              .textTheme
              .caption!
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
                  if (LocalSyncService.instance
                      .hasGrantedLimitedPermissions()) {
                    PhotoManager.presentLimited();
                  } else {
                    routeToPage(
                      context,
                      const BackupFolderSelectionPage(
                        buttonText: "Start backup",
                      ),
                    );
                  }
                },
                text: "Start backup",
              ),
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.all(50)),
      ],
    );
  }
}
