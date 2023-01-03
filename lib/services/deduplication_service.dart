import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';

class DeduplicationService {
  final _logger = Logger("DeduplicationService");
  final _enteDio = Network.instance.enteDio;

  DeduplicationService._privateConstructor();

  static final DeduplicationService instance =
      DeduplicationService._privateConstructor();

  Future<List<DuplicateFiles>> getDuplicateFiles() async {
    try {
      final DuplicateFilesResponse dupes = await _fetchDuplicateFileIDs();
      final ids = <int>[];
      for (final dupe in dupes.duplicates) {
        ids.addAll(dupe.fileIDs);
      }
      final fileMap = await FilesDB.instance.getFilesFromIDs(ids);
      final result = <DuplicateFiles>[];
      final missingFileIDs = <int>[];
      for (final dupe in dupes.duplicates) {
        final files = <File>[];
        for (final id in dupe.fileIDs) {
          final file = fileMap[id];
          if (file != null) {
            files.add(file);
          } else {
            missingFileIDs.add(id);
          }
        }
        // Place files that are available locally at first to minimize the chances
        // of a deletion followed by a re-upload
        files.sort((first, second) {
          if (first.localID != null && second.localID == null) {
            return -1;
          } else if (first.localID == null && second.localID != null) {
            return 1;
          }
          return 0;
        });
        if (files.length > 1) {
          result.add(DuplicateFiles(files, dupe.size));
        }
      }
      if (missingFileIDs.isNotEmpty) {
        _logger.severe(
          "Missing files",
          InvalidStateError(
            "Could not find " +
                missingFileIDs.length.toString() +
                " files in local DB: " +
                missingFileIDs.toString(),
          ),
        );
      }
      return result;
    } catch (e) {
      _logger.severe(e);
      rethrow;
    }
  }

  List<DuplicateFiles> clubDuplicatesByTime(List<DuplicateFiles> dupes) {
    final result = <DuplicateFiles>[];
    for (final dupe in dupes) {
      final files = <File>[];
      final Map<int, int> creationTimeCounter = {};
      int mostFrequentCreationTime = 0, mostFrequentCreationTimeCount = 0;
      // Counts the frequency of creationTimes within the supposed duplicates
      for (final file in dupe.files) {
        if (creationTimeCounter.containsKey(file.creationTime!)) {
          creationTimeCounter[file.creationTime!] =
              creationTimeCounter[file.creationTime!]! + 1;
        } else {
          creationTimeCounter[file.creationTime!] = 0;
        }
        if (creationTimeCounter[file.creationTime]! >
            mostFrequentCreationTimeCount) {
          mostFrequentCreationTimeCount =
              creationTimeCounter[file.creationTime]!;
          mostFrequentCreationTime = file.creationTime!;
        }
        files.add(file);
      }
      // Ignores those files that were not created within the most common creationTime
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
    final response = await _enteDio.get("/files/duplicates");
    return DuplicateFilesResponse.fromMap(response.data);
  }
}
