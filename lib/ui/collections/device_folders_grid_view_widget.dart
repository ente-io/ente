import 'package:flutter/material.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/collections/device_folder_icon_widget.dart';
import 'package:photos/ui/viewer/gallery/empte_state.dart';

class DeviceFoldersGridViewWidget extends StatelessWidget {
  final List<DeviceFolder> folders;

  const DeviceFoldersGridViewWidget(
    this.folders, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: SizedBox(
        height: 170,
        child: Align(
          alignment: Alignment.centerLeft,
          child: folders.isEmpty
              ? const EmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(6, 0, 6, 0),
                  physics: const ScrollPhysics(),
                  // to disable GridView's scrolling
                  itemBuilder: (context, index) {
                    return DeviceFolderIcon(folders[index]);
                  },
                  itemCount: folders.length,
                ),
        ),
      ),
    );
  }
}
