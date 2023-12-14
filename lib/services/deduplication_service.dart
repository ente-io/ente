import 'package:logging/logging.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/core/errors.dart';
import 'package:photos/core/network/network.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/models/duplicate_files.dart';
import 'package:photos/models/file/file.dart';
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
      for (final dupe in dupes.sameSizeFiles) {
        ids.addAll(dupe.fileIDs);
      }
      final fileMap = await FilesDB.instance.getFilesFromIDs(ids);
      final result = <DuplicateFiles>[];
      final missingFileIDs = <int>[];
      for (final dupe in dupes.sameSizeFiles) {
        final Map<String, List<EnteFile>> sizeHashToFilesMap = {};
        final fileSize = dupe.size;
        final filesWithHash = <EnteFile>[];
        for (final id in dupe.fileIDs) {
          final file = fileMap[id];
          if (file != null && file.hash != null && file.hash!.isNotEmpty) {
            filesWithHash.add(file);
          } else if (file == null) {
            missingFileIDs.add(id);
          } else {
            _logger.info("File with ID $id has no hash");
          }
        }
        // Group by size and hash
        for (final file in filesWithHash) {
          final key = '$fileSize-${file.hash}';
          _logger.info('FileUploadID ${file.uploadedFileID} has hash ${key}');
          if (!sizeHashToFilesMap.containsKey(key)) {
            sizeHashToFilesMap[key] = <EnteFile>[];
          }
          sizeHashToFilesMap[key]!.add(file);
        }
        for (final key in sizeHashToFilesMap.keys) {
          final files = sizeHashToFilesMap[key]!;
          if (files.length > 1) {
            // todo: add logic to put candidate to keep first
            result.add(DuplicateFiles(files, fileSize));
          }
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

  // Returns a list of DuplicateFiles, where each DuplicateFiles object contains
  // a list of files that have the same size and hash
  Future<List<DuplicateFiles>> _getDuplicateFilesFromLocal() async {
    final List<EnteFile> allFiles = await FilesDB.instance.getAllFilesFromDB(
      CollectionsService.instance.getHiddenCollectionIds(),
    );
    final int ownerID = Configuration.instance.getUserID()!;
    allFiles.removeWhere(
      (f) =>
          !f.isUploaded ||
          (f.hash ?? '').isEmpty ||
          (f.ownerID ?? 0) != ownerID ||
          (f.fileSize ?? 0) <= 0,
    );
    final Map<String, List<EnteFile>> sizeHashToFilesMap = {};
    for (final file in allFiles) {
      final key = '${file.fileSize}-${file.hash}';
      if (!sizeHashToFilesMap.containsKey(key)) {
        sizeHashToFilesMap[key] = <EnteFile>[];
      }
      sizeHashToFilesMap[key]!.add(file);
    }
    final List<DuplicateFiles> dupesBySizeHash = [];
    for (final key in sizeHashToFilesMap.keys) {
      final List<EnteFile> files = sizeHashToFilesMap[key]!;
      if (files.length > 1) {
        final size = files[0].fileSize!;
        dupesBySizeHash.add(DuplicateFiles(files, size));
      }
    }
    return dupesBySizeHash;
  }

  Future<DuplicateFilesResponse> _fetchDuplicateFileIDs() async {
    final response = await _enteDio.get("/files/duplicates");
    return DuplicateFilesResponse.fromMap(response.data);
  }
}
