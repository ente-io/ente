import 'package:photos/models/collection.dart';
import 'package:photos/models/file.dart';

class CollectionWithThumbnail {
  final Collection collection;
  final File? thumbnail;

  CollectionWithThumbnail(
    this.collection,
    this.thumbnail,
  );
}

class SharedCollections {
  final List<Collection> outgoing;
  final List<Collection> incoming;
  final List<Collection> quickLinks;

  SharedCollections(this.outgoing, this.incoming, this.quickLinks);
}
