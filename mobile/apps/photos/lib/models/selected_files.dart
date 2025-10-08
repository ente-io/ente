import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/clear_selections_event.dart';
import 'package:photos/models/file/dummy_file.dart';
import 'package:photos/models/file/file.dart';

class SelectedFiles extends ChangeNotifier {
  final files = <EnteFile>{};

  ///This variable is used to track the files that were involved in last selection
  ///operation (select/unselect). Each [LazyGridView] checks this variable on
  ///change in [SelectedFiles] to see if any of it's files were involved in last
  ///select/unselect operation. If yes, then it will rebuild itself.
  final lastSelectionOperationFiles = <EnteFile>{};

  void toggleSelection(EnteFile fileToToggle) {
    // Skip dummy files - they should never be selected
    if (fileToToggle is DummyFile) {
      return;
    }
    // To handle the cases, where the file might have changed due to upload
    // or any other update, using file.generatedID to track if this file was already
    // selected or not
    final EnteFile? alreadySelected = files.firstWhereOrNull(
      (element) => _isMatch(fileToToggle, element),
    );
    if (alreadySelected != null) {
      files.remove(alreadySelected);
    } else {
      files.add(fileToToggle);
    }
    lastSelectionOperationFiles.clear();
    lastSelectionOperationFiles.add(fileToToggle);
    notifyListeners();
  }

  void toggleGroupSelection(Set<EnteFile> filesToToggle) {
    // Filter out dummy files before processing
    final nonDummyFiles =
        filesToToggle.where((file) => file is! DummyFile).toSet();
    if (nonDummyFiles.isEmpty) {
      return;
    }
    if (files.containsAll(nonDummyFiles)) {
      unSelectAll(nonDummyFiles);
    } else {
      selectAll(nonDummyFiles);
    }
  }

  void selectAll(Set<EnteFile> filesToSelect) {
    // Filter out dummy files before adding to selection
    final nonDummyFiles =
        filesToSelect.where((file) => file is! DummyFile).toSet();
    files.addAll(nonDummyFiles);
    lastSelectionOperationFiles.clear();
    lastSelectionOperationFiles.addAll(nonDummyFiles);
    notifyListeners();
  }

  void unSelectAll(Set<EnteFile> filesToUnselect, {bool skipNotify = false}) {
    files.removeWhere((file) => filesToUnselect.contains(file));
    lastSelectionOperationFiles.clear();
    // Filter out dummy files before adding to lastSelectionOperationFiles
    lastSelectionOperationFiles
        .addAll(filesToUnselect.where((file) => file is! DummyFile));
    if (!skipNotify) {
      notifyListeners();
    }
  }

  bool isFileSelected(EnteFile file) {
    final EnteFile? alreadySelected = files.firstWhereOrNull(
      (element) => _isMatch(file, element),
    );
    return alreadySelected != null;
  }

  bool isPartOfLastSelected(EnteFile file) {
    final EnteFile? matchedFile = lastSelectionOperationFiles.firstWhereOrNull(
      (element) => _isMatch(file, element),
    );
    return matchedFile != null;
  }

  bool _isMatch(EnteFile first, EnteFile second) {
    if (first.generatedID != null && second.generatedID != null) {
      if (first.generatedID == second.generatedID) {
        return true;
      }
    } else if (first.uploadedFileID != null && second.uploadedFileID != null) {
      return first.uploadedFileID == second.uploadedFileID;
    }
    return false;
  }

  void clearAll({bool fireEvent = true}) {
    if (fireEvent) {
      Bus.instance.fire(ClearSelectionsEvent());
    }
    lastSelectionOperationFiles.addAll(files);
    files.clear();
    notifyListeners();
  }

  ///Retains only the files that are present in the [filesToRetain] set in
  ///[files]. Takes the intersection of the two sets.
  void retainFiles(Set<EnteFile> filesToRetain) {
    files.retainAll(filesToRetain);
    notifyListeners();
  }
}
