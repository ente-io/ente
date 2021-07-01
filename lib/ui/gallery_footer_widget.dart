import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/backup_folder_selection_widget.dart';

class GalleryFooterWidget extends StatelessWidget {
  const GalleryFooterWidget({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(padding: EdgeInsets.all(12)),
        Divider(
          height: 1,
          color: Theme.of(context).buttonColor.withOpacity(0.4),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(28, 36, 28, 46),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.fromLTRB(50, 20, 50, 20),
              side: BorderSide(
                width: 2,
                color: Theme.of(context).buttonColor.withOpacity(1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.all(6)),
                Text(
                  "preserve more",
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            onPressed: () async {
              if (LocalSyncService.instance.hasGrantedLimitedPermissions()) {
                await PhotoManager.presentLimited();
              } else {
                _showBackupFolderSelectionWidget(context);
              }
            },
          ),
        ),
      ],
    );
  }

  void _showBackupFolderSelectionWidget(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: const BackupFolderSelectionWidget("preserve"),
          backgroundColor: Color.fromRGBO(8, 18, 18, 1),
          insetPadding: const EdgeInsets.all(24),
          contentPadding: const EdgeInsets.all(24),
        );
      },
      barrierColor: Colors.black.withOpacity(0.85),
    );
  }
}
