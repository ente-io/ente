import 'package:photos/models/file/file.dart';
import "package:photos/services/filter/collection_ignore.dart";
import "package:photos/services/filter/dedupe_by_upload_id.dart";
import "package:photos/services/filter/filter.dart";
import "package:photos/services/filter/upload_ignore.dart";
import "package:photos/services/ignored_files_service.dart";

class DBFilterOptions {
  // typically used for filtering out all files which are present in hidden
  // (searchable files result) or archived collections or both (ex: home
  // timeline)
  Set<int>? ignoredCollectionIDs;
  bool dedupeUploadID;
  bool hideIgnoredForUpload;

  DBFilterOptions({
    this.ignoredCollectionIDs,
    this.hideIgnoredForUpload = false,
    this.dedupeUploadID = true,
  });

  static DBFilterOptions dedupeOption = DBFilterOptions(
    dedupeUploadID: true,
  );
}

Future<List<EnteFile>> applyDBFilters(
  List<EnteFile> files,
  DBFilterOptions? options,
) async {
  if (options == null) {
    return files;
  }
  final List<Filter> filters = [];
  if (options.hideIgnoredForUpload) {
    final Map<String, String> idToReasonMap =
        await IgnoredFilesService.instance.idToIgnoreReasonMap;
    if (idToReasonMap.isNotEmpty) {
      filters.add(UploadIgnoreFilter(idToReasonMap));
    }
  }
  if (options.dedupeUploadID) {
    filters.add(DedupeUploadIDFilter());
  }
  if (options.ignoredCollectionIDs != null &&
      options.ignoredCollectionIDs!.isNotEmpty) {
    final collectionIgnoreFilter =
        CollectionsIgnoreFilter(options.ignoredCollectionIDs!, files);
    filters.add(collectionIgnoreFilter);
  }
  final List<EnteFile> filterFiles = [];
  for (final file in files) {
    if (filters.every((f) => f.filter(file))) {
      filterFiles.add(file);
    }
  }
  return filterFiles;
}
