import "dart:convert";

import "package:dio/dio.dart";
import "package:flutter_test/flutter_test.dart";
import "package:mockito/mockito.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/clip.dart";
import "package:photos/models/ml/face/face.dart";
import "package:package_info_plus/package_info_plus.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/ml_service.dart";
import "package:photos/utils/ml_util.dart";
import "package:shared_preferences/shared_preferences.dart";

class RecordingMLDataDB extends Mock implements MLDataDB {
  final List<List<Face>> insertedFaces = [];
  final List<List<ClipEmbedding>> insertedClips = [];

  @override
  Future<void> bulkInsertFaces(List<Face> faces) async {
    insertedFaces.add(faces);
  }

  @override
  Future<void> putClip(List<ClipEmbedding> embeddings) async {
    insertedClips.add(embeddings);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test("runAllML(force: true) skips when ML consent is disabled", () async {
    SharedPreferences.setMockInitialValues({
      "remote_flags": jsonEncode({
        "faceSearchEnabled": false,
        "internalUser": true,
      }),
    });
    final prefs = await SharedPreferences.getInstance();
    ServiceLocator.instance.init(
      prefs,
      Dio(),
      Dio(),
      PackageInfo(
        appName: "photos",
        packageName: "io.ente.photos",
        version: "1.0.0",
        buildNumber: "1",
      ),
    );

    expect(hasGrantedMLConsent, isFalse);

    await expectLater(MLService.instance.runAllML(force: true), completes);
    expect(MLService.instance.isRunningML, isFalse);
  });

  group("storeAcceptedIssuePlaceholders", () {
    late RecordingMLDataDB mlDataDB;

    setUp(() {
      mlDataDB = RecordingMLDataDB();
    });

    test("faces-only reindex stores empty face placeholder only", () async {
      final instruction = FileMLInstruction(
        file: _makeFile(1),
        mode: MLMode.offline,
        offlineFileKey: 101,
        shouldRunFaces: true,
        shouldRunClip: false,
      );

      await MLService.instance.storeAcceptedIssuePlaceholders(
        instruction: instruction,
        mlDataDB: mlDataDB,
      );

      expect(mlDataDB.insertedFaces, hasLength(1));
      expect(mlDataDB.insertedFaces.single, hasLength(1));
      expect(mlDataDB.insertedFaces.single.single.fileID, 101);
      expect(mlDataDB.insertedFaces.single.single.embedding, isEmpty);
      expect(mlDataDB.insertedFaces.single.single.score, -1.0);
      expect(mlDataDB.insertedClips, isEmpty);
    });

    test("clip-only offline reindex stores empty clip placeholder only",
        () async {
      final instruction = FileMLInstruction(
        file: _makeFile(2),
        mode: MLMode.offline,
        offlineFileKey: 202,
        shouldRunFaces: false,
        shouldRunClip: true,
      );

      await MLService.instance.storeAcceptedIssuePlaceholders(
        instruction: instruction,
        mlDataDB: mlDataDB,
      );

      expect(mlDataDB.insertedClips, hasLength(1));
      expect(mlDataDB.insertedClips.single, hasLength(1));
      expect(mlDataDB.insertedClips.single.single.fileID, 202);
      expect(mlDataDB.insertedClips.single.single.isEmpty, isTrue);
      expect(mlDataDB.insertedFaces, isEmpty);
    });

    test("clip-only online reindex does not write empty faces", () async {
      final file = _makeFile(3);
      int emptyClipStoreCalls = 0;

      final instruction = FileMLInstruction(
        file: file,
        mode: MLMode.online,
        shouldRunFaces: false,
        shouldRunClip: true,
      );

      await MLService.instance.storeAcceptedIssuePlaceholders(
        instruction: instruction,
        mlDataDB: mlDataDB,
        storeEmptyClipImageResult: (enteFile) async {
          expect(enteFile, same(file));
          emptyClipStoreCalls++;
        },
      );

      expect(emptyClipStoreCalls, 1);
      expect(mlDataDB.insertedFaces, isEmpty);
      expect(mlDataDB.insertedClips, isEmpty);
    });
  });
}

EnteFile _makeFile(int uploadedFileID) {
  return EnteFile()
    ..uploadedFileID = uploadedFileID
    ..title = "test.jpg"
    ..fileType = FileType.image;
}
