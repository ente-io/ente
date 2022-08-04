import 'package:photos/models/collection_items.dart';
import 'package:photos/models/search/search_results.dart';

class AlbumSearchResult extends SearchResult {
  final CollectionWithThumbnail collectionWithThumbnail;

  AlbumSearchResult(this.collectionWithThumbnail);
}

// class AlbumSearchResults extends SearchResult {
//   final List<AlbumSearchResult> albumSearchResults;

//   AlbumSearchResults(this.albumSearchResults);
// }
