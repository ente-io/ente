import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';

class PhotoLoader {
  final logger = Logger();
  List<Photo> _photos;
  
  List<Photo> getPhotos() {
    return _photos;
  }

  Future<List<Photo>> loadPhotos() async {
    DatabaseHelper db = DatabaseHelper.instance;
    _photos = await db.getAllPhotos();
    logger.i("Imported photo size: " + _photos.length.toString());
    return _photos;
  }
}