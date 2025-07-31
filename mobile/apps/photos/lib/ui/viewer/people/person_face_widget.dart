import "dart:typed_data";

import 'package:flutter/widgets.dart';
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

  bool get isPerson => widget.personId != null;

  @override
  bool get wantKeepAlive => widget.keepAlive;

  @override
  void initState() {
    super.initState();
    faceCropFuture = _getFaceCrop();
  }

  @override
  void dispose() {
    super.dispose();
    if (fileForFaceCrop != null) {
      checkStopTryingToGenerateFaceThumbnails(
        fileForFaceCrop!.uploadedFileID!,
        useFullFile: widget.useFullFile,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
      context,
    ); // Calling super.build for AutomaticKeepAliveClientMixin

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
              "Error getting cover face for person",
              snapshot.error,
              snapshot.stackTrace,
            );
          }
          return EnteLoadingWidget(
            color: getEnteColorScheme(context).fillMuted,
          );
        }
      },
    );
  }

  Future<Uint8List?> _getFaceCrop() async {
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
        useFullFile: widget.useFullFile,
        personOrClusterID: personOrClusterId,
        useTempCache: false,
      );
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
