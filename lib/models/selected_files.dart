import 'package:flutter/foundation.dart';
import 'package:photos/models/file.dart';

class SelectedFiles extends ChangeNotifier {
  final files = Set<File>();

  void toggleSelection(File file) {
    if (files.contains(file)) {
      files.remove(file);
    } else {
      files.add(file);
    }
    notifyListeners();
  }

  void clearAll() {
    files.clear();
    notifyListeners();
  }
}
