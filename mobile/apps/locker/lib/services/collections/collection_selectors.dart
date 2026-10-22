import 'package:locker/services/collections/models/collection.dart';

Collection? findOwnedCollection(
  Iterable<Collection> collections, {
  required int ownerID,
  required CollectionType type,
  String? name,
}) {
  for (final collection in collections) {
    if (!collection.isDeleted &&
        collection.isOwner(ownerID) &&
        collection.type == type &&
        (name == null || collection.name == name)) {
      return collection;
    }
  }
  return null;
}
