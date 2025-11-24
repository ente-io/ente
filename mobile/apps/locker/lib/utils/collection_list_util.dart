import 'package:locker/services/collections/models/collection.dart';

/// Returns a list of collections with duplicate IDs removed while preserving
/// order. Stops at the first uncategorized collection encountered.
List<Collection> uniqueCollectionsById(List<Collection> collections) {
  final seenIds = <int>{};
  final unique = <Collection>[];

  bool uncategorizedSeen = false;

  for (final collection in collections) {
    final isUncategorizedCollection = _isUncategorized(collection);

    if (seenIds.add(collection.id)) {
      if (isUncategorizedCollection) {
        if (uncategorizedSeen) {
          continue;
        }
        uncategorizedSeen = true;
      }
      unique.add(collection);
    }
  }

  return unique;
}

bool _isUncategorized(Collection collection) {
  return collection.type == CollectionType.uncategorized;
}
