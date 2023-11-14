import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import "package:photos/models/embedding.dart";
import "package:photos/objectbox.g.dart"; // created by `flutter pub run build_runner build`

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  ObjectBox._privateConstructor();

  static final ObjectBox instance = ObjectBox._privateConstructor();

  Future<void> init() async {
    final docsDir = await getApplicationDocumentsDirectory();
    // Future<Store> openStore() {...} is defined in the generated objectbox.g.dart
    store = await openStore(directory: p.join(docsDir.path, "object-box-store"));
  }

  Future<void> clearTable() async {
    getEmbeddingBox().removeAll();
  }

  Box<Embedding> getEmbeddingBox() {
    return store.box<Embedding>();
  }
}
