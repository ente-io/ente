import "package:locker/services/collections/models/collection.dart";

extension CollectionDisplayExtension on Collection {
  /// Returns the display name for the collection.
  /// For favorites collections, always returns "Important" regardless of the stored name.
  /// For other collections, returns the stored name or null.
  String? get displayName {
    if (type == CollectionType.favorites) {
      return "Important";
    }
    return name;
  }
}
