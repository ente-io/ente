import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file.dart';
import "package:photos/services/collections_service.dart";
import "package:photos/services/files_service.dart";

class DeduplicationService {
  final _logger = Logger("DeduplicationService");
  final _enteDio = NetworkClient.instance.enteDio;

  DeduplicationService._privateConstructor();

  static final DeduplicationService instance =
      DeduplicationService._privateConstructor();

  Future<List<DuplicateFiles>> getDuplicateFiles() async {
    try {
      final bool hasFileSizes = await FilesService.instance.hasMigratedSizes();
      if (hasFileSizes) {
        final List<DuplicateFiles> result = await _getDuplicateFilesFromLocal();
        return result;
      }
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
    } catch (e, s) {
      _logger.severe("failed to get dedupeFile", e, s);
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

  Future<List<DuplicateFiles>> _getDuplicateFilesFromLocal() async {
    final List<File> allFiles = await FilesDB.instance.getAllFilesFromDB(
      CollectionsService.instance.getHiddenCollectionIds(),
    );
    final int ownerID = Configuration.instance.getUserID()!;
    allFiles.removeWhere(
      (f) =>
          !f.isUploaded ||
          (f.ownerID ?? 0) != ownerID ||
          (f.fileSize ?? 0) <= 0,
    );
    final Map<int, List<File>> sizeToFilesMap = {};
    for (final file in allFiles) {
      if (!sizeToFilesMap.containsKey(file.fileSize)) {
        sizeToFilesMap[file.fileSize!] = <File>[];
      }
      sizeToFilesMap[file.fileSize]!.add(file);
    }
    final List<DuplicateFiles> dupesBySize = [];
    for (final size in sizeToFilesMap.keys) {
      final List<File> files = sizeToFilesMap[size]!;
      if (files.length > 1) {
        dupesBySize.add(DuplicateFiles(files, size));
      }
    }
    return dupesBySize;
  }

  Future<DuplicateFilesResponse> _fetchDuplicateFileIDs() async {
    final response = await _enteDio.get("/files/duplicates");
    return DuplicateFilesResponse.fromMap(response.data);
  }
}
