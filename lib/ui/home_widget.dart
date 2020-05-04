import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_loader.dart';
import 'package:photos/ui/album_list_widget.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/gallery_container_widget.dart';
import 'package:photos/utils/logging_util.dart';
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
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = HashSet<Photo>();

  @override
  void initState() {
    Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    detector = ShakeDetector.waitForStart(
        shakeThresholdGravity: 3,
        onPhoneShake: () {
          logger.info("Emailing logs");
          LoggingUtil.instance.emailLogs();
        });
    super.initState();
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
          AlbumListWidget(PhotoLoader.instance.photos)
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
