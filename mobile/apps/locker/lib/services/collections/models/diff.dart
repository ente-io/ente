import 'package:locker/services/files/sync/models/file.dart';

class Diff {
  final List<EnteFile> updatedFiles;
  final List<EnteFile> deletedFiles;
  final bool hasMore;
  final int latestUpdatedAtTime;

  Diff(
    this.updatedFiles,
    this.deletedFiles,
    this.hasMore,
    this.latestUpdatedAtTime,
  );
}
