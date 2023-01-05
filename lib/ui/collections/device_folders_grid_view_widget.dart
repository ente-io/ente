

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/collections/device_folder_icon_widget.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';

class DeviceFoldersGridViewWidget extends StatefulWidget {
  const DeviceFoldersGridViewWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<DeviceFoldersGridViewWidget> createState() =>
      _DeviceFoldersGridViewWidgetState();
}

class _DeviceFoldersGridViewWidgetState
    extends State<DeviceFoldersGridViewWidget> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  String _loadReason = "init";

  @override
  void initState() {
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      if (mounted) {
        setState(() {});
      }
    });
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("${(DeviceFoldersGridViewWidget).toString()} - $_loadReason");
    final logger = Logger((_DeviceFoldersGridViewWidgetState).toString());
    final bool isMigrationDone =
        LocalSyncService.instance.isDeviceFileMigrationDone();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 170,
        child: Align(
          alignment: Alignment.centerLeft,
          child: FutureBuilder<List<DeviceCollection>>(
            future: FilesDB.instance
                .getDeviceCollections(includeCoverThumbnail: true),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return snapshot.data!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(22),
                        child: (isMigrationDone
                            ? const EmptyState()
                            : const EmptyState(
                                text: "Importing....",
                              )),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                        physics: const ScrollPhysics(),
                        // to disable GridView's scrolling
                        itemBuilder: (context, index) {
                          final deviceCollection = snapshot.data![index];
                          return DeviceFolderIcon(deviceCollection);
                        },
                        itemCount: snapshot.data!.length,
                      );
              } else if (snapshot.hasError) {
                logger.severe("failed to load device gallery", snapshot.error);
                return const Text("Failed to load albums");
              } else {
                return const EnteLoadingWidget();
              }
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    _localFilesSubscription?.cancel();
    super.dispose();
  }
}
