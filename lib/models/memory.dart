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
}
