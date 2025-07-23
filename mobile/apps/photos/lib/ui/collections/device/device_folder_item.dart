import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/device_collection.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/viewer/file/file_icons_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';
import 'package:photos/utils/navigation_util.dart';

class DeviceFolderItem extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final double sideOfThumbnail;

  static const _cornerRadius = 12.0;
  static const _cornerSmoothing = 0.6;
  static const _borderWidth = 1.0;

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
          SizedBox(
            height: sideOfThumbnail,
            width: sideOfThumbnail,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius + _borderWidth,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: Container(
                    color: getEnteColorScheme(context).strokeFaint,
                    width: sideOfThumbnail,
                    height: sideOfThumbnail,
                  ),
                ),
                ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: SizedBox(
                    height: sideOfThumbnail - _borderWidth * 2,
                    width: sideOfThumbnail - _borderWidth * 2,
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
                          isBackedUp
                              ? const SizedBox.shrink()
                              : const UnSyncedIcon(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: sideOfThumbnail,
            child: Text(
              deviceCollection.name,
              textAlign: TextAlign.left,
              style: Theme.of(context).colorScheme.enteTheme.textTheme.small,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          SizedBox(
            width: sideOfThumbnail,
            child: Text(
              deviceCollection.count.toString(),
              textAlign: TextAlign.left,
              style:
                  Theme.of(context).colorScheme.enteTheme.textTheme.miniMuted,
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
