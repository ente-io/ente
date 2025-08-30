import "package:locker/services/collections/models/collection.dart";

class SharedCollections {
  final List<Collection> outgoing;
  final List<Collection> incoming;
  final List<Collection> quickLinks;

  SharedCollections(this.outgoing, this.incoming, this.quickLinks);
}
