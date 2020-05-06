import 'dart:async';
import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/filters/important_items_filter.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/ui/album_list_widget.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/loading_widget.dart';
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
  static final importantItemsFilter = ImportantItemsFilter();
  final _logger = Logger("HomeWidgetState");
  ShakeDetector _detector;
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = HashSet<Photo>();
  StreamSubscription<LocalPhotosUpdatedEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    _detector = ShakeDetector.autoStart(
        shakeThresholdGravity: 3,
        onPhoneShake: () {
          _logger.info("Emailing logs");
          LoggingUtil.instance.emailLogs();
        });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        widget.title,
        _selectedPhotos,
        onSelectionClear: _clearSelectedPhotos,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: FutureBuilder<bool>(
        future: PhotoRepository.instance.loadPhotos(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return IndexedStack(
              children: <Widget>[
                Gallery(
                  _getFilteredPhotos(PhotoRepository.instance.photos),
                  _selectedPhotos,
                  photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
                    setState(() {
                      _selectedPhotos = selectedPhotos;
                    });
                  },
                ),
                AlbumListWidget(PhotoRepository.instance.photos)
              ],
              index: _selectedNavBarItem,
            );
          } else if (snapshot.hasError) {
            return Text("Error!");
          } else {
            return loadWidget;
          }
        },
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

  List<Photo> _getFilteredPhotos(List<Photo> unfilteredPhotos) {
    final List<Photo> filteredPhotos = List<Photo>();
    for (Photo photo in unfilteredPhotos) {
      if (importantItemsFilter.shouldInclude(photo)) {
        filteredPhotos.add(photo);
      }
    }
    return filteredPhotos;
  }

  void _clearSelectedPhotos() {
    setState(() {
      _selectedPhotos.clear();
    });
  }

  @override
  void dispose() {
    _detector.stopListening();
    _subscription.cancel();
    super.dispose();
  }
}
