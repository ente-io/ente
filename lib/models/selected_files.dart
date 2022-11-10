import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:photos/models/file.dart';

class SelectedFiles extends ChangeNotifier {
  final files = <File>{};
  final lastSelections = <File>{};

  void toggleSelection(File file) {
    // To handle the cases, where the file might have changed due to upload
    // or any other update, using file.generatedID to track if this file was already
    // selected or not
    final File? alreadySelected = files.firstWhereOrNull(
      (element) => element.generatedID == file.generatedID,
    );
    if (alreadySelected != null) {
      files.remove(alreadySelected);
    } else {
      files.add(file);
    }
    lastSelections.clear();
    lastSelections.add(file);
    notifyListeners();
  }

  bool isFileSelected(File file) {
    final File? alreadySelected = files.firstWhereOrNull(
      (element) => element.generatedID == file.generatedID,
    );
    return alreadySelected != null;
  }

  bool isPartOfLastSelectedGrid(File file) {
    final File? alreadySelected = lastSelections.firstWhereOrNull(
      (element) => element.generatedID == file.generatedID,
    );
    return alreadySelected != null;
  }

  void clearAll() {
    lastSelections.addAll(files);
    files.clear();
    notifyListeners();
  }
}
