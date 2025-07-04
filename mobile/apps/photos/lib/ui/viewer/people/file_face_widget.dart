import "dart:typed_data";

import 'package:flutter/widgets.dart';
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final _logger = Logger("FaceWidget");

class FileFaceWidget extends StatefulWidget {
  final EnteFile file;

  // Data to find the right face, in order of preference
  final Uint8List? faceCrop;
  final Face? face;
  final String? clusterID;

  final bool useFullFile;
  final bool thumbnailFallback;

  const FileFaceWidget(
    this.file, {
    this.face,
    this.faceCrop,
    this.clusterID,
    this.useFullFile = true,
    this.thumbnailFallback = false,
    super.key,
  });

  @override
  State<FileFaceWidget> createState() => _FileFaceWidgetState();
}

class _FileFaceWidgetState extends State<FileFaceWidget> {
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
        widget.file.uploadedFileID!,
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
    try {
      final Face? faceToUse = widget.face ??
          await MLDataDB.instance.getCoverFaceForPerson(
            recentFileID: widget.file.uploadedFileID!,
            clusterID: widget.clusterID,
          );
      if (faceToUse == null) {
        _logger.severe(
          "Cannot find face to crop, widget.face: ${widget.face}, clusterID: ${widget.clusterID}",
        );
      }
      final cropMap = await getCachedFaceCrops(
        widget.file,
        [faceToUse!],
        useFullFile: widget.useFullFile,
        useTempCache: true,
      );
      if (cropMap != null && cropMap[faceToUse.faceID] != null) {
        return cropMap[faceToUse.faceID];
      } else {
        _logger.severe(
          "No face crop found for face ${faceToUse.faceID} in file ${widget.file.uploadedFileID}",
        );
        return null;
      }
    } catch (e, s) {
      _logger.severe(
        "Failed to get face crop for file ${widget.file.uploadedFileID}",
        e,
        s,
      );
      return null;
    }
  }
}
