import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'db/db_helper.dart';
import 'models/photo.dart';

class PhotoLoader extends ChangeNotifier {
  final logger = Logger();
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
    await loadPhotos();
    logger.i("Reloading...");
    notifyListeners();
  }
}
