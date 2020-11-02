import 'package:photos/models/collection.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/file.dart';

class CollectionItems {
  final List<DeviceFolder> folders;
  final List<CollectionWithThumbnail> collections;

  CollectionItems(this.folders, this.collections);
}

class CollectionWithThumbnail {
  final Collection collection;
  final File thumbnail;
  final File lastUpdatedFile;

  CollectionWithThumbnail(
    this.collection,
    this.thumbnail,
    this.lastUpdatedFile,
  );
}

class SharedCollections {
  final List<CollectionWithThumbnail> outgoing;
  final List<CollectionWithThumbnail> incoming;

  SharedCollections(this.outgoing, this.incoming);
}
