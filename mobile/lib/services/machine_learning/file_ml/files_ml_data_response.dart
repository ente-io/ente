import 'package:photos/services/machine_learning/file_ml/file_ml.dart';

class FilesMLDataResponse {
  final Map<int, FileMl> mlData;
  final Set<int> notIndexedFileIds;
  final Set<int> fetchErrorFileIds;
  FilesMLDataResponse(
    this.mlData, {
    required this.notIndexedFileIds,
    required this.fetchErrorFileIds,
  });
}
