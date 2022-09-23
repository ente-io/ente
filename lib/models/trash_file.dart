import 'package:photos/models/file.dart';

class TrashFile extends File {
  // time when file was put in the trash for first time
  int? createdAt;

  // for non-deleted trash items, updateAt is usually equal to the latest time
  // when the file was moved to trash
  int? updateAt;

  // time after which will will be deleted from trash & user's storage usage
  // will go down
  int? deleteBy;
}
