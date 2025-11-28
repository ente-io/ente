import "package:photos/models/api/file_share_url.dart";
import "package:photos/models/collection/collection.dart";

/// A wrapper that represents either a collection quick link or a single file share
sealed class QuickLinkItem {
  int get createdAt;
}

/// A collection-based quick link (album share)
class CollectionQuickLink extends QuickLinkItem {
  final Collection collection;

  CollectionQuickLink(this.collection);

  @override
  int get createdAt => collection.updationTime;
}

/// A single file share quick link
class FileQuickLink extends QuickLinkItem {
  final FileShareUrl fileShareUrl;

  FileQuickLink(this.fileShareUrl);

  @override
  int get createdAt => fileShareUrl.createdAt;
}
