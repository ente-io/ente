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

class DeviceFolderVerticalGridView extends StatelessWidget {
  final Widget? appTitle;

  const DeviceFolderVerticalGridView({this.appTitle, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: appTitle,
      ),
      body: const SafeArea(
        child: _DeviceFolderVerticalGridViewBody(),
      ),
    );
  }
}

class _DeviceFolderVerticalGridViewBody extends StatefulWidget {
  const _DeviceFolderVerticalGridViewBody({
    Key? key,
  }) : super(key: key);

  @override
  State<_DeviceFolderVerticalGridViewBody> createState() =>
      _DeviceFolderVerticalGridViewBodyState();
}

class _DeviceFolderVerticalGridViewBodyState
    extends State<_DeviceFolderVerticalGridViewBody> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  String _loadReason = "init";
  static const horizontalPadding = 20.0;
  static const thumbnailSize = 120.0;
  final logger = Logger((_DeviceFolderVerticalGridViewBodyState).toString());

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
    debugPrint(
      "${(_DeviceFolderVerticalGridViewBody).toString()} - $_loadReason",
    );
    return FutureBuilder<List<DeviceCollection>>(
      future:
          FilesDB.instance.getDeviceCollections(includeCoverThumbnail: true),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final double screenWidth = MediaQuery.of(context).size.width;

          final int crossAxisItemCount =
              max(screenWidth ~/ (thumbnailSize + horizontalPadding), 2);
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
                      crossAxisCount: crossAxisItemCount,
                      crossAxisSpacing: 16.0,
                      childAspectRatio: thumbnailSize / (thumbnailSize + 22),
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
    );
  }

  @override
  void dispose() {
    _backupFoldersUpdatedEvent?.cancel();
    _localFilesSubscription?.cancel();
    super.dispose();
  }
}
