enum GalleryType {
  homepage,
  archive,
  uncategorized,
  hidden,
  favorite,
  trash,
  localFolder,
  // indicator for gallery view of collections shared with the user
  sharedCollection,
  ownedCollection,
  searchResults,
  locationTag,
  quickLink,
}

extension GalleyTypeExtension on GalleryType {
  bool showAddToAlbum() {
    switch (this) {
      case GalleryType.homepage:
      case GalleryType.archive:
      case GalleryType.localFolder:
      case GalleryType.ownedCollection:
      case GalleryType.searchResults:
      case GalleryType.favorite:
      case GalleryType.locationTag:
      case GalleryType.quickLink:
        return true;

      case GalleryType.hidden:
      case GalleryType.uncategorized:
      case GalleryType.trash:
      case GalleryType.sharedCollection:
        return false;
    }
  }

  bool showMoveToAlbum() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.uncategorized:
      case GalleryType.quickLink:
        return true;

      case GalleryType.hidden:
      case GalleryType.favorite:
      case GalleryType.searchResults:
      case GalleryType.archive:
      case GalleryType.localFolder:
      case GalleryType.homepage:
      case GalleryType.trash:
      case GalleryType.sharedCollection:
      case GalleryType.locationTag:
        return false;
    }
  }

  // showDeleteTopOption indicates whether we should show
  // delete icon as iconButton
  bool showDeleteIconOption() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.searchResults:
      case GalleryType.homepage:
      case GalleryType.favorite:
      case GalleryType.localFolder:
      case GalleryType.uncategorized:
      case GalleryType.locationTag:
      case GalleryType.quickLink:
        return true;
      case GalleryType.trash:
      case GalleryType.archive:
      case GalleryType.hidden:
      case GalleryType.sharedCollection:
        return false;
    }
  }

  bool showDeleteOption() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.searchResults:
      case GalleryType.homepage:
      case GalleryType.favorite:
      case GalleryType.uncategorized:
      case GalleryType.archive:
      case GalleryType.hidden:
      case GalleryType.localFolder:
      case GalleryType.locationTag:
      case GalleryType.quickLink:
        return true;
      case GalleryType.trash:
      case GalleryType.sharedCollection:
        return false;
    }
  }

  bool showCreateLink() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.searchResults:
      case GalleryType.homepage:
      case GalleryType.favorite:
      case GalleryType.archive:
      case GalleryType.uncategorized:
      case GalleryType.locationTag:
        return true;
      case GalleryType.hidden:
      case GalleryType.localFolder:
      case GalleryType.trash:
      case GalleryType.sharedCollection:
      case GalleryType.quickLink:
        return false;
    }
  }

  bool showRemoveFromAlbum() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.sharedCollection:
      case GalleryType.quickLink:
        return true;
      case GalleryType.hidden:
      case GalleryType.uncategorized:
      case GalleryType.favorite:
      case GalleryType.searchResults:
      case GalleryType.homepage:
      case GalleryType.archive:
      case GalleryType.localFolder:
      case GalleryType.trash:
      case GalleryType.locationTag:
        return false;
    }
  }

  bool showArchiveOption() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.homepage:
      case GalleryType.uncategorized:
      case GalleryType.quickLink:
        return true;

      case GalleryType.hidden:

      case GalleryType.favorite:
      case GalleryType.searchResults:
      case GalleryType.archive:
      case GalleryType.localFolder:
      case GalleryType.trash:
      case GalleryType.sharedCollection:
      case GalleryType.locationTag:
        return false;
    }
  }

  bool showUnArchiveOption() {
    return this == GalleryType.archive;
  }

  bool showHideOption() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.homepage:
      case GalleryType.searchResults:
      case GalleryType.archive:
      case GalleryType.uncategorized:
      case GalleryType.locationTag:
      case GalleryType.quickLink:
        return true;

      case GalleryType.hidden:

      case GalleryType.localFolder:
      case GalleryType.trash:
      case GalleryType.favorite:
      case GalleryType.sharedCollection:
        return false;
    }
  }

  bool showUnHideOption() {
    return this == GalleryType.hidden;
  }

  bool showFavoriteOption() {
    switch (this) {
      case GalleryType.ownedCollection:
      case GalleryType.homepage:
      case GalleryType.searchResults:
      case GalleryType.uncategorized:
      case GalleryType.locationTag:
        return true;

      case GalleryType.hidden:
      case GalleryType.quickLink:
      case GalleryType.favorite:
      case GalleryType.archive:
      case GalleryType.localFolder:
      case GalleryType.trash:
      case GalleryType.sharedCollection:
        return false;
    }
  }

  bool showUnFavoriteOption() {
    return this == GalleryType.favorite;
  }

  bool showRestoreOption() {
    return this == GalleryType.trash;
  }

  bool showPermanentlyDeleteOption() {
    return this == GalleryType.trash;
  }
}
