import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/core/cache/thumbnail_in_memory_cache.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/ml/db.dart';
import 'package:photos/db/offline_files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/ml/face/box.dart';
import 'package:photos/models/ml/face/face.dart';
import 'package:photos/models/ml/face/person_face_source.dart';
import 'package:photos/service_locator.dart' show flagService, isOfflineMode;
import 'package:photos/services/machine_learning/face_ml/person/person_service.dart';
import 'package:photos/services/machine_learning/ml_result.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/face/face_thumbnail_cache.dart';
import 'package:photos/utils/face/face_thumbnail_quality.dart';
import 'package:photos/utils/thumbnail_util.dart';
import 'package:visibility_detector/visibility_detector.dart';

final _logger = Logger('PersonFaceWidget');
const _kMinUnnamedClusterSizeForProgressiveUpgrade = 5;
const _kProgressiveUpgradeUpscaleThreshold = 1.35;
const _kProgressiveUpgradeMinImprovementRatio = 1.2;
const _kProgressiveUpgradeIdleWaitBudget = Duration(seconds: 2);
const _kVisibleTaskTouchInterval = Duration(seconds: 20);

class _PersonFaceLoadResult {
  final Uint8List? faceCropBytes;
  final Uint8List? thumbnailBytes;
  final PersonFaceSource? faceSource;
  final String? personName;

  const _PersonFaceLoadResult._({
    this.faceCropBytes,
    this.thumbnailBytes,
    this.faceSource,
    this.personName,
  });

  const _PersonFaceLoadResult.faceCrop({
    required Uint8List faceCropBytes,
    String? personName,
  }) : this._(
          faceCropBytes: faceCropBytes,
          personName: personName,
        );

  const _PersonFaceLoadResult.thumbnailPreview({
    required Uint8List thumbnailBytes,
    required PersonFaceSource faceSource,
    String? personName,
  }) : this._(
          thumbnailBytes: thumbnailBytes,
          faceSource: faceSource,
          personName: personName,
        );
}

class PersonFaceWidget extends StatefulWidget {
  final String? personId;
  final String? clusterID;
  final bool useFullFile;
  final VoidCallback? onErrorCallback;
  final bool keepAlive;
  final PersonFaceSource? initialFaceSource;
  final String? initialPersonName;
  final String? initialAvatarFaceId;
  final EnteFile? initialPreviewFile;

  /// Physical pixel width for image decoding optimization.
  ///
  /// When provided and > 0, the image will be decoded at this width, with height
  /// computed to preserve aspect ratio. This reduces memory usage for small displays.
  ///
  /// Typically calculated as: `(logicalWidth * MediaQuery.devicePixelRatioOf(context)).toInt()`
  ///
  /// If null or <= 0, the image is decoded at full resolution.
  final int? cachedPixelWidth;

  const PersonFaceWidget({
    this.personId,
    this.clusterID,
    this.useFullFile = true,
    this.onErrorCallback,
    this.keepAlive = false,
    this.initialFaceSource,
    this.initialPersonName,
    this.initialAvatarFaceId,
    this.initialPreviewFile,
    this.cachedPixelWidth,
    super.key,
  }) : assert(
          personId != null || clusterID != null,
          'PersonFaceWidget requires either personId or clusterID to be non-null',
        );

  @override
  State<PersonFaceWidget> createState() => _PersonFaceWidgetState();
}

class _PersonFaceWidgetState extends State<PersonFaceWidget>
    with AutomaticKeepAliveClientMixin {
  Future<_PersonFaceLoadResult?>? _faceLoadFuture;
  EnteFile? fileForFaceCrop;
  Face? _faceForFaceCrop;
  int? _faceCropFileId;
  PersonFaceSource? _resolvedFaceSource;
  String? _personName;
  bool _showingFallback = false;
  bool _fallbackEverUsed = false;
  bool _disposed = false;
  int _upgradeGeneration = 0;
  EnteFile? _requestedThumbnailPreviewFile;
  final Map<int, int> _fullGenerationTaskClaims = <int, int>{};
  final Map<int, int> _thumbnailGenerationTaskClaims = <int, int>{};
  bool _isVisible = false;
  Timer? _visibleTaskTouchTimer;

  static final LRUMap<String, int> _clusterToFileCountCache = LRUMap(1000);

  bool get isPerson => widget.personId != null;

  bool get _shouldUseProgressiveStrategy {
    return widget.useFullFile &&
        !isOfflineMode &&
        flagService.progressivePersonFaceThumbnailsEnabled;
  }

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    _personName = widget.initialPersonName;
    _faceLoadFuture = _loadFace();
  }

  @override
  void dispose() {
    _disposed = true;
    _upgradeGeneration += 1;
    _cancelVisibleTaskTouchTimer();
    _releasePendingFaceGenerationClaims();
    if (_requestedThumbnailPreviewFile != null) {
      removePendingGetThumbnailRequestIfAny(_requestedThumbnailPreviewFile!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: ValueKey(
        'person_face_visibility_${_visibilityKeySuffix()}_${identityHashCode(this)}',
      ),
      onVisibilityChanged: _handleVisibilityChanged,
      child: FutureBuilder<_PersonFaceLoadResult?>(
        future: _faceLoadFuture,
        builder: (context, snapshot) {
          final loadResult = snapshot.data;
          if (loadResult?.faceCropBytes != null) {
            return _buildFaceImage(
              _buildImageFromBytes(loadResult!.faceCropBytes!),
            );
          }
          if (loadResult?.thumbnailBytes != null &&
              loadResult?.faceSource != null) {
            final previewDimensions = _previewImageDimensionsForSource(
              loadResult!.faceSource!,
            );
            if (previewDimensions != null) {
              return _buildFaceImage(
                _DirectThumbnailFacePreview(
                  thumbnailBytes: loadResult.thumbnailBytes!,
                  faceBox: loadResult.faceSource!.face.detection.box,
                  imageDimensions: previewDimensions,
                ),
              );
            }
          }
          if (snapshot.connectionState == ConnectionState.waiting ||
              snapshot.connectionState == ConnectionState.active) {
            return EnteLoadingWidget(
              color: getEnteColorScheme(context).fillMuted,
            );
          }
          if (snapshot.hasError) {
            _logger.severe(
              'Error getting cover face for person',
              snapshot.error,
              snapshot.stackTrace,
            );
          } else {
            _logger.severe(
              'No cover face found for person or cluster.',
            );
          }
          return _EmptyPersonThumbnail(
            initial: isPerson ? (loadResult?.personName ?? _personName) : null,
          );
        },
      ),
    );
  }

  Widget _buildImageFromBytes(Uint8List imageBytes) {
    final shouldOptimize =
        widget.cachedPixelWidth != null && widget.cachedPixelWidth! > 0;
    final ImageProvider imageProvider = shouldOptimize
        ? Image.memory(
            imageBytes,
            cacheWidth: widget.cachedPixelWidth,
          ).image
        : MemoryImage(imageBytes);
    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
    );
  }

  Widget _buildFaceImage(Widget child) {
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (kDebugMode && _showingFallback)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '(T)',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<_PersonFaceLoadResult?> _loadFace() async {
    if (!widget.useFullFile) {
      final thumbnailCrop = await _getFaceCrop(useFullFile: false);
      if (thumbnailCrop == null) {
        return null;
      }
      _fallbackEverUsed = true;
      _showingFallback = false;
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: thumbnailCrop,
        personName: _personName,
      );
    }

    if (!_shouldUseProgressiveStrategy) {
      return _loadFaceLegacy();
    }

    return _loadFaceProgressive();
  }

  Future<_PersonFaceLoadResult?> _loadFaceLegacy() async {
    final fullCrop = await _getFaceCrop(useFullFile: true);
    if (fullCrop != null) {
      _showingFallback = false;
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: fullCrop,
        personName: _personName,
      );
    }

    final String personOrClusterId = widget.personId ?? widget.clusterID!;
    _logger.warning(
      'Full face crop unavailable for $personOrClusterId, attempting thumbnail fallback.',
    );

    final fallbackCrop = await _getFaceCrop(useFullFile: false);
    if (fallbackCrop != null) {
      _showingFallback = true;
      _fallbackEverUsed = true;
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: fallbackCrop,
        personName: _personName,
      );
    }

    _logger
        .warning('Thumbnail fallback also unavailable for $personOrClusterId.');
    return null;
  }

  Future<_PersonFaceLoadResult?> _loadFaceProgressive() async {
    final String personOrClusterId = widget.personId ?? widget.clusterID!;
    final faceSource = await _resolveFaceSource();
    if (faceSource == null) {
      return null;
    }

    final cachedFullCrop = await _loadCachedFullFaceCropIfAvailable(faceSource);
    if (cachedFullCrop != null) {
      _showingFallback = false;
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: cachedFullCrop,
        personName: _personName,
      );
    }

    if (_previewImageDimensionsForSource(faceSource) != null) {
      final thumbnailBytes = await _loadThumbnailPreviewBytes(faceSource.file);
      if (thumbnailBytes != null) {
        _showingFallback = true;
        _fallbackEverUsed = true;
        final generation = ++_upgradeGeneration;
        unawaited(_attemptFullQualityUpgrade(generation));
        return _PersonFaceLoadResult.thumbnailPreview(
          thumbnailBytes: thumbnailBytes,
          faceSource: faceSource,
          personName: _personName,
        );
      }
    }

    final thumbnailCrop = await _getFaceCrop(
      useFullFile: false,
      resolvedSource: faceSource,
    );
    if (thumbnailCrop != null) {
      _showingFallback = true;
      _fallbackEverUsed = true;
      final generation = ++_upgradeGeneration;
      unawaited(_attemptFullQualityUpgrade(generation));
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: thumbnailCrop,
        personName: _personName,
      );
    }

    _logger.warning(
      'Thumbnail face crop unavailable for $personOrClusterId, attempting full-file generation.',
    );
    final fullCrop = await _getFaceCrop(
      useFullFile: true,
      resolvedSource: faceSource,
    );
    if (fullCrop != null) {
      _showingFallback = false;
      return _PersonFaceLoadResult.faceCrop(
        faceCropBytes: fullCrop,
        personName: _personName,
      );
    }
    _logger.warning(
      'Full face crop also unavailable for $personOrClusterId after thumbnail miss.',
    );
    return null;
  }

  ImageDimensions? _previewImageDimensionsForSource(
    PersonFaceSource faceSource,
  ) {
    final cachedThumbnailDimensions =
        getCachedThumbnailSourceDimensionsForFileId(faceSource.resolvedFileId);
    if (cachedThumbnailDimensions != null) {
      return cachedThumbnailDimensions;
    }
    if (faceSource.file.width > 0 && faceSource.file.height > 0) {
      return (
        width: faceSource.file.width,
        height: faceSource.file.height,
      );
    }
    return null;
  }

  Future<Uint8List?> _loadThumbnailPreviewBytes(EnteFile file) async {
    final cachedThumbnailBytes = ThumbnailInMemoryLruCache.get(file);
    if (cachedThumbnailBytes != null) {
      return cachedThumbnailBytes;
    }

    _requestedThumbnailPreviewFile = file;
    try {
      return await getThumbnail(file);
    } finally {
      if (_requestedThumbnailPreviewFile == file) {
        _requestedThumbnailPreviewFile = null;
      }
    }
  }

  Future<Uint8List?> _loadCachedFullFaceCropIfAvailable(
    PersonFaceSource faceSource,
  ) async {
    final personOrClusterId = widget.personId ?? widget.clusterID!;
    final cachedFullCrop =
        checkInMemoryCachedCropForPersonOrClusterID(personOrClusterId);
    if (cachedFullCrop != null) {
      return cachedFullCrop;
    }
    return getPersistedFullFaceCropIfAvailable(
      faceSource.face.faceID,
      personOrClusterID: personOrClusterId,
    );
  }

  void _applyResolvedFaceSource(PersonFaceSource faceSource) {
    _resolvedFaceSource = faceSource;
    fileForFaceCrop = faceSource.file;
    _faceForFaceCrop = faceSource.face;
    _faceCropFileId = faceSource.resolvedFileId;
    _personName = faceSource.personName ?? _personName;
    cacheFaceSourceForPersonOrClusterID(
      widget.personId ?? widget.clusterID!,
      faceSource,
    );
    _touchVisibleFaceTasks();
  }

  void _handleVisibilityChanged(VisibilityInfo info) {
    final nowVisible = info.visibleFraction >= 0.01;
    if (nowVisible == _isVisible) {
      return;
    }
    _isVisible = nowVisible;
    if (_isVisible) {
      _touchVisibleFaceTasks();
      _visibleTaskTouchTimer = Timer.periodic(
        _kVisibleTaskTouchInterval,
        (_) => _touchVisibleFaceTasks(),
      );
    } else {
      _cancelVisibleTaskTouchTimer();
    }
  }

  void _touchVisibleFaceTasks() {
    if (!_isVisible) {
      return;
    }
    final fileId = _faceCropFileId;
    if (fileId == null) {
      return;
    }
    touchPendingFaceThumbnailGeneration(fileId, useFullFile: false);
    // Keep first-paint work ahead of progressive upgrades. Only reprioritize
    // full-file generation when the tile still has no fallback thumbnail.
    if (widget.useFullFile && !_fallbackEverUsed) {
      touchPendingFaceThumbnailGeneration(fileId, useFullFile: true);
    }
  }

  void _cancelVisibleTaskTouchTimer() {
    _visibleTaskTouchTimer?.cancel();
    _visibleTaskTouchTimer = null;
  }

  void _recordPendingFaceGenerationClaim(
    int fileId, {
    required bool useFullFile,
  }) {
    final claims = useFullFile
        ? _fullGenerationTaskClaims
        : _thumbnailGenerationTaskClaims;
    claims.update(fileId, (count) => count + 1, ifAbsent: () => 1);
  }

  void _releasePendingFaceGenerationClaims() {
    void releaseClaims(Map<int, int> claims, {required bool useFullFile}) {
      for (final entry in claims.entries) {
        for (var i = 0; i < entry.value; i++) {
          checkStopTryingToGenerateFaceThumbnails(
            entry.key,
            useFullFile: useFullFile,
          );
        }
      }
      claims.clear();
    }

    releaseClaims(_fullGenerationTaskClaims, useFullFile: true);
    releaseClaims(_thumbnailGenerationTaskClaims, useFullFile: false);
  }

  String _visibilityKeySuffix() {
    final widgetKey = widget.key;
    if (widgetKey is ValueKey) {
      return widgetKey.value.toString();
    }
    return widget.personId ?? widget.clusterID ?? widgetKey.toString();
  }

  bool _canUseResolvedFaceSource(
    PersonFaceSource faceSource,
    String personOrClusterId,
  ) {
    final currentFaceID =
        checkInMemoryCachedFaceIDForPersonOrClusterID(personOrClusterId);
    return currentFaceID == null || currentFaceID == faceSource.face.faceID;
  }

  Future<bool> _canReuseResolvedFaceSource(
    PersonFaceSource faceSource,
    String personOrClusterId, {
    bool clearSharedCache = false,
  }) async {
    if (!_canUseResolvedFaceSource(faceSource, personOrClusterId)) {
      return false;
    }
    if (isOfflineMode) {
      return true;
    }

    final fileId = faceSource.file.uploadedFileID ?? faceSource.resolvedFileId;

    final hiddenFileIDs = await SearchService.instance.getHiddenFiles().then(
          (files) =>
              files.map((file) => file.uploadedFileID).whereType<int>().toSet(),
        );
    if (!hiddenFileIDs.contains(fileId)) {
      return true;
    }

    _logger.info(
      'Skipping cached face source for hidden file ID $fileId for person: ${widget.personId} or cluster: ${widget.clusterID}',
    );
    if (identical(_resolvedFaceSource, faceSource)) {
      _resolvedFaceSource = null;
    }
    if (clearSharedCache) {
      removeCachedFaceSourceForPersonOrClusterID(personOrClusterId);
    }
    return false;
  }

  Future<PersonFaceSource?> _resolveFaceSource({
    bool notifyOnError = true,
  }) async {
    final personOrClusterId = widget.personId ?? widget.clusterID!;

    if (widget.initialFaceSource != null &&
        await _canReuseResolvedFaceSource(
          widget.initialFaceSource!,
          personOrClusterId,
        )) {
      _applyResolvedFaceSource(widget.initialFaceSource!);
      await cacheFaceIdForPersonOrClusterIfNeeded(
        personOrClusterId,
        widget.initialFaceSource!.face.faceID,
      );
      return widget.initialFaceSource;
    }

    if (_resolvedFaceSource != null) {
      if (await _canReuseResolvedFaceSource(
        _resolvedFaceSource!,
        personOrClusterId,
      )) {
        return _resolvedFaceSource;
      }
    }

    final cachedFaceSource =
        checkCachedFaceSourceForPersonOrClusterID(personOrClusterId);
    if (cachedFaceSource != null) {
      if (await _canReuseResolvedFaceSource(
        cachedFaceSource,
        personOrClusterId,
        clearSharedCache: true,
      )) {
        _applyResolvedFaceSource(cachedFaceSource);
        await cacheFaceIdForPersonOrClusterIfNeeded(
          personOrClusterId,
          cachedFaceSource.face.faceID,
        );
        return cachedFaceSource;
      }
    }

    try {
      String? fixedFaceID = widget.initialAvatarFaceId;
      final mlDataDB =
          isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
      if (isPerson && !isOfflineMode && fixedFaceID == null) {
        final personEntity =
            await PersonService.instance.getPerson(widget.personId!);
        if (personEntity == null) {
          _logger.severe(
            'Person with ID ${widget.personId} not found, cannot get cover face.',
          );
          return null;
        }
        _personName = personEntity.data.name;
        fixedFaceID = personEntity.data.avatarFaceID;
      }
      fixedFaceID ??= await checkUsedFaceIDForPersonOrClusterId(
        personOrClusterId,
      );

      EnteFile? selectedFileForFaceCrop;
      if (isOfflineMode) {
        final allFiles = await SearchService.instance.getAllFilesForSearch();
        final localIdToFile = <String, EnteFile>{};
        for (final file in allFiles) {
          final localId = file.localID;
          if (localId != null && localId.isNotEmpty) {
            localIdToFile[localId] = file;
          }
        }

        if (fixedFaceID != null) {
          final localIntId = getFileIdFromFaceId<int>(fixedFaceID);
          final localId =
              await OfflineFilesDB.instance.getLocalIdForIntId(localIntId);
          if (localId == null) {
            await checkRemoveCachedFaceIDForPersonOrClusterId(
              personOrClusterId,
            );
            fixedFaceID = null;
          } else {
            selectedFileForFaceCrop = localIdToFile[localId];
            if (selectedFileForFaceCrop == null) {
              await checkRemoveCachedFaceIDForPersonOrClusterId(
                personOrClusterId,
              );
              fixedFaceID = null;
            }
          }
        }

        if (selectedFileForFaceCrop == null) {
          final List<String> allFaces = isPerson
              ? await mlDataDB
                  .getFaceIDsForPersonOrderedByScore(widget.personId!)
              : await mlDataDB
                  .getFaceIDsForClusterOrderedByScore(widget.clusterID!);
          final localIntIds = allFaces
              .map((faceID) => getFileIdFromFaceId<int>(faceID))
              .toSet();
          final localIdMap =
              await OfflineFilesDB.instance.getLocalIdsForIntIds(localIntIds);
          for (final faceID in allFaces) {
            final localIntId = getFileIdFromFaceId<int>(faceID);
            final localId = localIdMap[localIntId];
            final candidate = localId != null ? localIdToFile[localId] : null;
            if (candidate != null) {
              selectedFileForFaceCrop = candidate;
              fixedFaceID = faceID;
              break;
            }
          }
        }

        if (selectedFileForFaceCrop == null) {
          final initialPreviewFile = widget.initialPreviewFile;
          final localId = initialPreviewFile?.localID;
          if (localId != null && localId.isNotEmpty) {
            selectedFileForFaceCrop = localIdToFile[localId];
          }
        }

        if (selectedFileForFaceCrop == null) {
          _logger.severe(
            'No suitable local file found for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
          );
          return null;
        }
      } else {
        final hiddenFileIDs =
            await SearchService.instance.getHiddenFiles().then(
                  (files) => files
                      .map((file) => file.uploadedFileID)
                      .whereType<int>()
                      .toSet(),
                );

        final initialPreviewFile = widget.initialPreviewFile;
        if (fixedFaceID != null) {
          final fileID = getFileIdFromFaceId<int>(fixedFaceID);
          if (initialPreviewFile?.uploadedFileID == fileID &&
              !hiddenFileIDs.contains(fileID)) {
            selectedFileForFaceCrop = initialPreviewFile;
          } else {
            final fileInDB = await FilesDB.instance.getAnyUploadedFile(fileID);
            if (fileInDB == null) {
              _logger.severe(
                'File with ID $fileID not found in DB, cannot get cover face.',
              );
              await checkRemoveCachedFaceIDForPersonOrClusterId(
                personOrClusterId,
              );
              fixedFaceID = null;
            } else if (hiddenFileIDs.contains(fileInDB.uploadedFileID)) {
              _logger.info(
                'File with ID $fileID is hidden, skipping it for face crop.',
              );
              await checkRemoveCachedFaceIDForPersonOrClusterId(
                personOrClusterId,
              );
              fixedFaceID = null;
            } else {
              selectedFileForFaceCrop = fileInDB;
            }
          }
        }

        if (selectedFileForFaceCrop == null) {
          final List<String> allFaces = isPerson
              ? await mlDataDB
                  .getFaceIDsForPersonOrderedByScore(widget.personId!)
              : await mlDataDB
                  .getFaceIDsForClusterOrderedByScore(widget.clusterID!);
          for (final faceID in allFaces) {
            final fileID = getFileIdFromFaceId<int>(faceID);
            if (hiddenFileIDs.contains(fileID)) {
              _logger.info(
                'File with ID $fileID is hidden, skipping it for face crop.',
              );
              continue;
            }
            selectedFileForFaceCrop =
                await FilesDB.instance.getAnyUploadedFile(fileID);
            if (selectedFileForFaceCrop != null) {
              _logger.info(
                'Using file ID $fileID for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
              );
              fixedFaceID = faceID;
              break;
            }
          }
        }

        if (selectedFileForFaceCrop == null &&
            initialPreviewFile != null &&
            initialPreviewFile.uploadedFileID != null &&
            !hiddenFileIDs.contains(initialPreviewFile.uploadedFileID)) {
          selectedFileForFaceCrop = initialPreviewFile;
        }

        if (selectedFileForFaceCrop == null) {
          _logger.severe(
            'No suitable file found for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
          );
          return null;
        }
      }

      final int? recentFileID;
      if (isOfflineMode) {
        final localId = selectedFileForFaceCrop.localID;
        if (localId == null || localId.isEmpty) {
          _logger.severe(
            'Missing local ID for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
          );
          return null;
        }
        recentFileID =
            await OfflineFilesDB.instance.getOrCreateLocalIntId(localId);
      } else {
        recentFileID = selectedFileForFaceCrop.uploadedFileID;
      }
      if (recentFileID == null) {
        _logger.severe(
          'Missing file id for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
        );
        return null;
      }

      final face = await mlDataDB.getCoverFaceForPerson(
        recentFileID: recentFileID,
        avatarFaceId: fixedFaceID,
        personID: widget.personId,
        clusterID: widget.clusterID,
      );
      if (face == null) {
        _logger.severe(
          'No cover face for person: ${widget.personId} or cluster ${widget.clusterID} and fileID $recentFileID',
        );
        await checkRemoveCachedFaceIDForPersonOrClusterId(personOrClusterId);
        return null;
      }
      await cacheFaceIdForPersonOrClusterIfNeeded(
        personOrClusterId,
        face.faceID,
      );

      final faceSource = PersonFaceSource(
        file: selectedFileForFaceCrop,
        face: face,
        resolvedFileId: recentFileID,
        personName: _personName ?? widget.initialPersonName,
      );
      _applyResolvedFaceSource(faceSource);
      return faceSource;
    } catch (e, s) {
      _logger.severe(
        'Error resolving face source for person: ${widget.personId} or cluster ${widget.clusterID}',
        e,
        s,
      );
      if (notifyOnError) {
        widget.onErrorCallback?.call();
      }
      return null;
    }
  }

  Future<void> _attemptFullQualityUpgrade(int generation) async {
    if (_shouldAbortUpgrade(generation)) {
      return;
    }

    final face = _faceForFaceCrop;
    final sourceFile = fileForFaceCrop;
    if (face == null || sourceFile == null) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=missing_face_or_file person=${widget.personId} cluster=${widget.clusterID}',
      );
      return;
    }
    if (sourceFile.fileType == FileType.video) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=video_source person=${widget.personId} cluster=${widget.clusterID}',
      );
      return;
    }

    if (!isPerson && await _isSmallUnnamedCluster()) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=small_unnamed_cluster cluster=${widget.clusterID}',
      );
      return;
    }

    if (await hasPersistedFullFaceCrop(face.faceID)) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=full_crop_cached face=${face.faceID}',
      );
      final fullCrop = await _getFaceCrop(
        useFullFile: true,
        notifyOnError: false,
      );
      if (fullCrop == null || _shouldAbortUpgrade(generation) || !mounted) {
        return;
      }
      setState(() {
        _showingFallback = false;
        _faceLoadFuture = Future.value(
          _PersonFaceLoadResult.faceCrop(
            faceCropBytes: fullCrop,
            personName: _personName,
          ),
        );
      });
      return;
    }

    if (sourceFile.width <= 0 || sourceFile.height <= 0) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=missing_full_dimensions file=${sourceFile.uploadedFileID}',
      );
      return;
    }

    final cachedThumbnailDimensions = _faceCropFileId != null
        ? getCachedThumbnailSourceDimensionsForFileId(_faceCropFileId!)
        : null;
    final thumbnailDimensions = cachedThumbnailDimensions ??
        estimateThumbnailDimensionsFromFullDimensions(
          fullWidth: sourceFile.width,
          fullHeight: sourceFile.height,
        );
    if (thumbnailDimensions == null) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=missing_thumbnail_dimensions file=${sourceFile.uploadedFileID}',
      );
      return;
    }
    if (cachedThumbnailDimensions == null) {
      _logger.fine(
        'person_face_thumbnail_upgrade_thumbnail_dimensions_source=estimated '
        'file=${sourceFile.uploadedFileID} '
        'estimated=${thumbnailDimensions.width}x${thumbnailDimensions.height}',
      );
    }

    final decision = shouldUpgradeFromThumbnail(
      faceBox: face.detection.box,
      thumbnailWidth: thumbnailDimensions.width,
      thumbnailHeight: thumbnailDimensions.height,
      fullWidth: sourceFile.width,
      fullHeight: sourceFile.height,
      upscaleThreshold: _kProgressiveUpgradeUpscaleThreshold,
      minImprovementRatio: _kProgressiveUpgradeMinImprovementRatio,
    );
    if (!decision.shouldUpgrade) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=${decision.reason} '
        'thumbUpscale=${decision.thumbnailUpscaleFactor.toStringAsFixed(2)} '
        'fullUpscale=${decision.fullUpscaleFactor.toStringAsFixed(2)} '
        'improvement=${decision.improvementRatio.toStringAsFixed(2)} '
        'person=${widget.personId} cluster=${widget.clusterID}',
      );
      return;
    }

    _logger.fine(
      'person_face_thumbnail_upgrade_waiting_for_idle '
      'person=${widget.personId} cluster=${widget.clusterID} '
      'thumbUpscale=${decision.thumbnailUpscaleFactor.toStringAsFixed(2)}',
    );
    final didReachThumbnailIdle = await waitForThumbnailFaceGenerationIdle(
      shouldStopWaiting: () => _shouldAbortUpgrade(generation),
      maxWait: _kProgressiveUpgradeIdleWaitBudget,
    );
    if (_shouldAbortUpgrade(generation)) {
      return;
    }
    if (!didReachThumbnailIdle) {
      _logger.fine(
        'person_face_thumbnail_upgrade_wait_idle_timeout person=${widget.personId} cluster=${widget.clusterID}',
      );
    }

    _logger.info(
      'person_face_thumbnail_upgrade_started person=${widget.personId} cluster=${widget.clusterID}',
    );
    final fullCrop = await _getFaceCrop(
      useFullFile: true,
      notifyOnError: false,
    );
    if (fullCrop == null || _shouldAbortUpgrade(generation)) {
      _logger.fine(
        'person_face_thumbnail_upgrade_skipped reason=full_crop_unavailable person=${widget.personId} cluster=${widget.clusterID}',
      );
      return;
    }

    if (!mounted) {
      return;
    }
    setState(() {
      _showingFallback = false;
      _faceLoadFuture = Future.value(
        _PersonFaceLoadResult.faceCrop(
          faceCropBytes: fullCrop,
          personName: _personName,
        ),
      );
    });

    _logger.info(
      'person_face_thumbnail_upgrade_applied person=${widget.personId} cluster=${widget.clusterID}',
    );
  }

  bool _shouldAbortUpgrade(int generation) {
    return _disposed || generation != _upgradeGeneration;
  }

  Future<bool> _isSmallUnnamedCluster() async {
    final clusterID = widget.clusterID;
    if (clusterID == null || isPerson) {
      return false;
    }
    final cachedFileCount = _clusterToFileCountCache.get(clusterID);
    if (cachedFileCount != null) {
      return cachedFileCount < _kMinUnnamedClusterSizeForProgressiveUpgrade;
    }

    final mlDataDB =
        isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
    final fileCount = await mlDataDB
        .getFileIDsOfClusterID(clusterID)
        .then((fileIDs) => fileIDs.length);
    _clusterToFileCountCache.put(clusterID, fileCount);
    return fileCount < _kMinUnnamedClusterSizeForProgressiveUpgrade;
  }

  Future<Uint8List?> _getFaceCrop({
    required bool useFullFile,
    PersonFaceSource? resolvedSource,
    bool notifyOnError = true,
  }) async {
    try {
      final String personOrClusterId = widget.personId ?? widget.clusterID!;
      final tryInMemoryCachedCrop =
          checkInMemoryCachedCropForPersonOrClusterID(personOrClusterId);
      if (tryInMemoryCachedCrop != null) {
        return tryInMemoryCachedCrop;
      }
      if (!useFullFile) {
        final tryInMemoryCachedThumbnailCrop =
            checkInMemoryCachedThumbnailCropForPersonOrClusterID(
          personOrClusterId,
        );
        if (tryInMemoryCachedThumbnailCrop != null) {
          return tryInMemoryCachedThumbnailCrop;
        }
      }

      final faceSource = resolvedSource ??
          await _resolveFaceSource(notifyOnError: notifyOnError);
      if (faceSource == null) {
        return null;
      }

      var didRecordGenerationClaim = false;
      final cropMap = await getCachedFaceCrops(
        faceSource.file,
        [faceSource.face],
        useFullFile: useFullFile,
        personOrClusterID: personOrClusterId,
        onGenerationTaskQueued: () {
          if (didRecordGenerationClaim) {
            return;
          }
          didRecordGenerationClaim = true;
          _recordPendingFaceGenerationClaim(
            faceSource.resolvedFileId,
            useFullFile: useFullFile,
          );
        },
        useTempCache: false,
      );
      _applyResolvedFaceSource(faceSource);
      final result = cropMap?[faceSource.face.faceID];
      if (result == null) {
        _logger.severe(
          'Null cover face crop for person: ${widget.personId} or cluster ${widget.clusterID} and fileID ${faceSource.resolvedFileId}',
        );
      }
      return result;
    } catch (e, s) {
      _logger.severe(
        'Error getting cover face for person: ${widget.personId} or cluster ${widget.clusterID}',
        e,
        s,
      );
      if (notifyOnError) {
        widget.onErrorCallback?.call();
      }
      return null;
    }
  }
}

class _DirectThumbnailFacePreview extends StatelessWidget {
  final Uint8List thumbnailBytes;
  final FaceBox faceBox;
  final ImageDimensions imageDimensions;

  const _DirectThumbnailFacePreview({
    required this.thumbnailBytes,
    required this.faceBox,
    required this.imageDimensions,
  });

  @override
  Widget build(BuildContext context) {
    final crop = computeNormalizedFaceCrop(faceBox);
    if (crop == null) {
      return const SizedBox.shrink();
    }

    const imageHeight = 1000.0;
    final imageWidth =
        imageHeight * imageDimensions.width / imageDimensions.height;
    final cropX = crop.x * imageWidth;
    final cropY = crop.y * imageHeight;
    final cropWidth = crop.width * imageWidth;
    final cropHeight = crop.height * imageHeight;

    if (cropWidth <= 0 || cropHeight <= 0) {
      return const SizedBox.shrink();
    }

    return ClipRect(
      child: SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: cropWidth,
            height: cropHeight,
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Positioned(
                    left: -cropX,
                    top: -cropY,
                    width: imageWidth,
                    height: imageHeight,
                    child: Image.memory(
                      thumbnailBytes,
                      fit: BoxFit.fill,
                      gaplessPlayback: true,
                      filterQuality: FilterQuality.low,
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

class _EmptyPersonThumbnail extends StatelessWidget {
  final String? initial;

  const _EmptyPersonThumbnail({
    this.initial,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final trimmed = initial?.trim();
    final hasInitial = trimmed != null && trimmed.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.fillFaint,
        border: Border.all(
          color: colorScheme.strokeFaint,
          width: 1,
        ),
      ),
      child: Center(
        child: hasInitial
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final shortestSide = constraints.biggest.shortestSide.isFinite
                      ? constraints.biggest.shortestSide
                      : 0;
                  final fontSize = shortestSide > 0
                      ? shortestSide * 0.42
                      : textTheme.h2.fontSize ?? 24;
                  return Text(
                    trimmed.substring(0, 1).toUpperCase(),
                    style: textTheme.h2Bold.copyWith(
                      color: colorScheme.textMuted,
                      fontSize: fontSize,
                      height: 1,
                    ),
                  );
                },
              )
            : Icon(
                Icons.person_outline,
                color: colorScheme.strokeMuted,
              ),
      ),
    );
  }
}
