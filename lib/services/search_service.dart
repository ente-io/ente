import 'package:photos/core/event_bus.dart';
import 'package:photos/db/files_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/file.dart';

class SearchService {
  List<File> _cachedFiles;

  SearchService._privateConstructor();
  static final SearchService instance = SearchService._privateConstructor();

  Future<void> init() async {
    _cachedFiles = await FilesDB.instance.getAllFilesFromDB();

    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      _cachedFiles = null;
      getAllFiles();
    });

    //need collectionUpdatedEvent listener?
  }

  Future<List<File>> getAllFiles() async {
    _cachedFiles ??= await FilesDB.instance.getAllFilesFromDB();
    return _cachedFiles;
  }
}
