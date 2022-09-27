import 'package:photos/models/trash_file.dart';

const kIgnoreReasonTrash = "trash";
const kIgnoreReasonInvalidFile = "invalidFile";

class IgnoredFile {
  final String? localID;
  final String? title;
  final String? deviceFolder;
  String reason;

  IgnoredFile(this.localID, this.title, this.deviceFolder, this.reason);

  static fromTrashItem(TrashFile? trashFile) {
    if (trashFile == null) return null;
    if (trashFile.localID == null ||
        trashFile.localID!.isEmpty ||
        trashFile.title == null ||
        trashFile.title!.isEmpty ||
        trashFile.deviceFolder == null ||
        trashFile.deviceFolder!.isEmpty) {
      return null;
    }

    return IgnoredFile(
      trashFile.localID,
      trashFile.title,
      trashFile.deviceFolder,
      kIgnoreReasonTrash,
    );
  }
}
