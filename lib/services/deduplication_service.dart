import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';

class DeduplicationService {
  final _logger = Logger("DeduplicationService");
  final _dio = Network.instance.getDio();

  DeduplicationService._privateConstructor();

  static final DeduplicationService instance =
      DeduplicationService._privateConstructor();

  Future<List<DuplicateFiles>> getDuplicateFiles() async {
    try {
      DuplicateFilesResponse dupes = await _fetchDuplicateFileIDs();
      final ids = <int>[];
      for (final dupe in dupes.duplicates) {
        ids.addAll(dupe.fileIDs);
      }
      final fileMap = await FilesDB.instance.getFilesFromIDs(ids);
      return _computeDuplicates(dupes, fileMap);
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  List<DuplicateFiles> _computeDuplicates(
      DuplicateFilesResponse dupes, Map<int, File> fileMap) {
    final result = <DuplicateFiles>[];
    for (final dupe in dupes.duplicates) {
      final files = <File>[];
      final Map<int, int> creationTimeCounter = {};
      int mostFrequentCreationTime = 0, mostFrequentCreationTimeCount = 0;
      for (final id in dupe.fileIDs) {
        final file = fileMap[id];
        if (file != null) {
          if (creationTimeCounter.containsKey(file.creationTime)) {
            creationTimeCounter[file.creationTime]++;
          } else {
            creationTimeCounter[file.creationTime] = 0;
          }
          if (creationTimeCounter[file.creationTime] >
              mostFrequentCreationTimeCount) {
            mostFrequentCreationTimeCount =
                creationTimeCounter[file.creationTime];
            mostFrequentCreationTime = file.creationTime;
          }
          files.add(file);
        } else {
          _logger.severe(
              "Missing file",
              InvalidStateError(
                  "Could not find file in local DB " + id.toString()));
        }
      }
      final incorrectDuplicates = <File>{};
      for (final file in files) {
        if (file.creationTime != mostFrequentCreationTime) {
          incorrectDuplicates.add(file);
        }
      }
      files.removeWhere((file) => incorrectDuplicates.contains(file));
      if (files.length > 1) {
        result.add(DuplicateFiles(files, dupe.size));
      }
    }
    return result;
  }

  Future<DuplicateFilesResponse> _fetchDuplicateFileIDs() async {
    final response = await _dio.get(
      Configuration.instance.getHttpEndpoint() + "/files/duplicates",
      options: Options(
        headers: {
          "X-Auth-Token": Configuration.instance.getToken(),
        },
      ),
    );
    return DuplicateFilesResponse.fromMap(response.data);
  }
}
