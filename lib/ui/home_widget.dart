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
import 'package:photos/photo_sync_manager.dart';
import 'package:photos/ui/device_folders_gallery_widget.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:photos/ui/loading_photos_widget.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/ui/remote_folder_gallery_widget.dart';
import 'package:photos/ui/search_page.dart';
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
  final _remoteFolderGalleryWidget = RemoteFolderGalleryWidget();
  final _deviceFolderGalleryWidget = DeviceFolderGalleryWidget();

  ShakeDetector _detector;
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = HashSet<Photo>();
  StreamSubscription<LocalPhotosUpdatedEvent>
      _localPhotosUpdatedEventSubscription;

  @override
  void initState() {
    _detector = ShakeDetector.autoStart(
        shakeThresholdGravity: 3,
        onPhoneShake: () {
          _logger.info("Emailing logs");
          LoggingUtil.instance.emailLogs();
        });
    _localPhotosUpdatedEventSubscription =
        Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.homepage,
        widget.title,
        "/",
        _selectedPhotos,
        onSelectionClear: _clearSelectedPhotos,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: FutureBuilder<bool>(
        future: PhotoSyncManager.instance.hasScannedDisk(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return IndexedStack(
              children: <Widget>[
                snapshot.data ? _getMainGalleryWidget() : LoadingPhotosWidget(),
                _deviceFolderGalleryWidget,
                _remoteFolderGalleryWidget,
              ],
              index: _selectedNavBarItem,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else {
            return loadWidget;
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (BuildContext context) {
                return SearchPage();
              },
            ),
          );
        },
        child: Icon(
          Icons.search,
          size: 28,
        ),
        elevation: 1,
        backgroundColor: Colors.black38,
        foregroundColor: Colors.amber,
      ),
    );
  }

  Widget _getMainGalleryWidget() {
    return FutureBuilder<bool>(
      future: PhotoRepository.instance.loadPhotos(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Gallery(
            () => Future.value(
                _getFilteredPhotos(PhotoRepository.instance.photos)),
            selectedPhotos: _selectedPhotos,
            photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
              setState(() {
                _selectedPhotos = selectedPhotos;
              });
            },
            syncFunction: () {
              return PhotoSyncManager.instance.sync();
            },
            reloadTrigger: Bus.instance.on<LocalPhotosUpdatedEvent>(),
          );
        } else if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        } else {
          return loadWidget;
        }
      },
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
        BottomNavigationBarItem(
          icon: Icon(Icons.folder_shared),
          title: Text('Shared'),
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
    _localPhotosUpdatedEventSubscription.cancel();
    super.dispose();
  }
}
