import 'package:flutter/foundation.dart';
import 'package:photos/models/file.dart';

class SelectedFiles extends ChangeNotifier {
  final files = <File>{};
  final lastSelections = <File>{};

  void toggleSelection(File file) {
    if (files.contains(file)) {
      files.remove(file);
    } else {
      files.add(file);
    }
    lastSelections.clear();
    lastSelections.add(file);
    notifyListeners();
  }

  void clearAll() {
    lastSelections.addAll(files);
    files.clear();
    notifyListeners();
  }
}
