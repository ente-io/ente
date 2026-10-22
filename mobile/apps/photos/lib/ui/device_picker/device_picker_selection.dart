import "package:photos/core/constants.dart";
import "package:photos/models/file/dummy_file.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/selected_files.dart";

class DevicePickerSelectedFiles extends SelectedFiles {
  bool locked = false;

  @override
  bool isFileSelected(EnteFile file) => files.contains(file);

  @override
  void toggleSelection(EnteFile file) {
    if (locked || file is DummyFile) return;
    if (isFileSelected(file)) {
      unSelectAll({file});
    } else {
      selectAll({file});
    }
  }

  @override
  void selectAll(Set<EnteFile> filesToSelect) {
    if (locked) return;
    final remaining = maxPickAssetLimit - files.length;
    final additions = filesToSelect
        .where((file) => file is! DummyFile && !files.contains(file))
        .take(remaining)
        .toSet();
    if (additions.isNotEmpty) super.selectAll(additions);
  }

  @override
  void unSelectAll(Set<EnteFile> filesToUnselect, {bool skipNotify = false}) {
    if (!locked) super.unSelectAll(filesToUnselect, skipNotify: skipNotify);
  }

  @override
  void clearAll({bool fireEvent = true}) {
    if (!locked) super.clearAll(fireEvent: false);
  }
}
