import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/cache/lru_map.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/db/ml/db.dart';
import 'package:photos/db/offline_files_db.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/ml/face/face.dart';
import 'package:photos/models/ml/face/person.dart';
import 'package:photos/service_locator.dart' show flagService, isOfflineMode;
import 'package:photos/services/machine_learning/face_ml/person/person_service.dart';
import 'package:photos/services/machine_learning/ml_result.dart';
import 'package:photos/services/search_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/face/face_thumbnail_cache.dart';
import 'package:photos/utils/face/face_thumbnail_quality.dart';

final _logger = Logger('PersonFaceWidget');
const _kMinUnnamedClusterSizeForProgressiveUpgrade = 5;
const _kProgressiveUpgradeUpscaleThreshold = 1.35;
const _kProgressiveUpgradeMinImprovementRatio = 1.2;
const _kProgressiveUpgradeIdleWaitBudget = Duration(seconds: 2);

class PersonFaceWidget extends StatefulWidget {
  final String? personId;
  final String? clusterID;
  final bool useFullFile;
  final VoidCallback? onErrorCallback;
  final bool keepAlive;

  /// Physical pixel width for image decoding optimization.
  ///
  /// When provided and > 0, the image will be decoded at this width, with height
  /// computed to preserve aspect ratio. This reduces memory usage for small displays.
  ///
  /// Typically calculated as: `(logicalWidth * MediaQuery.devicePixelRatioOf(context)).toInt()`
  ///
  /// If null or <= 0, the image is decoded at full resolution.
  final int? cachedPixelWidth;

  // PersonFaceWidget constructor checks that both personId and clusterID are not null
  // and that the file is not null
  const PersonFaceWidget({
    this.personId,
    this.clusterID,
    this.useFullFile = true,
    this.onErrorCallback,
    this.keepAlive = false,
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
  Future<Uint8List?>? faceCropFuture;
  EnteFile? fileForFaceCrop;
  Face? _faceForFaceCrop;
  int? _faceCropFileId;
  String? _personName;
  bool _showingFallback = false;
  bool _fallbackEverUsed = false;
  bool _disposed = false;
  int _upgradeGeneration = 0;

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
    faceCropFuture = _loadFaceCrop();
  }

  @override
  void dispose() {
    _disposed = true;
    _upgradeGeneration += 1;
    if (_faceCropFileId != null) {
      if (widget.useFullFile) {
        checkStopTryingToGenerateFaceThumbnails(
          _faceCropFileId!,
          useFullFile: true,
        );
      }
      if (_fallbackEverUsed) {
        checkStopTryingToGenerateFaceThumbnails(
          _faceCropFileId!,
          useFullFile: false,
        );
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // Calling super.build for AutomaticKeepAliveClientMixin

    return FutureBuilder<Uint8List?>(
      future: faceCropFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          // Only cacheWidth (not cacheHeight) to preserve aspect ratio.
          // Face crops are typically portrait, so constraining width ensures
          // sufficient height for BoxFit.cover without upscaling.
          final shouldOptimize =
              widget.cachedPixelWidth != null && widget.cachedPixelWidth! > 0;
          final ImageProvider imageProvider = shouldOptimize
              ? Image.memory(
                  snapshot.data!,
                  cacheWidth: widget.cachedPixelWidth,
                ).image
              : MemoryImage(snapshot.data!);
          return Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
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
            'faceCropFuture is null, no cover face found for person or cluster.',
          );
        }
        return _EmptyPersonThumbnail(
          initial: isPerson ? _personName : null,
        );
      },
    );
  }

  Future<Uint8List?> _loadFaceCrop() async {
    if (!widget.useFullFile) {
      final Uint8List? thumbnailCrop =
          await _getFaceCrop(useFullFile: widget.useFullFile);
      if (thumbnailCrop != null) {
        _fallbackEverUsed = true;
      }
      _showingFallback = false;
      return thumbnailCrop;
    }

    if (!_shouldUseProgressiveStrategy) {
      return _loadFaceCropLegacy();
    }

    return _loadFaceCropProgressive();
  }

  Future<Uint8List?> _loadFaceCropLegacy() async {
    final Uint8List? fullCrop = await _getFaceCrop(useFullFile: true);
    if (fullCrop != null) {
      _showingFallback = false;
      return fullCrop;
    }

    final String personOrClusterId = widget.personId ?? widget.clusterID!;
    _logger.warning(
      'Full face crop unavailable for $personOrClusterId, attempting thumbnail fallback.',
    );

    final Uint8List? fallbackCrop = await _getFaceCrop(useFullFile: false);
    if (fallbackCrop != null) {
      _showingFallback = true;
      _fallbackEverUsed = true;
      return fallbackCrop;
    }

    _logger
        .warning('Thumbnail fallback also unavailable for $personOrClusterId.');
    return null;
  }

  Future<Uint8List?> _loadFaceCropProgressive() async {
    final String personOrClusterId = widget.personId ?? widget.clusterID!;
    final Uint8List? thumbnailCrop = await _getFaceCrop(useFullFile: false);
    if (thumbnailCrop == null) {
      _logger.warning(
        'Thumbnail face crop unavailable for $personOrClusterId, attempting full-file generation.',
      );
      final Uint8List? fullCrop = await _getFaceCrop(useFullFile: true);
      if (fullCrop != null) {
        _showingFallback = false;
        return fullCrop;
      }
      _logger.warning(
        'Full face crop also unavailable for $personOrClusterId after thumbnail miss.',
      );
      return null;
    }

    _showingFallback = true;
    _fallbackEverUsed = true;
    final generation = ++_upgradeGeneration;
    unawaited(_attemptFullQualityUpgrade(generation));
    return thumbnailCrop;
  }

  Future<void> _attemptFullQualityUpgrade(int generation) async {
    if (_shouldAbortUpgrade(generation)) {
      return;
    }

    final Face? face = _faceForFaceCrop;
    final EnteFile? sourceFile = fileForFaceCrop;
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
      final Uint8List? fullCrop = await _getFaceCrop(
        useFullFile: true,
        notifyOnError: false,
      );
      if (fullCrop == null || _shouldAbortUpgrade(generation) || !mounted) {
        return;
      }
      setState(() {
        _showingFallback = false;
        faceCropFuture = Future.value(fullCrop);
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
    final Uint8List? fullCrop = await _getFaceCrop(
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
      faceCropFuture = Future.value(fullCrop);
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
      String? fixedFaceID;
      PersonEntity? personEntity;
      final mlDataDB =
          isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
      if (isPerson && !isOfflineMode) {
        personEntity = await PersonService.instance.getPerson(widget.personId!);
        if (personEntity == null) {
          _logger.severe(
            'Person with ID ${widget.personId} not found, cannot get cover face.',
          );
          return null;
        }
        _personName = personEntity.data.name;
        fixedFaceID = personEntity.data.avatarFaceID;
      }
      fixedFaceID ??=
          await checkUsedFaceIDForPersonOrClusterId(personOrClusterId);

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
          } else {
            selectedFileForFaceCrop = localIdToFile[localId];
            if (selectedFileForFaceCrop == null) {
              await checkRemoveCachedFaceIDForPersonOrClusterId(
                personOrClusterId,
              );
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
          if (selectedFileForFaceCrop == null) {
            _logger.severe(
              'No suitable local file found for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
            );
            return null;
          }
        }
      } else {
        final hiddenFileIDs =
            await SearchService.instance.getHiddenFiles().then(
                  (files) => files
                      .map((file) => file.uploadedFileID)
                      .whereType<int>()
                      .toSet(),
                );
        if (fixedFaceID != null) {
          final fileID = getFileIdFromFaceId<int>(fixedFaceID);
          final fileInDB = await FilesDB.instance.getAnyUploadedFile(fileID);
          if (fileInDB == null) {
            _logger.severe(
              'File with ID $fileID not found in DB, cannot get cover face.',
            );
            await checkRemoveCachedFaceIDForPersonOrClusterId(
              personOrClusterId,
            );
          } else if (hiddenFileIDs.contains(fileInDB.uploadedFileID)) {
            _logger.info(
              'File with ID $fileID is hidden, skipping it for face crop.',
            );
            await checkRemoveCachedFaceIDForPersonOrClusterId(
              personOrClusterId,
            );
          } else {
            selectedFileForFaceCrop = fileInDB;
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
          if (selectedFileForFaceCrop == null) {
            _logger.severe(
              'No suitable file found for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}',
            );
            return null;
          }
        }
      }

      int? recentFileID;
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

      final Face? face = await mlDataDB.getCoverFaceForPerson(
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

      final cropMap = await getCachedFaceCrops(
        selectedFileForFaceCrop,
        [face],
        useFullFile: useFullFile,
        personOrClusterID: personOrClusterId,
        useTempCache: false,
      );
      fileForFaceCrop = selectedFileForFaceCrop;
      _faceForFaceCrop = face;
      _faceCropFileId = recentFileID;
      final result = cropMap?[face.faceID];
      if (result == null) {
        _logger.severe(
          'Null cover face crop for person: ${widget.personId} or cluster ${widget.clusterID} and fileID $recentFileID',
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
