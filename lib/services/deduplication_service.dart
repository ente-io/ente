import 'package:logging/logging.dart';
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';

class DeduplicationService {
  final _logger = Logger("DeduplicationService");
  final _enteDio = NetworkClient.instance.enteDio;

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

  List<DuplicateFiles> clubDuplicates(
    List<DuplicateFiles> dupesBySize, {
    required String? Function(File) clubbingKey,
  }) {
    final dupesBySizeAndClubKey = <DuplicateFiles>[];
    for (final sizeBasedDupe in dupesBySize) {
      final Map<String, List<File>> clubKeyToFilesMap = {};
      for (final file in sizeBasedDupe.files) {
        final String? clubKey = clubbingKey(file);
        if (clubKey == null || clubKey.isEmpty) {
          continue;
        }
        if (!clubKeyToFilesMap.containsKey(clubKey)) {
          clubKeyToFilesMap[clubKey] = <File>[];
        }
        clubKeyToFilesMap[clubKey]!.add(file);
      }
      for (final clubbingKey in clubKeyToFilesMap.keys) {
        final clubbedFiles = clubKeyToFilesMap[clubbingKey]!;
        if (clubbedFiles.length > 1) {
          dupesBySizeAndClubKey.add(
            DuplicateFiles(clubbedFiles, sizeBasedDupe.size),
          );
        }
      }
    }
    return dupesBySizeAndClubKey;
  }

  Future<DuplicateFilesResponse> _fetchDuplicateFileIDs() async {
    final response = await _enteDio.get("/files/duplicates");
    return DuplicateFilesResponse.fromMap(response.data);
  }
}
