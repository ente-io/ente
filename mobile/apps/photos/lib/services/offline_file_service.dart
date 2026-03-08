import 'package:photos/models/file/file.dart';
import 'package:photos/models/offline_file.dart';

class OfflineFileService {
  static final OfflineFileService _instance = OfflineFileService._internal();
  factory OfflineFileService() => _instance;
  OfflineFileService._internal();

  final List<OfflineFile> _offlineFiles = [];

  Future<void> makeFileAvailableOffline(EnteFile file) async {
    // This is a placeholder. In a real implementation, this would
    // download the file, encrypt it, and store it locally.
    final offlineFile = OfflineFile(
      originalFile: file,
      localPath: 'path/to/encrypted/${file.uploadedFileID}',
    );
    _offlineFiles.add(offlineFile);
  }

  List<OfflineFile> getOfflineFiles() {
    return _offlineFiles;
  }
}
