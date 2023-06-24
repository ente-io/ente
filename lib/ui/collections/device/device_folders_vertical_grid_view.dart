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

class DeviceFolderVerticalGridView extends StatefulWidget {
  final Widget? appTitle;

  const DeviceFolderVerticalGridView({
    Key? key,
    this.appTitle,
  }) : super(key: key);

  @override
  State<DeviceFolderVerticalGridView> createState() =>
      _DeviceFolderVerticalGridViewState();
}

class _DeviceFolderVerticalGridViewState
    extends State<DeviceFolderVerticalGridView> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  String _loadReason = "init";

  @override
  void initState() {
    _backupFoldersUpdatedEvent =
        Bus.instance.on<BackupFoldersUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      if (mounted) {
        setState(() {});
      }
    });
    _localFilesSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _loadReason = event.reason;
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: widget.appTitle,
      ),
      body: SafeArea(
        child: _getBody(context),
      ),
    );
  }

  Widget _getBody(BuildContext context) {
    const horizontalPadding = 20.0;
    const deviceAlbumThumbnailWidth = 120.0;
    debugPrint("${(DeviceFolderVerticalGridView).toString()} - $_loadReason");
    final logger = Logger((_DeviceFolderVerticalGridViewState).toString());
    return SafeArea(
      child: FutureBuilder<List<DeviceCollection>>(
        future:
            FilesDB.instance.getDeviceCollections(includeCoverThumbnail: true),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final double screenWidth = MediaQuery.of(context).size.width;

            final int albumsCountInOneRow = max(
                screenWidth ~/ (deviceAlbumThumbnailWidth + horizontalPadding),
                2);
            return snapshot.data!.isEmpty
                ? const EmptyState()
                : Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                    ),
                    child: GridView.builder(
                      physics: const ScrollPhysics(),
                      itemBuilder: (context, index) {
                        final deviceCollection = snapshot.data![index];
                        return DeviceFolderItem(deviceCollection);
                      },
                      itemCount: snapshot.data!.length,
                      // To include the + button
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: albumsCountInOneRow,
                        crossAxisSpacing: 16.0,
                        childAspectRatio: deviceAlbumThumbnailWidth /
                            (deviceAlbumThumbnailWidth + 10),
                      ),
                    ),
                  );
          } else if (snapshot.hasError) {
            logger.severe("failed to load device gallery", snapshot.error);
            return Text(S.of(context).failedToLoadAlbums);
          } else {
            return const EnteLoadingWidget();
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    _localFilesSubscription?.cancel();
    super.dispose();
  }
}
