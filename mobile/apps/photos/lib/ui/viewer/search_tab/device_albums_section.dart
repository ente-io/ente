import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/device_files_db.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/backup_folders_updated_event.dart";
import "package:photos/events/local_photos_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/device_collection.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/gallery/device_folder_page.dart";

class DeviceAlbumsSection extends StatefulWidget {
  const DeviceAlbumsSection({super.key});

  @override
  State<DeviceAlbumsSection> createState() => _DeviceAlbumsSectionState();
}

class _DeviceAlbumsSectionState extends State<DeviceAlbumsSection> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 5),
    leading: true,
  );

  @override
  void initState() {
    super.initState();
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      if (mounted) {
        setState(() {});
      }
    });
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _debouncer.run(() async {
        if (mounted) {
          setState(() {});
        }
      });
    });
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    _localFilesSubscription?.cancel();
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<DeviceCollection>>(
      future:
          FilesDB.instance.getDeviceCollections(includeCoverThumbnail: true),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final deviceCollections = snapshot.data!;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 2),
                SizedBox(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 4.5),
                    physics: const BouncingScrollPhysics(),
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: deviceCollections
                          .map(
                            (dc) => _DeviceAlbumRecommendation(dc),
                          )
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        AppLocalizations.of(context).onDevice,
        style: getEnteTextTheme(context).largeBold,
      ),
    );
  }
}

class _DeviceAlbumRecommendation extends StatelessWidget {
  static const _width = 100.0;
  final DeviceCollection deviceCollection;

  const _DeviceAlbumRecommendation(this.deviceCollection);

  @override
  Widget build(BuildContext context) {
    final enteTextTheme = getEnteTextTheme(context);
    final heroTag =
        "device_folder:${deviceCollection.name}${deviceCollection.thumbnail?.tag ?? ""}";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2.5),
      child: GestureDetector(
        onTap: () {
          routeToPage(context, DeviceFolderPage(deviceCollection));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: _width,
                height: 100,
                child: deviceCollection.thumbnail != null
                    ? Hero(
                        tag: heroTag,
                        child: ThumbnailWidget(
                          deviceCollection.thumbnail!,
                          shouldShowArchiveStatus: false,
                          shouldShowSyncStatus: false,
                        ),
                      )
                    : Container(
                        color: getEnteColorScheme(context).fillFaint,
                        child: Icon(
                          Icons.folder_outlined,
                          color: getEnteColorScheme(context).strokeMuted,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _width),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    deviceCollection.name,
                    style: enteTextTheme.small,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    deviceCollection.count.toString(),
                    style: enteTextTheme.miniMuted,
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
