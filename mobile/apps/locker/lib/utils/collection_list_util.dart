import 'package:locker/services/collections/models/collection.dart';
import 'package:logging/logging.dart';

/// Returns a list of collections with duplicate IDs removed while preserving
/// order. Stops at the first uncategorized collection encountered.
List<Collection> uniqueCollectionsById(
  List<Collection> collections, {
  Logger? logger,
}) {
  final seenIds = <int>{};
  final unique = <Collection>[];

  bool uncategorizedSeen = false;

  for (final collection in collections) {
    final isUncategorizedCollection = _isUncategorized(collection);

    if (!seenIds.add(collection.id)) {
      logger?.fine(
        'Skipping duplicate collection with id ${collection.id} '
        '(${collection.name ?? "Unnamed"})',
      );
      continue;
    }

    if (isUncategorizedCollection) {
      if (uncategorizedSeen) {
        logger?.finer(
          'Skipping duplicate uncategorized collection with id ${collection.id}',
        );
        continue;
      }
      uncategorizedSeen = true;
    }

    unique.add(collection);
  }

  return unique;
}

bool _isUncategorized(Collection collection) {
  return collection.type == CollectionType.uncategorized;
}
