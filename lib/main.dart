import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:myapp/photo_provider.dart';
import 'package:myapp/photo_sync_manager.dart';
import 'package:provider/provider.dart';
import 'package:myapp/ui/gallery_page.dart';

final provider = PhotoProvider();
final logger = Logger();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await provider.refreshGalleryList();
  var assets = await provider.list[0].assetList;
  PhotoSyncManager(assets);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    logger.i("hello, world");
    return ChangeNotifierProvider<PhotoProvider>.value(
      value: provider,
      child: MaterialApp(
        title: 'Orma',
        theme: ThemeData.dark(),
        home: GalleryPage(path: provider.list[0]),
      ),
    );
  }
}
