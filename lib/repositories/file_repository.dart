import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';

class FileRepository {
  final _logger = Logger("PhotoRepository");
  final _files = List<File>();

  FileRepository._privateConstructor();
  static final FileRepository instance = FileRepository._privateConstructor();

  List<File> get files {
    return _files;
  }

  Future<List<File>> loadFiles() async {
    var files = await FilesDB.instance.getFiles();
    _files.clear();
    _files.addAll(files);

    return _files;
  }

  Future<void> reloadFiles() async {
    _logger.info("Reloading...");
    await loadFiles();
    Bus.instance.fire(LocalPhotosUpdatedEvent());
  }
}
