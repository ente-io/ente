import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/service_locator.dart";
import "package:photos/theme/colors.dart";

class VideoStreamChangeWidget extends StatefulWidget {
  const VideoStreamChangeWidget({
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
  State<VideoStreamChangeWidget> createState() =>
      _VideoStreamChangeWidgetState();
}

class _VideoStreamChangeWidgetState extends State<VideoStreamChangeWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isPreviewAvailable = widget.file.uploadedFileID != null &&
        (fileDataService.previewIds.containsKey(widget.file.uploadedFileID));
    if (!isPreviewAvailable) {
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
            onTap: widget.onStreamChange,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: const BorderRadius.all(
                  Radius.circular(200),
                ),
                border: Border.all(
                  color: strokeFaintDark,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.play_arrow, size: 16),
                  const SizedBox(width: 2),
                  Text(
                    widget.isPreviewPlayer
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
