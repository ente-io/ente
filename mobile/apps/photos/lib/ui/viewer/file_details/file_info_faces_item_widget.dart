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
  NoFacesReason? _errorReason;

  @override
  void initState() {
    super.initState();
    loadFaces();
  }

  Future<void> loadFaces({bool isRefresh = false}) async {
    if (!isRefresh && mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final result = await _fetchFaceData();
      if (mounted) {
        setState(() {
          _defaultFaces = result.defaultFaces;
          _remainingFaces = result.remainingFaces;
          _errorReason = result.errorReason;
          if (!isRefresh) {
            _isLoading = false;
          }
        });
      }
    } catch (e, s) {
      _logger.severe('Failed to load faces', e, s);
      if (!isRefresh && mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const IconButtonWidget(
          icon: Icons.face_retouching_natural_outlined,
          iconButtonType: IconButtonType.secondary,
        ),
        const SizedBox(width: 12),
        _buildContent(),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(
        child: Padding(
          padding: EdgeInsets.only(top: 8, right: 12),
          child: Center(
            child: EnteLoadingWidget(
              padding: 6,
              size: 20,
              alignment: Alignment.center,
            ),
          ),
        ),
      );
    }

    if (_errorReason != null ||
        (_defaultFaces.isEmpty && _remainingFaces.isEmpty)) {
      return _buildNoFacesWidget();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: SizedBox(
                  height: 24,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context).faces,
                      style: getEnteTextTheme(context).small,
                    ),
                  ),
                ),
              ),
              _editStateButton(),
            ],
          ),
          const SizedBox(height: 20),
          if (_defaultFaces.isNotEmpty) _buildFaceGrid(_defaultFaces),
          if (_remainingFaces.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRemainingFacesSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildFaceGrid(List<_FaceInfo> faceInfoList) {
    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.16;
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Wrap(
        runSpacing: 8,
        spacing: 12,
        children: faceInfoList
            .map(
              (faceInfo) => FileInfoFaceWidget(
                widget.file,
                faceInfo.face,
                faceCrop: faceInfo.faceCrop,
                person: faceInfo.person,
                clusterID: faceInfo.clusterID,
                width: thumbnailWidth,
                isEditMode: _isEditMode,
                reloadAllFaces: () => loadFaces(isRefresh: true),
              ),
            )
            .toList(),
      ),
    );
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

  Widget _buildNoFacesWidget() {
    final reason = _errorReason ?? NoFacesReason.noFacesFound;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 8),
        child: ChipButtonWidget(
          getNoFaceReasonText(context, reason),
          noChips: true,
        ),
      ),
    );
  }

  Widget _buildRemainingFacesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleRemainingFaces,
            child: Row(
              children: [
                Text(
                  AppLocalizations.of(context).otherDetectedFaces,
                  style: getEnteTextTheme(context).miniMuted,
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    _showRemainingFaces
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: getEnteColorScheme(context).textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showRemainingFaces) ...[
          const SizedBox(height: 16),
          _buildFaceGrid(_remainingFaces),
        ],
      ],
    );
  }

  Widget _editStateButton() {
    return SizedBox(
      height: 36,
      child: _isEditMode
          ? Padding(
              padding: const EdgeInsets.only(top: 12.0, right: 12.0),
              child: Center(
                child: GestureDetector(
                  onTap: _toggleEditMode,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: getEnteColorScheme(context).primary500,
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      AppLocalizations.of(context).done,
                      style: getEnteTextTheme(context).small.copyWith(
                            color: getEnteColorScheme(context).primary500,
                          ),
                    ),
                  ),
                ),
              ),
            )
          : IconButtonWidget(
              icon: Icons.edit,
              iconButtonType: IconButtonType.secondary,
              onTap: _toggleEditMode,
            ),
    );
  }

  Future<_FaceDataResult> _fetchFaceData() async {
    if (widget.file.uploadedFileID == null) {
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        errorReason: NoFacesReason.fileNotUploaded,
      );
    }

    final mlDataDB = MLDataDB.instance;
    final faces =
        await mlDataDB.getFacesForGivenFileID(widget.file.uploadedFileID!);

    if (faces == null) {
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        errorReason: NoFacesReason.fileNotAnalyzed,
      );
    }

    // Get additional data
    final faceIdsToClusterIds = await mlDataDB.getFaceIdsToClusterIds(
      faces.map((face) => face.faceID).toList(),
    );
    final persons = await PersonService.instance.getPersonsMap();
    final clusterIDToPerson = await mlDataDB.getClusterIDToPersonID();
    final faceCrops =
        await getCachedFaceCrops(widget.file, faces, useTempCache: true);
    final defaultFaces = <Face>[];
    final remainingFaces = <Face>[];

    for (final face in faces) {
      if (face.score >= kMinimumFaceShowScore) {
        defaultFaces.add(face);
      } else if (clusterIDToPerson[faceIdsToClusterIds[face.faceID] ?? ""] !=
          null) {
        defaultFaces.add(face);
      } else if (face.score >= kMinFaceDetectionScore) {
        remainingFaces.add(face);
      } else if (face.score == -1.0) {
        return _FaceDataResult(
          defaultFaces: [],
          remainingFaces: [],
          errorReason: NoFacesReason.fileAnalysisFailed,
        );
      }
    }
    if (defaultFaces.isEmpty && remainingFaces.isEmpty) {
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        errorReason: NoFacesReason.noFacesFound,
      );
    }

    if (faceCrops == null) {
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        errorReason: NoFacesReason.faceThumbnailGenerationFailed,
      );
    }
    for (final face in defaultFaces) {
      if (faceCrops[face.faceID] == null) {
        return _FaceDataResult(
          defaultFaces: [],
          remainingFaces: [],
          errorReason: NoFacesReason.faceThumbnailGenerationFailed,
        );
      }
    }

    return _FaceDataResult(
      defaultFaces: await _buildFaceInfoList(
        defaultFaces,
        faceIdsToClusterIds,
        persons,
        clusterIDToPerson,
        faceCrops,
      ),
      remainingFaces: await _buildFaceInfoList(
        remainingFaces,
        faceIdsToClusterIds,
        persons,
        clusterIDToPerson,
        faceCrops,
      ),
    );
  }

  void _toggleEditMode() => setState(() => _isEditMode = !_isEditMode);

  void _toggleRemainingFaces() =>
      setState(() => _showRemainingFaces = !_showRemainingFaces);
}

class _FaceDataResult {
  final List<_FaceInfo> defaultFaces;
  final List<_FaceInfo> remainingFaces;
  final NoFacesReason? errorReason;

  _FaceDataResult({
    required this.defaultFaces,
    required this.remainingFaces,
    this.errorReason,
  });
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
  fileAnalysisFailed,
}

String getNoFaceReasonText(BuildContext context, NoFacesReason reason) {
  switch (reason) {
    case NoFacesReason.fileNotUploaded:
      return AppLocalizations.of(context).fileNotUploadedYet;
    case NoFacesReason.fileNotAnalyzed:
      return AppLocalizations.of(context).imageNotAnalyzed;
    case NoFacesReason.noFacesFound:
      return AppLocalizations.of(context).noFacesFound;
    case NoFacesReason.faceThumbnailGenerationFailed:
      return AppLocalizations.of(context).faceThumbnailGenerationFailed;
    case NoFacesReason.fileAnalysisFailed:
      return AppLocalizations.of(context).fileAnalysisFailed;
  }
}
