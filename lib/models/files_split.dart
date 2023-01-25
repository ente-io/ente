import 'package:photos/models/file.dart';

class FilesSplit {
  final List<File> pendingUploads;
  final List<File> ownedByCurrentUser;
  final List<File> ownedByOtherUsers;

  FilesSplit({
    required this.pendingUploads,
    required this.ownedByCurrentUser,
    required this.ownedByOtherUsers,
  });

  int get totalFileOwnedCount =>
      pendingUploads.length + ownedByCurrentUser.length;

  static FilesSplit split(Iterable<File> files, int currentUserID) {
    final List<File> ownedByCurrentUser = [],
        ownedByOtherUsers = [],
        pendingUploads = [];
    for (var f in files) {
      if (f.ownerID == null || f.uploadedFileID == null) {
        pendingUploads.add(f);
      } else if (f.ownerID == currentUserID) {
        ownedByCurrentUser.add(f);
      } else {
        ownedByOtherUsers.add(f);
      }
    }
    return FilesSplit(
      pendingUploads: pendingUploads,
      ownedByCurrentUser: ownedByCurrentUser,
      ownedByOtherUsers: ownedByOtherUsers,
    );
  }
}
