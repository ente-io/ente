import 'package:logging/logging.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/db/db_helper.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/photo.dart';

class PhotoLoader {
  final logger = Logger("PhotoLoader");
  final _photos = List<Photo>();

  PhotoLoader._privateConstructor();
  static final PhotoLoader instance = PhotoLoader._privateConstructor();

  List<Photo> get photos {
    return _photos;
  }

  Future<bool> loadPhotos() async {
    DatabaseHelper db = DatabaseHelper.instance;
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
