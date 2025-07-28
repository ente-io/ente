import "dart:math" show max;
import "dart:typed_data" show Float32List;

import "package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart"
    show Uint64List;
import 'package:logging/logging.dart';
import "package:photos/db/ml/clip_vector_db.dart";
import "package:photos/db/ml/db.dart";
import 'package:photos/models/file/file.dart';
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
  Future<List<SimilarFiles>> getSimilarFiles(double distanceThreshold) async {
    try {
      final List<SimilarFiles> result =
          await _getSimilarFiles(distanceThreshold);
      return result;
    } catch (e, s) {
      _logger.severe("failed to get similar files", e, s);
      rethrow;
    }
  }

  Future<List<SimilarFiles>> _getSimilarFiles(double distanceThreshold) async {
    final mlDataDB = MLDataDB.instance;
    _logger.info("Checking migration and filling clip vector DB");
    await mlDataDB.checkMigrateFillClipVectorDB();

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

    // Run bulk vector search
    final (vectorKeys, distances) =
        await ClipVectorDB.instance.bulkSearchVectors(
      clipFloat32,
      BigInt.from(100),
    );

    // Get all files, and create a map of fileID to file
    final allFiles = Set<EnteFile>.from(
      await SearchService.instance.getAllFilesForSearch(),
    );
    final allFileIdsToFile = <int, EnteFile>{};
    for (final file in allFiles) {
      if (file.uploadedFileID != null) {
        allFileIdsToFile[file.uploadedFileID!] = file;
      }
    }

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
        final distance = distancesToFiles[j];
        if (distance > distanceThreshold) {
          break;
        } else {
          furthestDistance = max(furthestDistance, distance);
        }
        final otherFileID = otherFileIDs[j].toInt();
        if (alreadyUsedFileIDs.contains(otherFileID)) continue;
        final otherFile = allFileIdsToFile[otherFileID];
        if (otherFile != null && otherFile.uploadedFileID != null) {
          similarFilesList.add(otherFile);
        }
      }
      if (similarFilesList.isNotEmpty) {
        similarFilesList.add(firstLoopFile);
        int totalSize = 0;
        for (final file in similarFilesList) {
          alreadyUsedFileIDs.add(file.uploadedFileID!);
          totalSize += file.fileSize ?? 0;
        }
        final similarFiles = SimilarFiles(
          similarFilesList,
          totalSize,
          furthestDistance,
        );
        allSimilarFiles.add(similarFiles);
      }
    }

    // Sort the similar files by total size in descending order
    allSimilarFiles.sort((a, b) => b.totalSize.compareTo(a.totalSize));

    return allSimilarFiles;
  }
}
