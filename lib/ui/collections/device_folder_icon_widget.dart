// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';
import 'package:photos/utils/navigation_util.dart';

class DeviceFolderIcon extends StatelessWidget {
  final DeviceCollection deviceCollection;
  const DeviceFolderIcon(
    this.deviceCollection, {
    Key key,
  }) : super(key: key);

  static final kUnsyncedIconOverlay = Container(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          Colors.black.withOpacity(0.6),
        ],
        stops: const [0.7, 1],
      ),
    ),
    child: Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: Icon(
          Icons.cloud_off_outlined,
          size: 18,
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isBackedUp = deviceCollection.shouldBackup;
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 140,
          width: 120,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: Hero(
                    tag: "device_folder:" +
                        deviceCollection.name +
                        deviceCollection.thumbnail.tag,
                    child: Stack(
                      children: [
                        ThumbnailWidget(
                          deviceCollection.thumbnail,
                          shouldShowSyncStatus: false,
                          key: Key(
                            "device_folder:" +
                                deviceCollection.name +
                                deviceCollection.thumbnail.tag,
                          ),
                        ),
                        isBackedUp ? Container() : kUnsyncedIconOverlay,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  deviceCollection.name,
                  textAlign: TextAlign.left,
                  style: Theme.of(context)
                      .textTheme
                      .subtitle1
                      .copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        routeToPage(context, DeviceFolderPage(deviceCollection));
      },
    );
  }
}
