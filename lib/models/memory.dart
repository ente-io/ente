import 'package:photos/models/file.dart';

class Memory {
  final File file;
  bool _isSeen;

  Memory(this.file, this._isSeen);

  bool isSeen() {
    return _isSeen;
  }

  bool markSeen() {
    _isSeen = true;
  }
}
