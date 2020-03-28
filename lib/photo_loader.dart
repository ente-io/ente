import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoLoader extends ChangeNotifier {
  final logger = Logger();
  final _photos = List<Photo>();
  final _assetMap = Map<String, AssetEntity>();
  
  PhotoLoader._privateConstructor();
  static final PhotoLoader instance = PhotoLoader._privateConstructor();

  List<Photo> getPhotos() {
    return _photos;
  }

  Future<List<Photo>> loadPhotos() async {
    DatabaseHelper db = DatabaseHelper.instance;
    var photos = await db.getAllPhotos();
    _photos.clear();
    _photos.addAll(photos);
    logger.i("Imported photo size: " + _photos.length.toString());
    return _photos;
  }

  void reloadPhotos() async {
    await loadPhotos();
    logger.i("Reloading...");
    notifyListeners();
  }

  void addAsset(String path, AssetEntity asset) {
    _assetMap[path] = asset;
  }

  Future<Uint8List> getThumbnail(String path, int size) {
    if (!_assetMap.containsKey(path)) {
      logger.w("No thumbnail");
      return Future.value(null);
    }
    return _assetMap[path].thumbDataWithSize(size, size);
  }
}