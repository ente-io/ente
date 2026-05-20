import 'package:ente_pure_utils/ente_pure_utils.dart';
import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/device_collection.dart';
import "package:photos/service_locator.dart";
import "package:photos/ui/components/collection_share_badge.dart";
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';

class DeviceFolderRowItem extends StatelessWidget {
  final DeviceCollection deviceCollection;
  final double sideOfThumbnail;

  static const _cornerRadius = 20.0;
  static const _cornerSmoothing = 0.6;
  static const _overlayPadding = 8.0;

  const DeviceFolderRowItem(
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
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
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
                          if (!isBackedUp && !isLocalGalleryMode)
                            const Positioned(
                              right: _overlayPadding,
                              bottom: _overlayPadding,
                              child: CollectionUnSyncedBadge(),
                            ),
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
              style: Theme.of(
                context,
              ).colorScheme.enteTheme.textTheme.miniMuted,
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
