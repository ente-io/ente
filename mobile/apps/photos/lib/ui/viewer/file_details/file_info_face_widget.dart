import "dart:async";
import "dart:typed_data";

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/base/id.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/face_detection/detection.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/file_face_widget.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/dialog_util.dart";

final _logger = Logger("FileInfoFaceWidget");

class FileInfoFaceWidget extends StatefulWidget {
  final EnteFile file;
  final Face face;
  final Uint8List faceCrop;
  final PersonEntity? person;
  final String? clusterID;
  final double? width;
  final bool highlight;
  final bool isEditMode;
  final Future<void> Function() reloadAllFaces;

  const FileInfoFaceWidget(
    this.file,
    this.face, {
    required this.faceCrop,
    this.person,
    this.clusterID,
    this.highlight = false,
    this.isEditMode = false,
    this.width,
    required this.reloadAllFaces,
    super.key,
  });

  @override
  State<FileInfoFaceWidget> createState() => _FileInfoFaceWidgetState();
}

class _FileInfoFaceWidgetState extends State<FileInfoFaceWidget> {
  bool get hasPerson => widget.person != null;
  bool get isEditMode => widget.isEditMode;
  double get thumbnailWidth => widget.width ?? 68;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            GestureDetector(
              onTap: isEditMode
                  ? hasPerson
                      ? _onMinusIconTap
                      : _onPlusIconTap
                  : _routeToPersonOrClusterPage,
              child: Container(
                height: thumbnailWidth,
                width: thumbnailWidth,
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
                  child: SizedBox(
                    width: thumbnailWidth,
                    height: thumbnailWidth,
                    child: ClipPath(
                      clipper: ShapeBorderClipper(
                        shape: ContinuousRectangleBorder(
                          borderRadius: BorderRadius.circular(52),
                        ),
                      ),
                      child: FileFaceWidget(
                        key: ValueKey(widget.face.faceID),
                        widget.file,
                        faceCrop: widget.faceCrop,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (isEditMode) _buildEditIcon(context),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildFaceInfo(),
      ],
    );
  }

  List<Widget> _buildFaceInfo() {
    final List<Widget> faceInfo = [];
    if (widget.person != null) {
      faceInfo.add(
        SizedBox(
          width: thumbnailWidth,
          child: Center(
            child: Text(
              widget.person!.data.isIgnored
                  ? '(' + AppLocalizations.of(context).ignored + ')'
                  : widget.person!.data.name.trim(),
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      );
    }
    if (kDebugMode) {
      faceInfo.add(
        Text(
          'S:${widget.face.score.toStringAsFixed(2)}(I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'B:${widget.face.blur.toStringAsFixed(0)}(I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'D:${widget.face.detection.getFaceDirection().toDirectionString().substring(0, 3)}(I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
      faceInfo.add(
        Text(
          'Si:${widget.face.detection.faceIsSideways().toString()}(I)',
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
        ),
      );
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
      AppLocalizations.of(context).faceNotClusteredYet,
    );
    unawaited(MLService.instance.clusterAllImages(force: true));
    return;
  }

  Future<void> _onPlusIconTap() async {
    try {
      final newClusterIDValue =
          await ClusterFeedbackService.instance.removeFaceFromCluster(
        faceID: widget.face.faceID,
        clusterID: widget.clusterID,
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SaveOrEditPerson(
            newClusterIDValue,
            file: widget.file,
            isEditing: false,
          ),
        ),
      );
      await widget.reloadAllFaces();
    } catch (e, s) {
      _logger.severe('Error handling plus icon tap', e, s);
    }
  }

  Future<void> _onMinusIconTap() async {
    if (widget.person == null) return;
    final result = await showChoiceActionSheet(
      context,
      title: AppLocalizations.of(context).removePersonLabel,
      body: AppLocalizations.of(context).areYouSureRemoveThisFaceFromPerson,
      firstButtonLabel: AppLocalizations.of(context).remove,
      firstButtonType: ButtonType.critical,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
    );
    if (result?.action == ButtonAction.first) {
      try {
        await ClusterFeedbackService.instance.removeFaceFromPerson(
          widget.face.faceID,
          widget.person!,
        );
        await widget.reloadAllFaces();
      } catch (e, s) {
        _logger.severe('Error removing face from person', e, s);
      }
    }
  }

  Widget _buildEditIcon(BuildContext context) {
    return Positioned(
      right: -5,
      top: -5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => hasPerson ? _onMinusIconTap() : _onPlusIconTap(),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: hasPerson
                ? getEnteColorScheme(context).warning500
                : getEnteColorScheme(context).primary500,
            shape: BoxShape.circle,
            border: Border.all(
              color: getEnteColorScheme(context).backgroundBase,
              width: 2,
            ),
          ),
          child: Icon(
            hasPerson ? Icons.remove : Icons.add,
            size: 12,
            color: getEnteColorScheme(context).backgroundBase,
          ),
        ),
      ),
    );
  }
}
