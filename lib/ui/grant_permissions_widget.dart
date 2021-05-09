import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/backup_folder_selection_widget.dart';
import 'package:photos/ui/progress_dialog.dart';
import 'package:photos/utils/dialog_util.dart';

class GrantPermissionsWidget extends StatefulWidget {
  @override
  _GrantPermissionsWidgetState createState() => _GrantPermissionsWidgetState();
}

class _GrantPermissionsWidgetState extends State<GrantPermissionsWidget> {
  final _logger = Logger("GrantPermissionsWidget");

  ProgressDialog _dialog;
  StreamSubscription<SyncStatusUpdate> _firstImportEvent;

  @override
  void initState() {
    super.initState();
    _dialog = createProgressDialog(
        context, "hang on tight, your photos will be loaded in a jiffy! 🐣");

    _firstImportEvent =
        Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (mounted &&
          event.status == SyncStatus.completed_first_gallery_import) {
        await _dialog.hide();
        showBackupFolderSelectionDialog(context);
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _firstImportEvent.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              "ente needs your permission to display your gallery",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: 64,
            padding: const EdgeInsets.fromLTRB(80, 0, 80, 0),
            child: RaisedButton(
              child: Text(
                "grant permission",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
              onPressed: () async {
                final granted = await PhotoManager.requestPermission();
                if (granted) {
                  await _dialog.show();
                  SyncService.instance.onPermissionGranted();
                }
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
