import "dart:math" show max;
import "dart:typed_data" show Float32List;

import "package:flutter/foundation.dart" show kDebugMode;
import "package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart"
    show Uint64List;
import 'package:logging/logging.dart';
import "package:photos/db/ml/clip_vector_db.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/extensions/stop_watch.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/file/file_type.dart";
import "package:photos/models/ml/vector.dart";
import "package:photos/models/similar_files.dart";
import "package:photos/services/search_service.dart";

class SimilarImagesService {
  final _logger = Logger("SimilarImagesService");

  SimilarImagesService._privateConstructor();
  static final SimilarImagesService instance =
      SimilarImagesService._privateConstructor();

  /// Returns a list of SimilarFiles, where each SimilarFiles object contains
  /// a list of files that are perceptually similar
  Future<List<SimilarFiles>> getSimilarFiles(
    double distanceThreshold,
    {bool exact = false,}
  ) async {
    try {
      final now = DateTime.now();
      final List<SimilarFiles> result =
          await _getSimilarFiles(distanceThreshold, exact);
      final duration = DateTime.now().difference(now);
      _logger.info(
        "Found ${result.length} similar files in ${duration.inSeconds} seconds for threshold $distanceThreshold and exact $exact",
      );
      return result;
    } catch (e, s) {
      _logger.severe("failed to get similar files", e, s);
      rethrow;
    }
  }

  Future<List<SimilarFiles>> _getSimilarFiles(
    double distanceThreshold,
    bool exact,
  ) async {
    final w = (kDebugMode ? EnteWatch('getSimilarFiles') : null)?..start();
    final mlDataDB = MLDataDB.instance;
    _logger.info("Checking migration and filling clip vector DB");
    await mlDataDB.checkMigrateFillClipVectorDB();
    w?.log("checkMigrateFillClipVectorDB");

    // Get the embeddings ready for vector search
    final List<EmbeddingVector> allImageEmbeddings =
        await MLDataDB.instance.getAllClipVectors();
    final clipFloat32 = allImageEmbeddings
        .map(
          (value) => Float32List.fromList(value.vector.toList()),
        )
        .toList();
    final keys = Uint64List.fromList(
      allImageEmbeddings.map((e) => BigInt.from(e.fileID)).toList(),
    );
    w?.log("getAllClipVectors");

    // Run bulk vector search
    final (vectorKeys, distances) =
        await ClipVectorDB.instance.bulkSearchVectors(
      clipFloat32,
      BigInt.from(100),
      exact: exact,
    );
    w?.log("bulkSearchVectors");

    // Get all files, and create a map of fileID to file
    final allFiles = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      if (file.uploadedFileID != null && file.fileType != FileType.video) {
        allFileIdsToFile[file.uploadedFileID!] = file;
      }
    }
    w?.log("getAllFilesForSearch");

    // Run through the vector search results and create SimilarFiles objects
    final alreadyUsedFileIDs = <int>{};
    final allSimilarFiles = <SimilarFiles>[];
    for (int i = 0; i < keys.length; i++) {
      final fileID = keys[i].toInt();
      if (alreadyUsedFileIDs.contains(fileID)) continue;
      final firstLoopFile = allFileIdsToFile[fileID];
      if (firstLoopFile == null || firstLoopFile.uploadedFileID == null) {
        continue;
      }
      final otherFileIDs = vectorKeys[i];
      final distancesToFiles = distances[i];
      final similarFilesList = <EnteFile>[];
      double furthestDistance = 0.0;
      for (int j = 0; j < otherFileIDs.length; j++) {
        final otherFileID = otherFileIDs[j].toInt();
        if (otherFileID == fileID) continue;
        final distance = distancesToFiles[j];
        if (distance > distanceThreshold) {
          break;
        } else {
          furthestDistance = max(furthestDistance, distance);
        }
        if (alreadyUsedFileIDs.contains(otherFileID)) continue;
        final otherFile = allFileIdsToFile[otherFileID];
        if (otherFile != null && otherFile.uploadedFileID != null) {
          similarFilesList.add(otherFile);
        }
      }
      if (similarFilesList.isNotEmpty) {
        similarFilesList.add(firstLoopFile);
        for (final file in similarFilesList) {
          alreadyUsedFileIDs.add(file.uploadedFileID!);
        }
        final similarFiles = SimilarFiles(
          similarFilesList,
          furthestDistance,
        );
        allSimilarFiles.add(similarFiles);
      }
    }
    w?.log("going through files");

    // Sort the similar files by total size in descending order
    allSimilarFiles.sort((a, b) => b.totalSize.compareTo(a.totalSize));
    w?.log("sort similar files");

    return allSimilarFiles;
  }
}
