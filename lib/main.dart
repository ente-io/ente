import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/photo_provider.dart';
import 'package:myapp/photo_sync_manager.dart';
import 'package:myapp/ui/home_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

final provider = PhotoProvider();
final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
  await provider.refreshGalleryList();

  if (provider.list.length > 0) {
    provider.list[0].assetList.then((assets) {
      init(assets);
    });
  } else {
    init(List<AssetEntity>());
  }
}

Future<void> init(List<AssetEntity> assets) async {
  var photoSyncManager = PhotoSyncManager(assets);
  photoSyncManager.init();
}

class MyApp extends StatelessWidget {
  final _title = 'Orma';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      theme: ThemeData.dark(),
      home: ChangeNotifierProvider<PhotoLoader>.value(
        value: PhotoLoader.instance,
        child: HomeWidget(_title),
      ),
    );
  }
}
