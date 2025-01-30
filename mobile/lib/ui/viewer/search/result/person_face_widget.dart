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
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/face/face_box_crop.dart";

final _logger = Logger("PersonFaceWidget");

class PersonFaceWidget extends StatefulWidget {
  final EnteFile file;
  final String? personId;
  final String? clusterID;
  final bool useFullFile;
  final bool thumbnailFallback;
  final bool cannotTrustFile;
  final Uint8List? faceCrop;

  // PersonFaceWidget constructor checks that both personId and clusterID are not null
  // and that the file is not null
  const PersonFaceWidget(
    this.file, {
    this.personId,
    this.clusterID,
    this.useFullFile = true,
    this.thumbnailFallback = false,
    this.cannotTrustFile = false,
    this.faceCrop,
    super.key,
  }) : assert(
          personId != null || clusterID != null,
          "PersonFaceWidget requires either personId or clusterID to be non-null",
        );

  @override
  State<PersonFaceWidget> createState() => _PersonFaceWidgetState();
}

class _PersonFaceWidgetState extends State<PersonFaceWidget> {
  Future<Uint8List?>? faceCropFuture;
  late final mlDataDB = MLDataDB.instance;

  @override
  void initState() {
    super.initState();
    faceCropFuture = widget.faceCrop != null
        ? Future.value(widget.faceCrop)
        : _getFaceCrop();
  }

  @override
  Widget build(BuildContext context) {
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
              "Error getting cover face for person: ${snapshot.error} ${snapshot.stackTrace}}",
            );
          }
          return widget.thumbnailFallback
              ? ThumbnailWidget(widget.file)
              : EnteLoadingWidget(
                  color: getEnteColorScheme(context).fillMuted,
                );
        }
      },
    );
  }

  Future<Uint8List?> _getFaceCrop() async {
    try {
      EnteFile? fileForFaceCrop = widget.file;
      String? personAvatarFaceID;
      Iterable<String>? allFaces;
      if (widget.personId != null) {
        final PersonEntity? personEntity =
            await PersonService.instance.getPerson(widget.personId!);
        if (personEntity != null) {
          personAvatarFaceID = personEntity.data.avatarFaceID;
          if (personAvatarFaceID != null) {
            final tryCache =
                await checkGetCachedCropForFaceID(personAvatarFaceID);
            if (tryCache != null) return tryCache;
          }
          if (personAvatarFaceID == null && widget.cannotTrustFile) {
            allFaces = await mlDataDB.getFaceIDsForPerson(widget.personId!);
          }
        }
      } else if (widget.clusterID != null && widget.cannotTrustFile) {
        allFaces = await mlDataDB.getFaceIDsForCluster(widget.clusterID!);
      }
      if (allFaces != null) {
        final allFileIDs =
            allFaces.map((e) => getFileIdFromFaceId<int>(e)).toSet();
        final hiddenFileIDs = await SearchService.instance
            .getHiddenFiles()
            .then((onValue) => onValue.map((e) => e.uploadedFileID));
        final acceptableFileIDs = allFileIDs.difference(hiddenFileIDs.toSet());
        final fileIDToCreationTime =
            await FilesDB.instance.getFileIDToCreationTime();
        // Get the file with the most recent creation time
        final recentFileID = acceptableFileIDs.reduce((a, b) {
          final aTime = fileIDToCreationTime[a];
          final bTime = fileIDToCreationTime[b];
          if (aTime == null) {
            return b;
          }
          if (bTime == null) {
            return a;
          }
          return (aTime >= bTime) ? a : b;
        });
        if (fileForFaceCrop.uploadedFileID != recentFileID) {
          fileForFaceCrop =
              await FilesDB.instance.getAnyUploadedFile(recentFileID);
          if (fileForFaceCrop == null) return null;
        }
      }

      final Face? face = await mlDataDB.getCoverFaceForPerson(
        recentFileID: fileForFaceCrop.uploadedFileID!,
        avatarFaceId: personAvatarFaceID,
        personID: widget.personId,
        clusterID: widget.clusterID,
      );
      if (face == null) {
        debugPrint(
          "No cover face for person: ${widget.personId} and cluster ${widget.clusterID} and recentFile ${widget.file.uploadedFileID}",
        );
        return null;
      }
      if (face.fileID != fileForFaceCrop.uploadedFileID!) {
        fileForFaceCrop =
            await FilesDB.instance.getAnyUploadedFile(face.fileID);
        if (fileForFaceCrop == null) return null;
      }
      final cropMap = await getCachedFaceCrops(
        fileForFaceCrop,
        [face],
        useFullFile: widget.useFullFile,
      );
      return cropMap?[face.faceID];
    } catch (e, s) {
      _logger.severe(
        "Error getting cover face for person: ${widget.personId} and cluster ${widget.clusterID}",
        e,
        s,
      );
      return null;
    }
  }
}
