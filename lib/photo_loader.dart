import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';

class PhotoLoader extends ChangeNotifier {
  final logger = Logger();
  final _photos = List<Photo>();
  final _collatedPhotos = List<List<Photo>>();

  PhotoLoader._privateConstructor();
  static final PhotoLoader instance = PhotoLoader._privateConstructor();

  List<Photo> get photos {
    return _photos;
  }

  List<List<Photo>> get collatedPhotos {
    return _collatedPhotos;
  }

  Future<bool> loadPhotos() async {
    DatabaseHelper db = DatabaseHelper.instance;
    var photos = await db.getAllPhotos();

    _photos.clear();
    _photos.addAll(photos);

    final dailyPhotos = List<Photo>();
    final collatedPhotos = List<List<Photo>>();
    for (int index = 0; index < photos.length; index++) {
      if (index > 0 &&
          !_arePhotosFromSameDay(photos[index], photos[index - 1])) {
        var collatedDailyPhotos = List<Photo>();
        collatedDailyPhotos.addAll(dailyPhotos);
        collatedPhotos.add(collatedDailyPhotos);
        dailyPhotos.clear();
      }
      dailyPhotos.add(photos[index]);
    }
    if (dailyPhotos.isNotEmpty) {
      collatedPhotos.add(dailyPhotos);
    }
    _collatedPhotos.clear();
    _collatedPhotos.addAll(collatedPhotos);

    logger.i("Imported photo size: " + _photos.length.toString());

    return true;
  }

  void reloadPhotos() async {
    await loadPhotos();
    logger.i("Reloading...");
    notifyListeners();
  }

  bool _arePhotosFromSameDay(Photo firstPhoto, Photo secondPhoto) {
    var firstDate =
        DateTime.fromMicrosecondsSinceEpoch(firstPhoto.createTimestamp);
    var secondDate =
        DateTime.fromMicrosecondsSinceEpoch(secondPhoto.createTimestamp);
    return firstDate.year == secondDate.year &&
        firstDate.month == secondDate.month &&
        firstDate.day == secondDate.day;
  }
}
