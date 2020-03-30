import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/photo_provider.dart';
import 'package:myapp/photo_sync_manager.dart';
import 'package:myapp/ui/gallery.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

final provider = PhotoProvider();
final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp2());
  await provider.refreshGalleryList();

  provider.list[0].assetList.then((assets) {
    var photoSyncManager = PhotoSyncManager(assets);
    photoSyncManager.init();
  });
}

Future<void> init(List<AssetEntity> assets) async {
  var photoSyncManager = PhotoSyncManager(assets);
  photoSyncManager.init();
}

class MyApp2 extends StatelessWidget {
  final PhotoLoader photoLoader = PhotoLoader.instance;

  @override
  Widget build(BuildContext context) {
    final title = 'Orma';
    return FutureBuilder<List<Photo>>(
        future: photoLoader.loadPhotos(),
        builder: (context, snapshot) {
          Widget body;
          if (snapshot.hasData) {
            body = Gallery();
          } else if (snapshot.hasError) {
            body = Text("Error!");
          } else {
            body = loadWidget;
          }
          return ChangeNotifierProvider<PhotoLoader>.value(
            value: photoLoader,
            child: MaterialApp(
              title: title,
              theme: ThemeData.dark(),
              home: Scaffold(
                  appBar: AppBar(
                    title: Text(title),
                  ),
                  body: body),
            ),
          );
        });
  }
}
