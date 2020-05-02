import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'core/configuration.dart';
import 'photo_loader.dart';
import 'photo_sync_manager.dart';
import 'ui/home_widget.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
  Configuration.instance.init();
  PhotoSyncManager.instance.sync();
}

class MyApp extends StatelessWidget with WidgetsBindingObserver {
  final _title = 'Photos';
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addObserver(this);

    return MaterialApp(
      title: _title,
      theme: ThemeData.dark(),
      home: ChangeNotifierProvider<PhotoLoader>.value(
        value: PhotoLoader.instance,
        child: HomeWidget(_title),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PhotoSyncManager.instance.sync();
    }
  }
}
