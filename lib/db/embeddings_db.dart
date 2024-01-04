import "dart:io";

import "package:isar/isar.dart";
import 'package:path_provider/path_provider.dart';
import "package:photos/models/embedding.dart";

class EmbeddingsDB {
  late final Isar _isar;

  EmbeddingsDB._privateConstructor();

  static final EmbeddingsDB instance = EmbeddingsDB._privateConstructor();

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [EmbeddingSchema],
      directory: dir.path,
    );
    // TODO: _clearDeprecatedStore(dir);
  }

  Future<void> clearTable() async {
    await _isar.clear();
  }

  Stream<List<Embedding>> getStream(Model model) {
    return _isar.embeddings.filter().modelEqualTo(model).watch();
  }

  Future<List<Embedding>> getAll(Model model) async {
    return _isar.embeddings.filter().modelEqualTo(model).findAll();
  }

  Future<void> put(Embedding embedding) {
    return _isar.writeTxn(() async {
      await _isar.embeddings.put(embedding);
    });
  }

  Future<void> putMany(List<Embedding> embeddings) {
    return _isar.writeTxn(() async {
      await _isar.embeddings.putAll(embeddings);
    });
  }

  Future<List<Embedding>> getUnsyncedEmbeddings() async {
    return await _isar.embeddings.filter().updationTimeEqualTo(null).findAll();
  }

  Future<void> deleteAllForModel(Model model) async {
    await _isar.writeTxn(() async {
      final embeddings =
          await _isar.embeddings.filter().modelEqualTo(model).findAll();
      await _isar.embeddings.deleteAll(embeddings.map((e) => e.id).toList());
    });
  }

  Future<void> _clearDeprecatedStore(Directory dir) async {
    final deprecatedStore = Directory(dir.path + "/object-box-store");
    if (await deprecatedStore.exists()) {
      await deprecatedStore.delete(recursive: true);
    }
  }
}
