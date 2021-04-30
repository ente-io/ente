import 'package:flutter/foundation.dart';
import 'package:photos/models/file.dart';

class SelectedFiles extends ChangeNotifier {
  final files = Set<File>();
  File latestSelection;

  void toggleSelection(File file) {
    if (files.contains(file)) {
      files.remove(file);
    } else {
      files.add(file);
    }
    latestSelection = file;
    notifyListeners();
  }

  void clearAll() {
    files.clear();
    latestSelection = null;
    notifyListeners();
  }
}
