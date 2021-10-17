import 'package:photos/models/trash_file.dart';

const kIgnoreReasonTrash = "trash";
const kIgnoreReasonInvalidFile = "invalidFile";

class IgnoredFile {
  final String localID;
  final String title;
  String reason;

  IgnoredFile(this.localID, this.title, this.reason);

  factory IgnoredFile.fromTrashItem(TrashFile trashFile) {
    if (trashFile == null) return null;
    if (trashFile.localID == null ||
        trashFile.title == null ||
        trashFile.localID.isEmpty ||
        trashFile.title.isEmpty) {
      return null;
    }

    return IgnoredFile(trashFile.localID, trashFile.title, kIgnoreReasonTrash);
  }
}
