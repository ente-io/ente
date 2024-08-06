import 'package:photos/services/machine_learning/file_ml/file_ml.dart';

class FilesMLDataResponse {
  final Map<int, RemoteFileDerivedData> mlData;
  // fetchErrorFileIDs are the fileIDs for whom we failed failed to fetch embeddings
  // from the storage
  final Set<int> fetchErrorFileIDs;
  // pendingIndexFileIDs are the fileIDs that were never indexed
  final Set<int> pendingIndexFileIDs;
  FilesMLDataResponse(
    this.mlData, {
    required this.fetchErrorFileIDs,
    required this.pendingIndexFileIDs,
  });

  FilesMLDataResponse.empty({
    this.mlData = const {},
    this.fetchErrorFileIDs = const {},
    this.pendingIndexFileIDs = const {},
  });

  String debugLog() {
    final nonZeroFetchErrorFileIDs = fetchErrorFileIDs.isNotEmpty
        ? ', errorForFileIDs: ${fetchErrorFileIDs.length}'
        : '';
    final nonZeroPendingIndexFileIDs = pendingIndexFileIDs.isNotEmpty
        ? ', pendingIndexFileIDs: ${pendingIndexFileIDs.length}'
        : '';
    return 'MLRemote(mlData: ${mlData.length}$nonZeroFetchErrorFileIDs$nonZeroPendingIndexFileIDs)';
  }
}
