import "dart:async";
import "dart:typed_data";

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/base/id.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/face_widget.dart";
import "package:photos/ui/viewer/people/people_page.dart";

class FileInfoFaceWidget extends StatefulWidget {
  final EnteFile file;
  final Face face;
  final Uint8List faceCrop;
  final PersonEntity? person;
  final String? clusterID;
  final bool highlight;

  const FileInfoFaceWidget(
    this.file,
    this.face, {
    required this.faceCrop,
    this.person,
    this.clusterID,
    this.highlight = false,
    super.key,
  });

  @override
  State<FileInfoFaceWidget> createState() => _FileInfoFaceWidgetState();
}

class _FileInfoFaceWidgetState extends State<FileInfoFaceWidget> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _routeToPersonOrClusterPage,
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: ShapeDecoration(
                  shape: RoundedRectangleBorder(
                    borderRadius: const BorderRadius.all(
                      Radius.elliptical(16, 12),
                    ),
                    side: widget.highlight
                        ? BorderSide(
                            color: getEnteColorScheme(context).primary700,
                            width: 1.0,
                          )
                        : BorderSide.none,
                  ),
                ),
                child: ClipRRect(
                  borderRadius:
                      const BorderRadius.all(Radius.elliptical(16, 12)),
                  child: SizedBox(
                    width: 60,
                    height: 60,
                    child: FaceWidget(
                      widget.file,
                      faceCrop: widget.faceCrop,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._buildFaceInfo(),
        ],
      ),
    );
  }

  List<Widget> _buildFaceInfo() {
    final List<Widget> faceInfo = [];
    if (widget.person != null) {
      faceInfo.add(
        Text(
          widget.person!.data.isIgnored
              ? '(' + S.of(context).ignored + ')'
              : widget.person!.data.name.trim(),
          style: Theme.of(context).textTheme.bodySmall,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      );
    }
    if (kDebugMode) {
      faceInfo.add(
        Text(
          'S: ${widget.face.score.toStringAsFixed(3)} (I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'B: ${widget.face.blur.toStringAsFixed(0)} (I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'D: ${widget.face.detection.getFaceDirection().toDirectionString()} (I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'Sideways: ${widget.face.detection.faceIsSideways().toString()} (I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      if (widget.face.score < kMinimumFaceShowScore) {
        faceInfo.add(
          Text(
            'Not visible to user (I)',
            style: Theme.of(context).textTheme.bodySmall,
            maxLines: 1,
          ),
        );
      }
    }
    return faceInfo;
  }

  Future<void> _routeToPersonOrClusterPage() async {
    final mlDataDB = MLDataDB.instance;
    if (widget.person != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PeoplePage(
            person: widget.person!,
            searchResult: null,
          ),
        ),
      );
      return;
    }
    final String? clusterID = widget.clusterID ??
        await mlDataDB.getClusterIDForFaceID(widget.face.faceID);
    if (clusterID != null) {
      final fileIdsToClusterIds = await mlDataDB.getFileIdToClusterIds();
      final files = await SearchService.instance.getAllFilesForSearch();
      final clusterFiles = files
          .where(
            (file) =>
                fileIdsToClusterIds[file.uploadedFileID]?.contains(clusterID) ??
                false,
          )
          .toList();
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClusterPage(
            clusterFiles,
            clusterID: clusterID,
          ),
        ),
      );
      return;
    }
    if (widget.face.score <= kMinimumQualityFaceScore) {
      // The face score is too low for automatic clustering,
      // assigning a manual new clusterID so that the user can cluster it manually
      final String clusterID = newClusterID();
      await mlDataDB.updateFaceIdToClusterId(
        {widget.face.faceID: clusterID},
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ClusterPage(
            [widget.file],
            clusterID: clusterID,
          ),
        ),
      );
      return;
    }

    showShortToast(
      context,
      S.of(context).faceNotClusteredYet,
    );
    unawaited(MLService.instance.clusterAllImages(force: true));
    return;
  }
}
