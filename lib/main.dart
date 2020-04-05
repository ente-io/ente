import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/photo_provider.dart';
import 'package:myapp/photo_sync_manager.dart';
import 'package:myapp/ui/gallery.dart';
import 'package:myapp/ui/loading_widget.dart';
import 'package:myapp/ui/search_page.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

final provider = PhotoProvider();
final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
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

class MyApp extends StatelessWidget {
  final PhotoLoader photoLoader = PhotoLoader.instance;

  @override
  Widget build(BuildContext context) {
    final title = 'Orma';
    return FutureBuilder<List<Photo>>(
        future: photoLoader.loadPhotos(),
        builder: (context, snapshot) {
          Widget body;
          if (snapshot.hasData) {
            body = HomeWidget();
          } else if (snapshot.hasError) {
            logger.e(snapshot.error);
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

class HomeWidget extends StatelessWidget {
  const HomeWidget({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: <Widget>[
          Hero(
              child: TextField(
                readOnly: true,
                onTap: () {
                  logger.i("Tapped");
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (BuildContext context) {
                        return SearchPage();
                      },
                    ),
                  );
                },
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Search "Paris"',
                  contentPadding: const EdgeInsets.all(12.0),
                ),
              ),
              tag: "search"),
          Flexible(
            child: Gallery(),
          )
        ],
      ),
    );
  }
}
