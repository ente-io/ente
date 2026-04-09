import "dart:async";
import "dart:convert";
import "dart:typed_data";

import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/db/files_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/db/offline_files_db.dart";
import "package:photos/events/pets_changed_event.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/box.dart";
import "package:photos/models/ml/face/detection.dart";
import "package:photos/models/ml/face/face.dart";
import "package:photos/service_locator.dart" show isOfflineMode;
import "package:photos/services/machine_learning/pet_ml/pet_clustering_service.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final _logger = Logger("PetFaceWidget");

class PetFaceWidget extends StatefulWidget {
  final String petClusterId;

  const PetFaceWidget({required this.petClusterId, super.key});

  @override
  State<PetFaceWidget> createState() => _PetFaceWidgetState();
}

class _PetFaceWidgetState extends State<PetFaceWidget> {
  Future<Uint8List?>? _faceCropFuture;
  late final StreamSubscription<PetsChangedEvent> _petsChangedSub;

  @override
  void initState() {
    super.initState();
    _faceCropFuture = _loadFaceCrop();
    _petsChangedSub =
        Bus.instance.on<PetsChangedEvent>().listen((_) => _reload());
  }

  @override
  void dispose() {
    _petsChangedSub.cancel();
    super.dispose();
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _faceCropFuture = _loadFaceCrop();
      });
    }
  }

  Future<Uint8List?> _loadFaceCrop() async {
    try {
      final mlDataDB =
          isOfflineMode ? MLDataDB.offlineInstance : MLDataDB.instance;
      final dbPetFace =
          await mlDataDB.getCoverPetFaceForCluster(widget.petClusterId);
      if (dbPetFace == null) return null;

      EnteFile? enteFile;
      if (isOfflineMode) {
        final localId =
            await OfflineFilesDB.instance.getLocalIdForIntId(dbPetFace.fileId);
        if (localId != null) {
          final files = await FilesDB.instance.getLocalFiles([localId]);
          enteFile = files.firstOrNull;
        }
      } else {
        enteFile = await FilesDB.instance.getAnyUploadedFile(dbPetFace.fileId);
      }
      if (enteFile == null) return null;

      final json = jsonDecode(dbPetFace.detection) as Map<String, dynamic>;
      final boxList =
          (json['box'] as List).map((e) => (e as num).toDouble()).toList();
      final detection = Detection(
        box: FaceBox(
          x: boxList[0],
          y: boxList[1],
          width: boxList[2] - boxList[0],
          height: boxList[3] - boxList[1],
        ),
        landmarks: const [],
      );
      final face = Face(
        dbPetFace.petFaceId,
        dbPetFace.fileId,
        const <double>[],
        dbPetFace.faceScore,
        detection,
        0.0,
      );

      final crops = await getCachedFaceCrops(
        enteFile,
        [face],
        useTempCache: true,
      );
      return crops?[face.faceID];
    } catch (e, s) {
      _logger.warning("Failed to load pet face crop", e, s);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _faceCropFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
          );
        }
        return const Center(child: Icon(Icons.pets, size: 32));
      },
    );
  }
}
