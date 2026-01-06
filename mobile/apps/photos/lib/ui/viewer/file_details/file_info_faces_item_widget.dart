import "dart:async";
import "dart:typed_data";

import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/service_locator.dart" show flagService;
import "package:photos/services/machine_learning/face_ml/face_filtering/face_filtering_constants.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart"
    show ManualPersonAssignmentResult, PersonService;
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/buttons/chip_button_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file_details/file_info_face_widget.dart";
import "package:photos/ui/viewer/people/add_files_to_person_page.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/people_page.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final Logger _logger = Logger("FacesItemWidget");

class FacesItemWidget extends StatefulWidget {
  final EnteFile file;
  const FacesItemWidget(this.file, {super.key});

  @override
  State<FacesItemWidget> createState() => _FacesItemWidgetState();
}

class _FacesItemWidgetState extends State<FacesItemWidget> {
  static const double _kHeaderActionHeight = 48;
  bool _isEditMode = false;
  bool _showRemainingFaces = false;
  bool _isLoading = true;
  List<_FaceInfo> _defaultFaces = [];
  List<_FaceInfo> _remainingFaces = [];
  List<PersonEntity> _manualPersons = [];
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
      if (isRefresh) {
        await PersonService.instance.refreshPersonCache();
      }
      final result = await _fetchFaceData();
      if (mounted) {
        setState(() {
          _defaultFaces = result.defaultFaces;
          _remainingFaces = result.remainingFaces;
          _manualPersons = result.manualPersons;
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

    final hasFaceData = _defaultFaces.isNotEmpty || _remainingFaces.isNotEmpty;
    final hasManual = _manualPersons.isNotEmpty;
    if (!hasFaceData && !hasManual) {
      return _buildNoFacesWidget();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final thumbnailWidth = screenWidth * 0.16;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppLocalizations.of(context).people,
                style: getEnteTextTheme(context).small,
              ),
              _editStateButton(),
            ],
          ),
          const SizedBox(height: 10),
          _buildPeopleGrid(thumbnailWidth),
          if (_remainingFaces.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildRemainingFacesSection(thumbnailWidth),
          ],
        ],
      ),
    );
  }

  Widget _buildPeopleGrid(double thumbnailWidth) {
    final children = <Widget>[];

    // Add manual person widgets first
    for (final person in _manualPersons) {
      children.add(
        _ManualPersonTag(
          key: ValueKey(person.remoteID),
          person: person,
          thumbnailWidth: thumbnailWidth,
          onTap: () => _openPersonPage(person),
          isEditMode: _isEditMode,
          onRemove: () => _onRemoveManualPerson(person),
        ),
      );
    }

    // Add face widgets
    for (final faceInfo in _defaultFaces) {
      children.add(
        FileInfoFaceWidget(
          widget.file,
          faceInfo.face,
          faceCrop: faceInfo.faceCrop,
          person: faceInfo.person,
          clusterID: faceInfo.clusterID,
          width: thumbnailWidth,
          isEditMode: _isEditMode,
          reloadAllFaces: () => loadFaces(isRefresh: true),
        ),
      );
    }

    // Add "Add person" button at the end
    if (flagService.manualTagFileToPerson &&
        widget.file.uploadedFileID != null) {
      children.add(_buildAddPersonButton(thumbnailWidth));
    }

    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Wrap(
        runSpacing: 8,
        spacing: 12,
        children: children,
      ),
    );
  }

  Widget _buildAddPersonButton(double thumbnailWidth) {
    final colorScheme = getEnteColorScheme(context);
    const strokeWidth = 1.0;
    final innerSize = thumbnailWidth - strokeWidth * 2;
    return GestureDetector(
      onTap: _openAddFilesToPersonPage,
      child: DottedBorder(
        color: colorScheme.strokeMuted,
        strokeWidth: strokeWidth,
        dashPattern: const [4, 4],
        padding: EdgeInsets.zero,
        customPath: faceThumbnailSquircleOuterPath,
        child: SizedBox(
          height: innerSize,
          width: innerSize,
          child: Center(
            child: Icon(
              Icons.person_add_alt_1_outlined,
              color: colorScheme.strokeMuted,
              size: 24,
            ),
          ),
        ),
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

  List<PersonEntity> _getManualPersonsForFile(
    Map<String, PersonEntity> persons,
    List<_FaceInfo> defaultFaces,
    List<_FaceInfo> remainingFaces,
  ) {
    final uploadedFileID = widget.file.uploadedFileID;
    if (uploadedFileID == null) return [];

    final existingPersonIDs = <String>{
      ...defaultFaces.map((face) => face.person?.remoteID).whereType<String>(),
      ...remainingFaces
          .map((face) => face.person?.remoteID)
          .whereType<String>(),
    };

    final manualPersons = persons.values.where((person) {
      if (existingPersonIDs.contains(person.remoteID)) {
        return false;
      }
      return person.data.manuallyAssigned.contains(uploadedFileID);
    }).toList();

    manualPersons.sort(
      (a, b) => a.data.name.toLowerCase().compareTo(b.data.name.toLowerCase()),
    );
    return manualPersons;
  }

  Widget _buildNoFacesWidget() {
    final reason = _errorReason ?? NoFacesReason.noFacesFound;
    final showManualTagOption = flagService.manualTagFileToPerson &&
        reason == NoFacesReason.noFacesFound;
    final label = showManualTagOption
        ? AppLocalizations.of(context).noFacesDetectedTapToAdd
        : getNoFaceReasonText(context, reason);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 12, top: 8),
        child: ChipButtonWidget(
          label,
          noChips: true,
          onTap: showManualTagOption ? _openAddFilesToPersonPage : null,
        ),
      ),
    );
  }

  Widget _buildFaceGrid(List<_FaceInfo> faceInfoList, double thumbnailWidth) {
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

  Widget _buildRemainingFacesSection(double thumbnailWidth) {
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
          _buildFaceGrid(_remainingFaces, thumbnailWidth),
        ],
      ],
    );
  }

  Widget _editStateButton() {
    if (_isEditMode) {
      return Padding(
        padding: const EdgeInsets.only(right: 12.0),
        child: SizedBox(
          height: _kHeaderActionHeight,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleEditMode,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        ),
      );
    }
    return IconButtonWidget(
      icon: Icons.edit,
      iconButtonType: IconButtonType.secondary,
      onTap: _toggleEditMode,
    );
  }

  Future<_FaceDataResult> _fetchFaceData() async {
    if (widget.file.uploadedFileID == null) {
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        manualPersons: const [],
        errorReason: NoFacesReason.fileNotUploaded,
      );
    }

    // Fetch persons map early so we can check for manual assignments
    // even when no faces are detected
    final persons = await PersonService.instance.getPersonsMap();

    final mlDataDB = MLDataDB.instance;
    final faces =
        await mlDataDB.getFacesForGivenFileID(widget.file.uploadedFileID!);

    if (faces == null) {
      final manualPersons = _getManualPersonsForFile(persons, [], []);
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        manualPersons: manualPersons,
        errorReason:
            manualPersons.isEmpty ? NoFacesReason.fileNotAnalyzed : null,
      );
    }

    // Get additional data
    final faceIdsToClusterIds = await mlDataDB.getFaceIdsToClusterIds(
      faces.map((face) => face.faceID).toList(),
    );
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
          manualPersons: const [],
          errorReason: NoFacesReason.fileAnalysisFailed,
        );
      }
    }
    if (defaultFaces.isEmpty && remainingFaces.isEmpty) {
      final manualPersons = _getManualPersonsForFile(persons, [], []);
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        manualPersons: manualPersons,
        errorReason: manualPersons.isEmpty ? NoFacesReason.noFacesFound : null,
      );
    }

    if (faceCrops == null) {
      final manualPersons = _getManualPersonsForFile(persons, [], []);
      return _FaceDataResult(
        defaultFaces: [],
        remainingFaces: [],
        manualPersons: manualPersons,
        errorReason: manualPersons.isEmpty
            ? NoFacesReason.faceThumbnailGenerationFailed
            : null,
      );
    }
    for (final face in defaultFaces) {
      if (faceCrops[face.faceID] == null) {
        final manualPersons = _getManualPersonsForFile(persons, [], []);
        return _FaceDataResult(
          defaultFaces: [],
          remainingFaces: [],
          manualPersons: manualPersons,
          errorReason: manualPersons.isEmpty
              ? NoFacesReason.faceThumbnailGenerationFailed
              : null,
        );
      }
    }

    final defaultFacesInfo = await _buildFaceInfoList(
      defaultFaces,
      faceIdsToClusterIds,
      persons,
      clusterIDToPerson,
      faceCrops,
    );
    final remainingFacesInfo = await _buildFaceInfoList(
      remainingFaces,
      faceIdsToClusterIds,
      persons,
      clusterIDToPerson,
      faceCrops,
    );
    return _FaceDataResult(
      defaultFaces: defaultFacesInfo,
      remainingFaces: remainingFacesInfo,
      manualPersons: _getManualPersonsForFile(
        persons,
        defaultFacesInfo,
        remainingFacesInfo,
      ),
    );
  }

  void _toggleEditMode() => setState(() => _isEditMode = !_isEditMode);

  void _toggleRemainingFaces() =>
      setState(() => _showRemainingFaces = !_showRemainingFaces);

  Future<void> _openAddFilesToPersonPage() async {
    final hasPersons =
        await AddFilesToPersonPage.ensureNamedPersonsExist(context);
    if (!mounted || !hasPersons) {
      return;
    }
    final result =
        await Navigator.of(context).push<ManualPersonAssignmentResult>(
      MaterialPageRoute(
        builder: (context) => AddFilesToPersonPage(files: [widget.file]),
      ),
    );
    if (result != null) {
      await loadFaces(isRefresh: true);
    }
  }

  Future<void> _onRemoveManualPerson(PersonEntity person) async {
    final result = await showChoiceActionSheet(
      context,
      title: AppLocalizations.of(context).removePersonTag,
      body: AppLocalizations.of(context).areYouSureRemoveThisPersonTag,
      firstButtonLabel: AppLocalizations.of(context).remove,
      firstButtonType: ButtonType.critical,
      secondButtonLabel: AppLocalizations.of(context).cancel,
      isCritical: true,
    );
    if (result?.action == ButtonAction.first) {
      try {
        await ClusterFeedbackService.instance.removeFilesFromPerson(
          [widget.file],
          person,
        );
        await loadFaces(isRefresh: true);
      } catch (e, s) {
        _logger.severe('Error removing manual person assignment', e, s);
      }
    }
  }

  Future<void> _openPersonPage(PersonEntity person) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PeoplePage(
          person: person,
          searchResult: null,
        ),
      ),
    );
  }
}

class _FaceDataResult {
  final List<_FaceInfo> defaultFaces;
  final List<_FaceInfo> remainingFaces;
  final List<PersonEntity> manualPersons;
  final NoFacesReason? errorReason;

  _FaceDataResult({
    required this.defaultFaces,
    required this.remainingFaces,
    required this.manualPersons,
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

class _ManualPersonTag extends StatelessWidget {
  final PersonEntity person;
  final double thumbnailWidth;
  final VoidCallback onTap;
  final bool isEditMode;
  final VoidCallback? onRemove;

  const _ManualPersonTag({
    super.key,
    required this.person,
    required this.thumbnailWidth,
    required this.onTap,
    this.isEditMode = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final displayName = person.data.isIgnored
        ? '(' + AppLocalizations.of(context).ignored + ')'
        : person.data.name.trim();

    return Semantics(
      button: true,
      label: displayName,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isEditMode ? onRemove : onTap,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: thumbnailWidth,
                    width: thumbnailWidth,
                    decoration: ShapeDecoration(
                      shape: faceThumbnailSquircleBorder(side: thumbnailWidth),
                    ),
                    child: FaceThumbnailSquircleClip(
                      child: PersonFaceWidget(
                        personId: person.remoteID,
                        keepAlive: true,
                      ),
                    ),
                  ),
                  if (isEditMode)
                    Positioned(
                      right: -5,
                      top: -5,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: colorScheme.warning500,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colorScheme.backgroundBase,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.remove,
                          size: 12,
                          color: colorScheme.backgroundBase,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: thumbnailWidth,
                child: Center(
                  child: Text(
                    displayName,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
