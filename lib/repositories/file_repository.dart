import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';

class FileRepository {
  final _logger = Logger("FileRepository");
  final _files = List<File>();

  FileRepository._privateConstructor();
  static final FileRepository instance = FileRepository._privateConstructor();

  List<File> get files {
    return _files;
  }

  Future<List<File>> loadFiles() async {
    final files = await FilesDB.instance.getFiles();
    final deduplicatedFiles = List<File>();
    for (int index = 0; index < files.length; index++) {
      if (index != 0) {
        bool isSameUploadedFile = files[index].uploadedFileID != null &&
            (files[index].uploadedFileID == files[index - 1].uploadedFileID);
        bool isSameLocalFile = files[index].localID != null &&
            (files[index].localID == files[index - 1].localID);
        if (isSameUploadedFile || isSameLocalFile) {
          continue;
        }
      }
      deduplicatedFiles.add(files[index]);
    }
    _files.clear();
    _files.addAll(deduplicatedFiles);
    return _files;
  }

  Future<void> reloadFiles() async {
    _logger.info("Reloading...");
    await loadFiles();
    Bus.instance.fire(LocalPhotosUpdatedEvent());
  }
}
