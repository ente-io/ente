import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file.dart';

class CollectionItems {
  final List<DeviceCollection> deviceCollections;
  final List<CollectionWithThumbnail> collections;

  CollectionItems(this.deviceCollections, this.collections);
}

class CollectionWithThumbnail {
  final Collection collection;
  final File thumbnail;

  CollectionWithThumbnail(
    this.collection,
    this.thumbnail,
  );
}

class SharedCollections {
  final List<CollectionWithThumbnail> outgoing;
  final List<CollectionWithThumbnail> incoming;

  SharedCollections(this.outgoing, this.incoming);
}
