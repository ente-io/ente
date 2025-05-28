import "dart:typed_data";

import 'package:flutter/widgets.dart';
import "package:logging/logging.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/face/face_box_crop.dart";

final _logger = Logger("FaceWidget");

class FaceWidget extends StatefulWidget {
  final EnteFile file;
  final Face? face;
  final Uint8List? faceCrop;
  final String? clusterID;
  final bool useFullFile;
  final bool thumbnailFallback;

  const FaceWidget(
    this.file, {
    this.face,
    this.faceCrop,
    this.clusterID,
    this.useFullFile = true,
    this.thumbnailFallback = false,
    super.key,
  });

  @override
  State<FaceWidget> createState() => _FaceWidgetState();
}

class _FaceWidgetState extends State<FaceWidget> {
  Future<Uint8List?>? faceCropFuture;

  @override
  void initState() {
    super.initState();
    faceCropFuture = _getFaceCrop();
  }

  @override
  void dispose() {
    super.dispose();
    if (widget.faceCrop == null) {
      checkStopTryingToGenerateFaceThumbnails(
        widget.file,
        useFullFile: widget.useFullFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: faceCropFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          final ImageProvider imageProvider = MemoryImage(snapshot.data!);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ],
          );
        } else {
          if (snapshot.hasError) {
            _logger.severe(
              "Error getting cover face",
              snapshot.error,
              snapshot.stackTrace,
            );
          }
          return widget.thumbnailFallback
              ? ThumbnailWidget(widget.file)
              : EnteLoadingWidget(
                  color: getEnteColorScheme(context).fillMuted,
                );
        }
      },
    );
  }

  Future<Uint8List?> _getFaceCrop() async {
    if (widget.faceCrop != null) {
      return widget.faceCrop;
    }
  }
}
