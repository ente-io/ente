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

class DeviceFolderVerticalGridView extends StatelessWidget {
  final Widget? appTitle;
  final String? tag;
  const DeviceFolderVerticalGridView({this.appTitle, this.tag, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverAppBar(
            elevation: 0,
            title: tag != null
                ? Hero(
                    tag: tag!,
                    child: appTitle ?? const SizedBox.shrink(),
                  )
                : appTitle ?? const SizedBox.shrink(),
            floating: true,
          ),
          const _DeviceFolderVerticalGridViewBody(),
        ],
      ),
    );
  }
}

class _DeviceFolderVerticalGridViewBody extends StatefulWidget {
  const _DeviceFolderVerticalGridViewBody();

  @override
  State<_DeviceFolderVerticalGridViewBody> createState() =>
      _DeviceFolderVerticalGridViewBodyState();
}

class _DeviceFolderVerticalGridViewBodyState
    extends State<_DeviceFolderVerticalGridViewBody> {
  StreamSubscription<BackupFoldersUpdatedEvent>? _backupFoldersUpdatedEvent;
  StreamSubscription<LocalPhotosUpdatedEvent>? _localFilesSubscription;
  String _loadReason = "init";
  final logger = Logger((_DeviceFolderVerticalGridViewBodyState).toString());
  final _debouncer = Debouncer(
    const Duration(milliseconds: 1500),
    executionInterval: const Duration(seconds: 4),
  );
  /*
  Aspect ratio 1:1
  Width changes dynamically with screen width
  */
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
    debugPrint(
      "${(_DeviceFolderVerticalGridViewBody).toString()} - $_loadReason",
    );
    return FutureBuilder<List<DeviceCollection>>(
      future:
          FilesDB.instance.getDeviceCollections(includeCoverThumbnail: true),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final double screenWidth = MediaQuery.sizeOf(context).width;
          final int albumsCountInCrossAxis =
              max(screenWidth ~/ maxThumbnailWidth, 3);

          final double totalCrossAxisSpacing =
              (albumsCountInCrossAxis - 1) * crossAxisSpacing;
          final double sideOfThumbnail =
              (screenWidth - totalCrossAxisSpacing - horizontalPadding) /
                  albumsCountInCrossAxis;

          return snapshot.data!.isEmpty
              ? const SliverFillRemaining(child: EmptyState())
              : SliverPadding(
                  padding: const EdgeInsets.only(
                    left: horizontalPadding / 2,
                    right: horizontalPadding / 2,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: albumsCountInCrossAxis,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: crossAxisSpacing,
                      childAspectRatio:
                          sideOfThumbnail / (sideOfThumbnail + 46),
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final deviceCollection = snapshot.data![index];
                        return DeviceFolderItem(
                          deviceCollection,
                          sideOfThumbnail: sideOfThumbnail,
                        );
                      },
                      childCount: snapshot.data!.length,
                    ),
                  ),
                );
        } else if (snapshot.hasError) {
          logger.severe("failed to load device gallery", snapshot.error);
          return SliverFillRemaining(
            child: Center(
              child: Text(AppLocalizations.of(context).failedToLoadAlbums),
            ),
          );
        } else {
          return const SliverFillRemaining(child: EnteLoadingWidget());
        }
      },
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
