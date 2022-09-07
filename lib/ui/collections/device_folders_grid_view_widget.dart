import 'package:flutter/material.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/services/local_sync_service.dart';
import 'package:photos/ui/collections/device_folder_icon_widget.dart';
import 'package:photos/ui/viewer/gallery/empte_state.dart';

class DeviceFoldersGridViewWidget extends StatelessWidget {
  final List<DeviceCollection> deviceCollections;

  const DeviceFoldersGridViewWidget(
    this.deviceCollections, {
    Key key,
  }) : super(key: key);

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
          child: deviceCollections.isEmpty
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
                    final deviceCollection = deviceCollections[index];
                    return DeviceFolderIcon(deviceCollection);
                  },
                  itemCount: deviceCollections.length,
                ),
        ),
      ),
    );
  }
}
