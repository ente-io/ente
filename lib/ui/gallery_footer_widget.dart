import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/backup_folder_selection_page.dart';
import 'package:photos/ui/common/gradientButton.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:sqflite/utils/utils.dart';

class GalleryFooterWidget extends StatelessWidget {
  const GalleryFooterWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
      child: GradientButton(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          //mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_upload_outlined,
              color: Colors.white,
            ),
            Padding(padding: EdgeInsets.all(6)),
            Text("Preserve more",
                style: Theme.of(context)
                    .textTheme
                    .headline6
                    .copyWith(color: Colors.white)),
          ],
        ),
        linearGradientColors: const [
          Color(0xFF2CD267),
          Color(0xFF1DB954),
        ],
        onTap: () async {
          if (LocalSyncService.instance.hasGrantedLimitedPermissions()) {
            await PhotoManager.presentLimited();
          } else {
            routeToPage(
              context,
              BackupFolderSelectionPage(
                buttonText: "preserve",
              ),
            );
          }
        },
      ),
    );
  }
}
