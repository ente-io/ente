import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_loader.dart';
import 'package:photos/ui/album_list_widget.dart';
import 'package:photos/ui/change_notifier_builder.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_container_widget.dart';
import 'package:photos/utils/logging_util.dart';
import 'package:provider/provider.dart';
import 'package:shake/shake.dart';
import 'package:logging/logging.dart';

class HomeWidget extends StatefulWidget {
  final String title;

  const HomeWidget(this.title, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  final logger = Logger("HomeWidgetState");
  ShakeDetector detector;
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = HashSet<Photo>();

  @override
  void initState() {
    super.initState();
    detector = ShakeDetector.waitForStart(onPhoneShake: () {
      logger.info("Emailing logs");
      emailLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    detector.startListening();
    return Scaffold(
      appBar: GalleryAppBarWidget(
        widget.title,
        _selectedPhotos,
        onSelectionClear: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
        onPhotosDeleted: (_) {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: IndexedStack(
        children: <Widget>[
          GalleryContainer(
            _selectedPhotos,
            (Set<Photo> selectedPhotos) {
              setState(() {
                _selectedPhotos = selectedPhotos;
              });
            },
          ),
          ChangeNotifierBuilder(
            value: photoLoader,
            builder: (_, __) {
              return AlbumListWidget(photoLoader.photos);
            },
          )
        ],
        index: _selectedNavBarItem,
      ),
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_filter),
          title: Text('Photos'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.photo_library),
          title: Text('Gallery'),
        ),
      ],
      currentIndex: _selectedNavBarItem,
      selectedItemColor: Colors.yellow[800],
      onTap: (index) {
        setState(() {
          _selectedNavBarItem = index;
        });
      },
    );
  }

  @override
  void dispose() {
    detector.stopListening();
    super.dispose();
  }
}
