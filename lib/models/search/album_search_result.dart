import 'package:photos/models/collection_items.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/search/search_result.dart';

class AlbumSearchResult extends SearchResult {
  final CollectionWithThumbnail collectionWithThumbnail;

  AlbumSearchResult(this.collectionWithThumbnail);

  @override
  ResultType type() {
    return ResultType.collection;
  }

  @override
  String name() {
    return collectionWithThumbnail.collection.name!;
  }

  @override
  File? previewThumbnail() {
    return collectionWithThumbnail.thumbnail;
  }

  @override
  List<File> resultFiles() {
    // for album search result, we should open the album page directly
    throw UnimplementedError();
  }
}
