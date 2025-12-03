import "dart:typed_data";

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/ml/face/face.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/services/machine_learning/ml_result.dart";
import "package:photos/services/search_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final _logger = Logger("PersonFaceWidget");

class PersonFaceWidget extends StatefulWidget {
  final String? personId;
  final String? clusterID;
  final bool useFullFile;
  final VoidCallback? onErrorCallback;
  final bool keepAlive;

  // PersonFaceWidget constructor checks that both personId and clusterID are not null
  // and that the file is not null
  const PersonFaceWidget({
    this.personId,
    this.clusterID,
    this.useFullFile = true,
    this.onErrorCallback,
    this.keepAlive = false,
    super.key,
  }) : assert(
          personId != null || clusterID != null,
          "PersonFaceWidget requires either personId or clusterID to be non-null",
        );

  @override
  State<PersonFaceWidget> createState() => _PersonFaceWidgetState();
}

class _PersonFaceWidgetState extends State<PersonFaceWidget>
    with AutomaticKeepAliveClientMixin {
  Future<Uint8List?>? faceCropFuture;
  EnteFile? fileForFaceCrop;
  String? _personName;
  bool _showingFallback = false;
  bool _fallbackEverUsed = false;

  bool get isPerson => widget.personId != null;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    faceCropFuture = _loadFaceCrop();
  }

  @override
  void dispose() {
    if (fileForFaceCrop != null) {
      checkStopTryingToGenerateFaceThumbnails(
        fileForFaceCrop!.uploadedFileID!,
        useFullFile: widget.useFullFile,
      );
      if (_fallbackEverUsed) {
        checkStopTryingToGenerateFaceThumbnails(
          fileForFaceCrop!.uploadedFileID!,
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
          final ImageProvider imageProvider = MemoryImage(snapshot.data!);
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
                      "(T)",
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
            "Error getting cover face for person",
            snapshot.error,
            snapshot.stackTrace,
          );
        } else {
          _logger.severe(
            "faceCropFuture is null, no cover face found for person or cluster.",
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

    final Uint8List? fullCrop =
        await _getFaceCrop(useFullFile: widget.useFullFile);
    if (fullCrop != null) {
      _showingFallback = false;
      return fullCrop;
    }

    final String personOrClusterId = widget.personId ?? widget.clusterID!;
    _logger.warning(
      "Full face crop unavailable for $personOrClusterId, attempting thumbnail fallback.",
    );

    final Uint8List? fallbackCrop = await _getFaceCrop(useFullFile: false);
    if (fallbackCrop != null) {
      _showingFallback = true;
      _fallbackEverUsed = true;
      return fallbackCrop;
    }

    _logger.warning(
      "Thumbnail fallback also unavailable for $personOrClusterId.",
    );
    return null;
  }

  Future<Uint8List?> _getFaceCrop({required bool useFullFile}) async {
    try {
      final String personOrClusterId = widget.personId ?? widget.clusterID!;
      final tryInMemoryCachedCrop =
          checkInMemoryCachedCropForPersonOrClusterID(personOrClusterId);
      if (tryInMemoryCachedCrop != null) return tryInMemoryCachedCrop;
      String? fixedFaceID;
      PersonEntity? personEntity;
      if (isPerson) {
        personEntity = await PersonService.instance.getPerson(widget.personId!);
        if (personEntity == null) {
          _logger.severe(
            "Person with ID ${widget.personId} not found, cannot get cover face.",
          );
          return null;
        }
        _personName = personEntity.data.name;
        fixedFaceID = personEntity.data.avatarFaceID;
      }
      fixedFaceID ??=
          await checkUsedFaceIDForPersonOrClusterId(personOrClusterId);
      final hiddenFileIDs = await SearchService.instance
          .getHiddenFiles()
          .then((onValue) => onValue.map((e) => e.uploadedFileID));
      EnteFile? fileForFaceCrop;
      if (fixedFaceID != null) {
        final fileID = getFileIdFromFaceId<int>(fixedFaceID);
        final fileInDB = await FilesDB.instance.getAnyUploadedFile(fileID);
        if (fileInDB == null) {
          _logger.severe(
            "File with ID $fileID not found in DB, cannot get cover face.",
          );
          await checkRemoveCachedFaceIDForPersonOrClusterId(
            personOrClusterId,
          );
        } else if (hiddenFileIDs.contains(fileInDB.uploadedFileID)) {
          _logger.info(
            "File with ID $fileID is hidden, skipping it for face crop.",
          );
          await checkRemoveCachedFaceIDForPersonOrClusterId(
            personOrClusterId,
          );
        } else {
          fileForFaceCrop = fileInDB;
        }
      }
      if (fileForFaceCrop == null) {
        final List<String> allFaces = isPerson
            ? await MLDataDB.instance
                .getFaceIDsForPersonOrderedByScore(widget.personId!)
            : await MLDataDB.instance
                .getFaceIDsForClusterOrderedByScore(widget.clusterID!);
        for (final faceID in allFaces) {
          final fileID = getFileIdFromFaceId<int>(faceID);
          if (hiddenFileIDs.contains(fileID)) {
            _logger.info(
              "File with ID $fileID is hidden, skipping it for face crop.",
            );
            continue;
          }
          fileForFaceCrop = await FilesDB.instance.getAnyUploadedFile(fileID);
          if (fileForFaceCrop != null) {
            _logger.info(
              "Using file ID $fileID for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}",
            );
            fixedFaceID = faceID;
            break;
          }
        }
        if (fileForFaceCrop == null) {
          _logger.severe(
            "No suitable file found for face crop for person: ${widget.personId} or cluster: ${widget.clusterID}",
          );
          return null;
        }
      }
      final Face? face = await MLDataDB.instance.getCoverFaceForPerson(
        recentFileID: fileForFaceCrop.uploadedFileID!,
        avatarFaceId: fixedFaceID,
        personID: widget.personId,
        clusterID: widget.clusterID,
      );
      if (face == null) {
        _logger.severe(
          "No cover face for person: ${widget.personId} or cluster ${widget.clusterID} and fileID ${fileForFaceCrop.uploadedFileID!}",
        );
        await checkRemoveCachedFaceIDForPersonOrClusterId(
          personOrClusterId,
        );
        return null;
      }
      final cropMap = await getCachedFaceCrops(
        fileForFaceCrop,
        [face],
        useFullFile: useFullFile,
        personOrClusterID: personOrClusterId,
        useTempCache: false,
      );
      this.fileForFaceCrop = fileForFaceCrop;
      final result = cropMap?[face.faceID];
      if (result == null) {
        _logger.severe(
          "Null cover face crop for person: ${widget.personId} or cluster ${widget.clusterID} and fileID ${fileForFaceCrop.uploadedFileID!}",
        );
      }
      return result;
    } catch (e, s) {
      _logger.severe(
        "Error getting cover face for person: ${widget.personId} or cluster ${widget.clusterID}",
        e,
        s,
      );
      widget.onErrorCallback?.call();
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
