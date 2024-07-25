import 'package:photos/services/machine_learning/file_ml/file_ml.dart';

class FilesMLDataResponse {
  final Map<int, RemoteFileML> mlData;
  // fileIDs that were indexed but they don't contain any meaningful embeddings
  // and hence should be discarded for re-indexing
  final Set<int> noEmbeddingFileIDs;
  // fetchErrorFileIDs are the fileIDs for whom we failed failed to fetch embeddings
  // from the storage
  final Set<int> fetchErrorFileIDs;
  // pendingIndexFileIDs are the fileIDs that were never indexed
  final Set<int> pendingIndexFileIDs;
  FilesMLDataResponse(
    this.mlData, {
    required this.noEmbeddingFileIDs,
    required this.fetchErrorFileIDs,
    required this.pendingIndexFileIDs,
  });

  String debugLog() {
    final nonZeroNoEmbeddingFileIDs = noEmbeddingFileIDs.isNotEmpty
        ? ', smallEmbeddings: ${noEmbeddingFileIDs.length}'
        : '';
    final nonZeroFetchErrorFileIDs = fetchErrorFileIDs.isNotEmpty
        ? ', errorForFileIDs: ${fetchErrorFileIDs.length}'
        : '';
    final nonZeroPendingIndexFileIDs = pendingIndexFileIDs.isNotEmpty
        ? ', pendingIndexFileIDs: ${pendingIndexFileIDs.length}'
        : '';
    return 'MLRemote(mlData: ${mlData.length}$nonZeroNoEmbeddingFileIDs$nonZeroFetchErrorFileIDs$nonZeroPendingIndexFileIDs)';
  }
}
