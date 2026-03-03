import "package:dio/dio.dart";
import "package:photos/models/duplicate_files.dart";

/// Gateway for files API endpoints.
///
/// Handles file metadata operations like size queries, file info retrieval,
/// and duplicate detection.
class FilesGateway {
  final Dio _enteDio;

  FilesGateway(this._enteDio);

  /// Gets the total size of files by their uploaded file IDs.
  ///
  /// [fileIDs] - List of uploaded file IDs to calculate total size for.
  ///
  /// Returns the total size in bytes.
  Future<int> getFilesSize(List<int> fileIDs) async {
    final response = await _enteDio.post(
      "/files/size",
      data: {"fileIDs": fileIDs},
    );
    return response.data["size"] as int;
  }

  /// Gets file info including sizes for the given file IDs.
  ///
  /// [fileIDs] - List of uploaded file IDs to get info for.
  ///
  /// Returns a map of uploadedFileID to file size in bytes.
  Future<Map<int, int>> getFilesInfo(List<int> fileIDs) async {
    final response = await _enteDio.post(
      "/files/info",
      data: {"fileIDs": fileIDs},
    );
    final Map<int, int> idToSize = {};
    final List<dynamic> result = response.data["filesInfo"] as List<dynamic>;
    for (final fileInfo in result) {
      final int uploadedFileID = fileInfo["id"] as int;
      final int size = fileInfo["fileInfo"]["fileSize"] as int;
      idToSize[uploadedFileID] = size;
    }
    return idToSize;
  }

  /// Gets duplicate files from the server.
  ///
  /// Returns a [DuplicateFilesResponse] containing groups of files with the
  /// same size (potential duplicates).
  Future<DuplicateFilesResponse> getDuplicates() async {
    final response = await _enteDio.get("/files/duplicates");
    return DuplicateFilesResponse.fromMap(
      response.data as Map<String, dynamic>,
    );
  }
}
