import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/photo_db.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/photo.dart';

class PhotoRepository {
  final logger = Logger("PhotoLoader");
  final _photos = List<Photo>();

  PhotoRepository._privateConstructor();
  static final PhotoRepository instance = PhotoRepository._privateConstructor();

  List<Photo> get photos {
    return _photos;
  }

  Future<bool> loadPhotos() async {
    PhotoDB db = PhotoDB.instance;
    var photos = await db.getAllPhotos();

    _photos.clear();
    _photos.addAll(photos);

    return true;
  }

  void reloadPhotos() async {
    logger.info("Reloading...");
    await loadPhotos();
    Bus.instance.fire(LocalPhotosUpdatedEvent());
  }
}
