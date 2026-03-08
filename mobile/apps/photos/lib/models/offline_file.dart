import 'package:photos/models/file/file.dart';

class OfflineFile {
  final EnteFile originalFile;
  final String localPath;

  OfflineFile({
    required this.originalFile,
    required this.localPath,
  });
}
