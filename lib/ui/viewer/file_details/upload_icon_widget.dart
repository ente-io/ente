import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/collection_updated_event.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/models/file.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/hidden_service.dart";
import "package:photos/services/ignored_files_service.dart";
import "package:photos/services/remote_sync_service.dart";
import "package:photos/services/sync_service.dart";

class UploadIconWidget extends StatefulWidget {
  final File file;

  const UploadIconWidget({super.key, required this.file});

  @override
  State<StatefulWidget> createState() {
    return _UpdateIconWidgetState();
  }
}

class _UpdateIconWidgetState extends State<UploadIconWidget> {
  late StreamSubscription<CollectionUpdatedEvent> _firstImportEvent;
  bool isUploadedNow = false;

  @override
  void initState() {
    super.initState();
    _firstImportEvent =
        Bus.instance.on<CollectionUpdatedEvent>().listen((event) {
      if (mounted &&
          event.type == EventType.addedOrUpdated &&
          event.updatedFiles.isNotEmpty &&
          event.updatedFiles.first.localID == widget.file.localID &&
          event.updatedFiles.first.isUploaded) {
        setState(() {
          isUploadedNow = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _firstImportEvent.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (SyncService.instance.isSyncInProgress()) {
      return const SizedBox.shrink();
    }
    if (widget.file.isUploaded || isUploadedNow) {
      if (isUploadedNow) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: const Icon(
            Icons.cloud_done_outlined,
            color: Colors.white,
          )
              .animate()
              .fadeIn(
                duration: 500.ms,
                curve: Curves.easeInOutCubic,
              )
              .fadeOut(
                delay: const Duration(seconds: 5),
                duration: 500.ms,
                curve: Curves.easeInOutCubic,
              ),
        );
      }
      return const SizedBox.shrink();
    }
    return FutureBuilder<bool>(
      future: IgnoredFilesService.instance.shouldSkipUploadAsync(widget.file),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final bool isIgnored = snapshot.data!;
          final bool isQueuedForUpload =
              !isIgnored && widget.file.collectionID != null;
          if (isQueuedForUpload) {
            return const SizedBox.shrink();
          }
          return IconButton(
            icon: const Icon(
              Icons.upload_rounded,
              color: Colors.white,
            ),
            onPressed: () async {
              if (isIgnored) {
                await IgnoredFilesService.instance
                    .removeIgnoredMappings([widget.file]);
              }
              if (widget.file.collectionID == null) {
                widget.file.collectionID = (await CollectionsService.instance
                        .getUncategorizedCollection())
                    .id;
                FilesDB.instance.insert(widget.file);
              }
              RemoteSyncService.instance.sync().ignore();
              if (mounted) {
                setState(() {});
              }
            },
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }
}
