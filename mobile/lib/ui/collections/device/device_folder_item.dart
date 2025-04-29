import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/ui/viewer/file/file_icons_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';
import 'package:photos/utils/navigation_util.dart';

class DeviceFolderItem extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final double sideOfThumbnail;
  const DeviceFolderItem(
    this.deviceCollection, {
    ///120 is default for the 'on device' scrollview in albums section
    this.sideOfThumbnail = 120,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final isBackedUp = deviceCollection.shouldBackup;
    return GestureDetector(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: SizedBox(
              height: sideOfThumbnail,
              width: sideOfThumbnail,
              child: Hero(
                tag: "device_folder:" +
                    deviceCollection.name +
                    deviceCollection.thumbnail!.tag,
                transitionOnUserGestures: true,
                child: Stack(
                  children: [
                    ThumbnailWidget(
                      deviceCollection.thumbnail!,
                      shouldShowSyncStatus: false,
                      key: Key(
                        "device_folder:" +
                            deviceCollection.name +
                            deviceCollection.thumbnail!.tag,
                      ),
                    ),
                    isBackedUp ? const SizedBox.shrink() : const UnSyncedIcon(),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 2,
          ),
          SizedBox(
            width: sideOfThumbnail,
            child: Text(
              deviceCollection.name,
              textAlign: TextAlign.left,
              style: Theme.of(context).colorScheme.enteTheme.textTheme.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      onTap: () {
        routeToPage(context, DeviceFolderPage(deviceCollection));
      },
    );
  }
}
