import "dart:async";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/file_details/file_info_face_widget.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final Logger _logger = Logger("FacesItemWidget");

class FacesItemWidget extends StatefulWidget {
  final EnteFile file;
  const FacesItemWidget(this.file, {super.key});

  @override
  State<FacesItemWidget> createState() => _FacesItemWidgetState();
}

class _FacesItemWidgetState extends State<FacesItemWidget> {
  bool _isEditMode = false;
  bool _showRemainingFaces = false;
  bool _isLoading = true;
  List<_FaceInfo> _defaultFaces = [];
  List<_FaceInfo> _remainingFaces = [];

  @override
  void initState() {
    super.initState();
    loadFaces();
  }

  Future<void> loadFaces() async {
    setState(() => _isLoading = true);

    try {
      final faceData = await _fetchFaceData();
      setState(() {
        _defaultFaces = faceData['default'] ?? [];
        _remainingFaces = faceData['remaining'] ?? [];
        _isLoading = false;
      });
    } catch (e, s) {
      _logger.severe('Failed to load faces', e, s);
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, List<_FaceInfo>>> _fetchFaceData() async {
    if (widget.file.uploadedFileID == null) {
      return {'default': [], 'remaining': []};
    }

    final mlDataDB = MLDataDB.instance;
    final faces =
        await mlDataDB.getFacesForGivenFileID(widget.file.uploadedFileID!);

    if (faces == null || faces.isEmpty) {
      return {'default': [], 'remaining': []};
    }

    // Separate faces by score threshold
    final defaultFaces = <Face>[];
    final remainingFaces = <Face>[];

    for (final face in faces) {
      if (face.score >= kMinimumFaceShowScore) {
        defaultFaces.add(face);
      } else {
        remainingFaces.add(face);
      }
    }

    // Get additional data
    final faceIdsToClusterIds = await mlDataDB.getFaceIdsToClusterIds(
      faces.map((face) => face.faceID).toList(),
    );
    final persons = await PersonService.instance.getPersonsMap();
    final clusterIDToPerson = await mlDataDB.getClusterIDToPersonID();
    final faceCrops = await getCachedFaceCrops(widget.file, faces);

    if (faceCrops == null) {
      return {'default': [], 'remaining': []};
    }

    return {
      'default': await _buildFaceInfoList(
        defaultFaces,
        faceIdsToClusterIds,
        persons,
        clusterIDToPerson,
        faceCrops,
      ),
      'remaining': await _buildFaceInfoList(
        remainingFaces,
        faceIdsToClusterIds,
        persons,
        clusterIDToPerson,
        faceCrops,
      ),
    };
  }

  Future<List<_FaceInfo>> _buildFaceInfoList(
    List<Face> faces,
    Map<String, String?> faceIdsToClusterIds,
    Map<String, PersonEntity> persons,
    Map<String, String> clusterIDToPerson,
    Map<String, Uint8List> faceCrops,
  ) async {
    final faceInfoList = <_FaceInfo>[];

    // Build person mapping for sorting
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

    // Sort faces: named first, then by score, hidden last
    faces.sort((a, b) {
      final aPersonID = faceIdToPersonID[a.faceID];
      final bPersonID = faceIdToPersonID[b.faceID];
      final aIsHidden = persons[aPersonID]?.data.isIgnored ?? false;
      final bIsHidden = persons[bPersonID]?.data.isIgnored ?? false;

      if (aIsHidden != bIsHidden) return aIsHidden ? 1 : -1;
      if ((aPersonID != null) != (bPersonID != null)) {
        return aPersonID != null ? -1 : 1;
      }
      return b.score.compareTo(a.score);
    });

    // Create face info objects
    for (final face in faces) {
      final faceCrop = faceCrops[face.faceID];
      if (faceCrop == null) {
        _logger.severe('Missing face crop for ${face.faceID}');
        continue;
      }

      final clusterID = faceIdsToClusterIds[face.faceID];
      final person = clusterIDToPerson[clusterID] != null
          ? persons[clusterIDToPerson[clusterID]!]
          : null;

      faceInfoList.add(
        _FaceInfo(
          face: face,
          faceCrop: faceCrop,
          clusterID: clusterID,
          person: person,
        ),
      );
    }

    return faceInfoList;
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) _showRemainingFaces = false;
    });
  }

  void _toggleRemainingFaces() {
    setState(() => _showRemainingFaces = !_showRemainingFaces);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const IconButtonWidget(
                icon: Icons.face_retouching_natural_outlined,
                iconButtonType: IconButtonType.secondary,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 3.5, 16, 3.5),
                  child: SizedBox(
                    width: double.infinity,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          S.of(context).faces,
                          style: getEnteTextTheme(context).miniMuted,
                        ),
                        const SizedBox(height: 8),
                        _buildContent(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButtonWidget(
          icon: _isEditMode ? Icons.check : Icons.edit,
          iconButtonType: IconButtonType.secondary,
          onTap: _toggleEditMode,
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const EnteLoadingWidget(
        padding: 6,
        size: 20,
        alignment: Alignment.centerLeft,
      );
    }

    if (_defaultFaces.isEmpty && _remainingFaces.isEmpty) {
      return _buildNoFacesWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_defaultFaces.isNotEmpty) _buildFaceGrid(_defaultFaces),
        if (_remainingFaces.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildRemainingFacesSection(),
        ],
      ],
    );
  }

  Widget _buildNoFacesWidget() {
    NoFacesReason reason;
    if (widget.file.uploadedFileID == null) {
      reason = NoFacesReason.fileNotUploaded;
    } else {
      reason = NoFacesReason.noFacesFound;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: ChipButtonWidget(
        getNoFaceReasonText(context, reason),
        noChips: true,
      ),
    );
  }

  Widget _buildFaceGrid(List<_FaceInfo> faceInfoList) {
    return Wrap(
      runSpacing: 8,
      spacing: 8,
      children: faceInfoList
          .map(
            (faceInfo) => FileInfoFaceWidget(
              widget.file,
              faceInfo.face,
              faceCrop: faceInfo.faceCrop,
              person: faceInfo.person,
              clusterID: faceInfo.clusterID,
              isEditMode: _isEditMode,
              reloadAllFaces: loadFaces,
            ),
          )
          .toList(),
    );
  }

  Widget _buildRemainingFacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _toggleRemainingFaces,
          child: Row(
            children: [
              Text(
                "Other detected faces",
                style: getEnteTextTheme(context).miniMuted,
              ),
              const SizedBox(width: 4),
              Icon(
                _showRemainingFaces
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: getEnteColorScheme(context).textMuted,
              ),
            ],
          ),
        ),
        if (_showRemainingFaces) ...[
          const SizedBox(height: 8),
          _buildFaceGrid(_remainingFaces),
        ],
      ],
    );
  }
}

class _FaceInfo {
  final Face face;
  final Uint8List faceCrop;
  final String? clusterID;
  final PersonEntity? person;

  _FaceInfo({
    required this.face,
    required this.faceCrop,
    this.clusterID,
    this.person,
  });
}

enum NoFacesReason {
  fileNotUploaded,
  fileNotAnalyzed,
  noFacesFound,
  faceThumbnailGenerationFailed,
}

String getNoFaceReasonText(BuildContext context, NoFacesReason reason) {
  switch (reason) {
    case NoFacesReason.fileNotUploaded:
      return S.of(context).fileNotUploadedYet;
    case NoFacesReason.fileNotAnalyzed:
      return S.of(context).imageNotAnalyzed;
    case NoFacesReason.noFacesFound:
      return S.of(context).noFacesFound;
    case NoFacesReason.faceThumbnailGenerationFailed:
      return "Unable to generate face thumbnails";
  }
}
