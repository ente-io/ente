// @dart=2.9

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/collections/device_folder_icon_widget.dart';
import 'package:photos/ui/viewer/gallery/empte_state.dart';

class DeviceFoldersGridViewWidget extends StatefulWidget {
  final List<DeviceCollection> deviceCollections;

  const DeviceFoldersGridViewWidget(
    this.deviceCollections, {
    Key key,
  }) : super(key: key);

  @override
  State<DeviceFoldersGridViewWidget> createState() =>
      _DeviceFoldersGridViewWidgetState();
}

class _DeviceFoldersGridViewWidgetState
    extends State<DeviceFoldersGridViewWidget> {
  StreamSubscription<BackupFoldersUpdatedEvent> _backupFoldersUpdatedEvent;

  @override
  void initState() {
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMigrationDone =
        LocalSyncService.instance.isDeviceFileMigrationDone();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 170,
        child: Align(
          alignment: Alignment.centerLeft,
          child: widget.deviceCollections.isEmpty
              ? (isMigrationDone
                  ? const EmptyState()
                  : const EmptyState(
                      text: "Importing....",
                    ))
              : ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                  physics: const ScrollPhysics(),
                  // to disable GridView's scrolling
                  itemBuilder: (context, index) {
                    final deviceCollection = widget.deviceCollections[index];
                    return DeviceFolderIcon(deviceCollection);
                  },
                  itemCount: widget.deviceCollections.length,
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    super.dispose();
  }
}
