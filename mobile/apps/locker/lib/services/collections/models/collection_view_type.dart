import "package:flutter/material.dart";
import "package:locker/services/collections/models/collection.dart";

enum CollectionViewType {
  ownedCollection,
  sharedCollection,
  hiddenOwnedCollection,
  hiddenSection,
  quickLink,
  uncategorized,
  favorite
}


CollectionViewType getCollectionViewType(Collection c, int userID) {
  if (!c.isOwner(userID)) {
    return CollectionViewType.sharedCollection;
  }
  if (c.isDefaultHidden()) {
    return CollectionViewType.hiddenSection;
  } else if (c.type == CollectionType.uncategorized) {
    return CollectionViewType.uncategorized;
  } else if (c.type == CollectionType.favorites) {
    return CollectionViewType.favorite;
  } else if (c.isQuickLinkCollection()) {
    return CollectionViewType.quickLink;
  } else if (c.isHidden()) {
    return CollectionViewType.hiddenOwnedCollection;
  }
  debugPrint("Unknown collection type for collection ${c.id}, falling back to "
      "default");
  return CollectionViewType.ownedCollection;
}
