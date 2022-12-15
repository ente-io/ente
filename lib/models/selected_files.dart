import 'package:collection/collection.dart' show IterableExtension;
import 'package:flutter/foundation.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/clear_selections_event.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/selected_file_breakup.dart';

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

  void selectAll(Set<File> selectedFiles) {
    files.addAll(selectedFiles);
    lastSelections.clear();
    lastSelections.addAll(selectedFiles);
    notifyListeners();
  }

  void unSelectAll(Set<File> selectedFiles) {
    files.removeAll(selectedFiles);
    lastSelections.clear();
    notifyListeners();
  }

  bool isFileSelected(File file) {
    final File? alreadySelected = files.firstWhereOrNull(
      (element) => element.generatedID == file.generatedID,
    );
    return alreadySelected != null;
  }

  bool isPartOfLastSelected(File file) {
    final File? matchedFile = lastSelections.firstWhereOrNull(
      (element) => element.generatedID == file.generatedID,
    );
    return matchedFile != null;
  }

  SelectedFileSplit split(int currentUseID) {
    final List<File> ownedByCurrentUser = [],
        ownedByOtherUsers = [],
        pendingUploads = [];
    for (var f in files) {
      if (f.ownerID == null || f.uploadedFileID == null) {
        pendingUploads.add(f);
      } else if (f.ownerID == currentUseID) {
        ownedByCurrentUser.add(f);
      } else {
        ownedByOtherUsers.add(f);
      }
    }
    return SelectedFileSplit(
      pendingUploads: pendingUploads,
      ownedByCurrentUser: ownedByCurrentUser,
      ownedByOtherUsers: ownedByOtherUsers,
    );
  }

  void clearAll() {
    Bus.instance.fire(ClearSelectionsEvent());
    lastSelections.addAll(files);
    files.clear();
    notifyListeners();
  }
}
