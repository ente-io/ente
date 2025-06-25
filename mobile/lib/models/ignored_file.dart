import "package:photos/models/api/diff/diff.dart";

const kIgnoreReasonTrash = "trash";

class IgnoredFile {
  final String? localID;
  final String? title;
  final String? deviceFolder;
  String reason;

  IgnoredFile(this.localID, this.title, this.deviceFolder, this.reason);

  static fromTrashItem(DiffItem? item) {
    if (item == null) return null;
    final fileItem = item.fileItem;
    if (fileItem.localID == null ||
        fileItem.localID!.isEmpty ||
        fileItem.title.isEmpty ||
        fileItem.deviceFolder == null ||
        fileItem.deviceFolder!.isEmpty) {
      return null;
    }

    return IgnoredFile(
      fileItem.localID,
      fileItem.title,
      fileItem.deviceFolder,
      kIgnoreReasonTrash,
    );
  }
}
