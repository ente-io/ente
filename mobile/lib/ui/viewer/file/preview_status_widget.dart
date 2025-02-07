import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/preview_updated_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/preview/preview_item.dart";
import "package:photos/models/preview/preview_item_status.dart";
import "package:photos/services/filedata/filedata_service.dart";
import "package:photos/services/preview_video_store.dart";
import "package:photos/theme/colors.dart";
import "package:photos/ui/settings/backup/backup_status_screen.dart";

class PreviewStatusWidget extends StatefulWidget {
  const PreviewStatusWidget({
    super.key,
    required bool showControls,
    required this.file,
    required this.onStreamChange,
    this.isPreviewPlayer = false,
  }) : _showControls = showControls;

  final bool _showControls;
  final EnteFile file;
  final bool isPreviewPlayer;
  final void Function()? onStreamChange;

  @override
  State<PreviewStatusWidget> createState() => _PreviewStatusWidgetState();
}

class _PreviewStatusWidgetState extends State<PreviewStatusWidget> {
  StreamSubscription? previewSubscription;
  late PreviewItem? preview =
      PreviewVideoStore.instance.previews[widget.file.uploadedFileID];
  late bool isVideoStreamingEnabled;

  @override
  void initState() {
    super.initState();

    isVideoStreamingEnabled =
        PreviewVideoStore.instance.isVideoStreamingEnabled;
    if (!isVideoStreamingEnabled) {
      return;
    }
    previewSubscription =
        Bus.instance.on<PreviewUpdatedEvent>().listen((event) {
      final newPreview = event.items[widget.file.uploadedFileID];
      if (newPreview != preview) {
        setState(() {
          preview = event.items[widget.file.uploadedFileID];
        });
      }
    });
  }

  @override
  void dispose() {
    previewSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isVideoStreamingEnabled) {
      return const SizedBox();
    }
    final bool isPreviewAvailable = widget.file.uploadedFileID != null &&
        (FileDataService.instance.previewIds
                ?.containsKey(widget.file.uploadedFileID) ??
            false);

    if (preview == null && !isPreviewAvailable) {
      return const SizedBox();
    }
    final isInProgress = preview?.status == PreviewItemStatus.compressing ||
        preview?.status == PreviewItemStatus.uploading;
    final isInQueue = preview?.status == PreviewItemStatus.inQueue ||
        preview?.status == PreviewItemStatus.retry;
    final isFailed = preview?.status == PreviewItemStatus.failed;

    final isBeforeCutoffDate = widget.file.creationTime != null &&
            PreviewVideoStore.instance.videoStreamingCutoff != null
        ? DateTime.fromMillisecondsSinceEpoch(widget.file.creationTime!)
            .isBefore(
            PreviewVideoStore.instance.videoStreamingCutoff!,
          )
        : false;

    if (preview == null && isBeforeCutoffDate && !isPreviewAvailable) {
      return const SizedBox();
    }

    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: const Duration(
          milliseconds: 200,
        ),
        curve: Curves.easeInQuad,
        opacity: widget._showControls ? 1 : 0,
        child: Padding(
          padding: const EdgeInsets.only(
            right: 10,
            bottom: 4,
          ),
          child: GestureDetector(
            onTap:
                preview == null || preview!.status == PreviewItemStatus.uploaded
                    ? widget.onStreamChange
                    : () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BackupStatusScreen(),
                          ),
                        );
                      },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: isPreviewAvailable ? Colors.green : null,
                borderRadius: const BorderRadius.all(
                  Radius.circular(200),
                ),
                border: isPreviewAvailable
                    ? null
                    : Border.all(
                        color: strokeFaintDark,
                        width: 1,
                      ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  !isInProgress
                      ? Icon(
                          isInQueue
                              ? Icons.history_outlined
                              : isBeforeCutoffDate
                                  ? Icons.block_outlined
                                  : isFailed
                                      ? Icons.error_outline
                                      : Icons.play_arrow,
                          size: 16,
                        )
                      : const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                              Colors.white,
                            ),
                            backgroundColor: Colors.transparent,
                            strokeWidth: 2,
                          ),
                        ),
                  SizedBox(
                    width: !isInProgress || isPreviewAvailable ? 2 : 6,
                  ),
                  Text(
                    isInProgress
                        ? S.of(context).processing
                        : isInQueue
                            ? S.of(context).queued
                            : isBeforeCutoffDate
                                ? S.of(context).ineligible
                                : isFailed
                                    ? S.of(context).failed
                                    : widget.isPreviewPlayer
                                        ? S.of(context).playOriginal
                                        : S.of(context).playStream,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
