import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';

class SearchService {
  List<File> _cachedFiles;
  Future<List<File>> _future;

  SearchService._privateConstructor();
  static final SearchService instance = SearchService._privateConstructor();

  Future<void> init() async {
    // Intention of delay is to give more CPU cycles to other tasks
    Future.delayed(const Duration(seconds: 5), () async {
      // In case home screen loads before 5 seconds and user starts search, future will not be null
      _future == null
          ? FilesDB.instance.getAllFilesFromDB().then((value) {
              _cachedFiles = value;
            })
          : null;
    });

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _cachedFiles = null;
      getAllFiles();
    });
  }

  Future<List<File>> getAllFiles() async {
    if (_cachedFiles != null) {
      return _cachedFiles;
    }
    if (_future != null) {
      return _future;
    }
    _future = _fetchAllFiles();
    return _future;
  }

  Future<List<File>> _fetchAllFiles() async {
    _cachedFiles = await FilesDB.instance.getAllFilesFromDB();
    return _cachedFiles;
  }

  Future<List<File>> getFilesOnFilenameSearch(String query) async {
    List<File> matchedFiles = [];
    List<File> files = await getAllFiles();
    //<20 to limit number of files in result
    for (int i = 0; (i < files.length) && (matchedFiles.length < 20); i++) {
      File file = files[i];
      if (file.title.contains(RegExp(query, caseSensitive: false))) {
        matchedFiles.add(file);
      }
    }
    return matchedFiles;
  }

  void clearCachedFiles() {
    _cachedFiles.clear();
  }
}
