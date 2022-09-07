// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';
import 'package:photos/utils/navigation_util.dart';

class DeviceFolderIcon extends StatelessWidget {
  const DeviceFolderIcon(
    this.folder, {
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

  final DeviceFolder folder;

  @override
  Widget build(BuildContext context) {
    final isBackedUp =
        Configuration.instance.getPathsToBackUp().contains(folder.path);
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: SizedBox(
          height: 140,
          width: 120,
          child: Column(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  height: 120,
                  width: 120,
                  child: Hero(
                    tag:
                        "device_folder:" + folder.path + folder.thumbnail.tag(),
                    child: Stack(
                      children: [
                        ThumbnailWidget(
                          folder.thumbnail,
                          shouldShowSyncStatus: false,
                          key: Key(
                            "device_folder:" +
                                folder.path +
                                folder.thumbnail.tag(),
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
                  folder.name,
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
        routeToPage(context, DeviceFolderPage(folder));
      },
    );
  }
}
