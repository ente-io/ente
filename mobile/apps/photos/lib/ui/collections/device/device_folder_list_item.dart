import 'package:ente_pure_utils/ente_pure_utils.dart';
import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/device_collection.dart';
import "package:photos/service_locator.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/collection_share_badge.dart";
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/gallery/device_folder_page.dart';

class DeviceFolderListItem extends StatelessWidget {
  static const _thumbSize = 52.0;
  static const _cornerRadius = 12.0;
  static const _rowHeight = 68.0;
  static const _cardRadius = 20.0;
  static const _padding = 8.0;

  final DeviceCollection deviceCollection;

  const DeviceFolderListItem(
    this.deviceCollection, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final isBackedUp = deviceCollection.shouldBackup;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        routeToPage(context, DeviceFolderPage(deviceCollection));
      },
      child: Container(
        height: _rowHeight,
        padding: const EdgeInsets.all(_padding),
        decoration: BoxDecoration(
          color: colorScheme.fill,
          borderRadius: const BorderRadius.all(Radius.circular(_cardRadius)),
        ),
        child: Row(
          children: [
            SizedBox(
              height: _thumbSize,
              width: _thumbSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_cornerRadius),
                    child: SizedBox(
                      height: _thumbSize,
                      width: _thumbSize,
                      child: ThumbnailWidget(
                        deviceCollection.thumbnail!,
                        shouldShowSyncStatus: false,
                        key: Key(
                          "device_folder:" +
                              deviceCollection.name +
                              deviceCollection.thumbnail!.tag,
                        ),
                      ),
                    ),
                  ),
                  if (!isBackedUp && !isLocalGalleryMode)
                    const Positioned(
                      right: -4,
                      bottom: -4,
                      child: CollectionUnSyncedBadge(showBorder: true),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    deviceCollection.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalizations.of(context).itemCount(
                      count: deviceCollection.count,
                    ),
                    style: textTheme.smallMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
