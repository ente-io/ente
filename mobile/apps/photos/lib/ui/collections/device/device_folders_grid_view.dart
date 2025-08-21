import 'dart:async';
import "dart:math";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/device_files_db.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/backup_folders_updated_event.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/device_collection.dart';
import "package:photos/ui/collections/device/device_folder_item.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/viewer/gallery/empty_state.dart';
import "package:photos/utils/standalone/debouncer.dart";

class DeviceFoldersGridView extends StatefulWidget {
  const DeviceFoldersGridView({
    super.key,
  });

  @override
  State<DeviceFoldersGridView> createState() => _DeviceFoldersGridViewState();
}

class _DeviceFoldersGridViewState extends State<DeviceFoldersGridView> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  String _loadReason = "init";
  final _logger = Logger((_DeviceFoldersGridViewState).toString());
  final _debouncer = Debouncer(
    const Duration(seconds: 2),
    executionInterval: const Duration(seconds: 5),
    leading: true,
  );
  static const maxThumbnailWidth = 224.0;
  static const horizontalPadding = 16.0;
  static const crossAxisSpacing = 8.0;

  @override
  void initState() {
    super.initState();
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      if (mounted) {
        setState(() {});
      }
    });
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _debouncer.run(() async {
        if (mounted) {
          _loadReason = event.reason;
          setState(() {});
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.sizeOf(context).width;
    final int albumsCountInCrossAxis = max(screenWidth ~/ maxThumbnailWidth, 3);

    final double totalCrossAxisSpacing =
        (albumsCountInCrossAxis - 1) * crossAxisSpacing;
    final double sideOfThumbnail =
        (screenWidth - totalCrossAxisSpacing - horizontalPadding) /
            albumsCountInCrossAxis;

    debugPrint("${(DeviceFoldersGridView).toString()} - $_loadReason");
    return SizedBox(
      height: sideOfThumbnail + 46,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FutureBuilder<List<DeviceCollection>>(
          future: FilesDB.instance
              .getDeviceCollections(includeCoverThumbnail: true),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: EmptyState(),
                    )
                  : Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: horizontalPadding / 2,
                      ),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        physics: const ScrollPhysics(),
                        // to disable GridView's scrolling
                        itemBuilder: (context, index) {
                          final deviceCollection = snapshot.data![index];
                          return Padding(
                            padding: const EdgeInsets.only(
                              right: horizontalPadding / 2,
                            ),
                            child: DeviceFolderItem(
                              deviceCollection,
                              sideOfThumbnail: sideOfThumbnail,
                            ),
                          );
                        },
                        itemCount: snapshot.data!.length,
                      ),
                    );
            } else if (snapshot.hasError) {
              _logger.severe("failed to load device gallery", snapshot.error);
              return Text(AppLocalizations.of(context).failedToLoadAlbums);
            } else {
              return const EnteLoadingWidget();
            }
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    _localFilesSubscription?.cancel();
    _debouncer.cancelDebounceTimer();
    super.dispose();
  }
}
