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
      _future == null
          ? //in case home screen loads before 5 seconds and user starts search, future will not be null
          FilesDB.instance
              .getAllFilesFromDB()
              .then((value) => _cachedFiles = value)
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
    _future = fetchAllFiles();
    return _future;
  }

  Future<List<File>> fetchAllFiles() async {
    _cachedFiles ??= await FilesDB.instance.getAllFilesFromDB();
    return _cachedFiles;
  }

  void clearCachedFiles() {
    _cachedFiles.clear();
  }
}
