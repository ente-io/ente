import 'package:photos/models/file.dart';

class SelectedFileSplit {
  final List<File> pendingUploads;
  final List<File> ownedByCurrentUser;
  final List<File> ownedByOtherUsers;

  SelectedFileSplit({
    required this.pendingUploads,
    required this.ownedByCurrentUser,
    required this.ownedByOtherUsers,
  });

  int get totalFileOwnedCount =>
      pendingUploads.length + ownedByCurrentUser.length;
}
