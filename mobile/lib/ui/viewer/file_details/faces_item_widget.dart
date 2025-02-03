import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/info_item_widget.dart";
import "package:photos/ui/viewer/file_details/face_widget.dart";
import "package:photos/utils/face/face_box_crop.dart";

class FacesItemWidget extends StatefulWidget {
  final EnteFile file;
  const FacesItemWidget(this.file, {super.key});

  @override
  State<FacesItemWidget> createState() => _FacesItemWidgetState();
}

class _FacesItemWidgetState extends State<FacesItemWidget> {
  bool editMode = false;

  @override
  void initState() {
    super.initState();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return InfoItemWidget(
      key: const ValueKey("Faces"),
      leadingIcon: Icons.face_retouching_natural_outlined,
      subtitleSection: _faceWidgets(context, widget.file, editMode),
      hasChipButtons: true,
      biggerSpinner: true,
    );
  }

  Future<List<Widget>> _faceWidgets(
    BuildContext context,
    EnteFile file,
    bool editMode,
  ) async {
    late final mlDataDB = MLDataDB.instance;
    try {
      if (file.uploadedFileID == null) {
        return [
          ChipButtonWidget(
            S.of(context).fileNotUploadedYet,
            noChips: true,
          ),
        ];
      }

      final List<Face>? faces =
          await mlDataDB.getFacesForGivenFileID(file.uploadedFileID!);
      if (faces == null) {
        return [
          ChipButtonWidget(
            S.of(context).imageNotAnalyzed,
            noChips: true,
          ),
        ];
      }

      // Remove faces with low scores
      if (!kDebugMode) {
        faces.removeWhere((face) => (face.score < 0.75));
      } else {
        faces.removeWhere((face) => (face.score < 0.5));
      }

      if (faces.isEmpty) {
        return [
          ChipButtonWidget(
            S.of(context).noFacesFound,
            noChips: true,
          ),
        ];
      }

      final faceIdsToClusterIds = await mlDataDB
          .getFaceIdsToClusterIds(faces.map((face) => face.faceID));
      final Map<String, PersonEntity> persons =
          await PersonService.instance.getPersonsMap();
      final clusterIDToPerson = await mlDataDB.getClusterIDToPersonID();

      // Sort faces by name and score
      final faceIdToPersonID = <String, String>{};
      for (final face in faces) {
        final clusterID = faceIdsToClusterIds[face.faceID];
        if (clusterID != null) {
          final personID = clusterIDToPerson[clusterID];
          if (personID != null) {
            faceIdToPersonID[face.faceID] = personID;
          }
        }
      }
      faces.sort((Face a, Face b) {
        final aPersonID = faceIdToPersonID[a.faceID];
        final bPersonID = faceIdToPersonID[b.faceID];
        if (aPersonID != null && bPersonID == null) {
          return -1;
        } else if (aPersonID == null && bPersonID != null) {
          return 1;
        } else {
          return b.score.compareTo(a.score);
        }
      });
      // Make sure hidden faces are last
      faces.sort((Face a, Face b) {
        final aIsHidden =
            persons[faceIdToPersonID[a.faceID]]?.data.isIgnored ?? false;
        final bIsHidden =
            persons[faceIdToPersonID[b.faceID]]?.data.isIgnored ?? false;
        if (aIsHidden && !bIsHidden) {
          return 1;
        } else if (!aIsHidden && bIsHidden) {
          return -1;
        } else {
          return 0;
        }
      });

      final lastViewedClusterID = ClusterFeedbackService.lastViewedClusterID;

      final faceWidgets = <FaceWidget>[];

      // await generation of the face crops here, so that the file info shows one central loading spinner
      final _ = await getCachedFaceCrops(file, faces);

      final faceCrops = getCachedFaceCrops(file, faces);
      for (final Face face in faces) {
        final String? clusterID = faceIdsToClusterIds[face.faceID];
        final PersonEntity? person = clusterIDToPerson[clusterID] != null
            ? persons[clusterIDToPerson[clusterID]!]
            : null;
        final highlight =
            (clusterID == lastViewedClusterID) && (person == null);
        faceWidgets.add(
          FaceWidget(
            file,
            face,
            faceCrops: faceCrops,
            clusterID: clusterID,
            person: person,
            highlight: highlight,
            editMode: highlight ? editMode : false,
          ),
        );
      }

      return faceWidgets;
    } catch (e, s) {
      Logger("FacesItemWidget").info(e, s);
      return <FaceWidget>[];
    }
  }
}
