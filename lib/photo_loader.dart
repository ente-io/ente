import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';

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

    logger.i("Imported photo size: " + _photos.length.toString());

    return true;
  }

  void reloadPhotos() async {
    await loadPhotos();
    logger.i("Reloading...");
    notifyListeners();
  }
}
