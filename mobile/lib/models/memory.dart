import 'package:photos/models/file/file.dart';

class Memory {
  final EnteFile file;
  int _seenTime;

  Memory(this.file, this._seenTime);

  bool isSeen() {
    return _seenTime != -1;
  }

  int seenTime() {
    return _seenTime;
  }

  void markSeen() {
    _seenTime = DateTime.now().microsecondsSinceEpoch;
  }

  Memory.fromUnseenFile(this.file) : _seenTime = -1;

  static List<Memory> fromFiles(List<EnteFile> files) {
    final memories = <Memory>[];
    for (final file in files) {
      memories.add(Memory.fromUnseenFile(file));
    }
    return memories;
  }

  static List<EnteFile> filesFromMemories(List<Memory> memories) {
    final List<EnteFile> files = [];
    for (final memory in memories) {
      files.add(memory.file);
    }
    return files;
  }
}
