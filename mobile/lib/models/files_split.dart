import 'package:photos/models/file/file.dart';

class FilesSplit {
  final List<EnteFile> pendingUploads;
  final List<EnteFile> ownedByCurrentUser;
  final List<EnteFile> ownedByOtherUsers;

  FilesSplit({
    required this.pendingUploads,
    required this.ownedByCurrentUser,
    required this.ownedByOtherUsers,
  });

  int get totalFileOwnedCount =>
      pendingUploads.length + ownedByCurrentUser.length;

  int get count => totalFileOwnedCount + ownedByOtherUsers.length;

  static FilesSplit split(Iterable<EnteFile> files, int currentUserID) {
    final List<EnteFile> ownedByCurrentUser = [],
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
