import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animations/loading_animations.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/sync_status_update_event.dart';
import 'package:photos/ui/backup_folder_selection_widget.dart';

class LoadingPhotosPage extends StatefulWidget {
  const LoadingPhotosPage({Key key}) : super(key: key);

  @override
  _LoadingPhotosPageState createState() => _LoadingPhotosPageState();
}

class _LoadingPhotosPageState extends State<LoadingPhotosPage> {
  StreamSubscription<SyncStatusUpdate> _firstImportEvent;

  @override
  void initState() {
    super.initState();
    _firstImportEvent =
        Bus.instance.on<SyncStatusUpdate>().listen((event) async {
      if (mounted &&
          event.status == SyncStatus.completed_first_gallery_import) {
        showBackupFolderSelectionDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _firstImportEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            LoadingBouncingGrid.square(
              inverted: true,
              backgroundColor: Theme.of(context).buttonColor,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "hang on tight, your photos will appear in a jiffy! 🐣",
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
