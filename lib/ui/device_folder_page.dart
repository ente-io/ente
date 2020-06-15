import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/local_photos_updated_event.dart';
import 'package:photos/models/device_folder.dart';
import 'package:photos/models/photo.dart';
import 'package:photos/photo_repository.dart';
import 'package:photos/ui/gallery.dart';
import 'package:photos/ui/gallery_app_bar_widget.dart';
import 'package:logging/logging.dart';

class DeviceFolderPage extends StatefulWidget {
  final DeviceFolder folder;

  const DeviceFolderPage(this.folder, {Key key}) : super(key: key);

  @override
  _DeviceFolderPageState createState() => _DeviceFolderPageState();
}

class _DeviceFolderPageState extends State<DeviceFolderPage> {
  final logger = Logger("DeviceFolderPageState");
  Set<Photo> _selectedPhotos = Set<Photo>();
  StreamSubscription<LocalPhotosUpdatedEvent> _subscription;

  @override
  void initState() {
    _subscription = Bus.instance.on<LocalPhotosUpdatedEvent>().listen((event) {
      setState(() {});
    });
    super.initState();
  }

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: GalleryAppBarWidget(
        GalleryAppBarType.local_folder,
        widget.folder.name,
        widget.folder.thumbnailPhoto.deviceFolder,
        _selectedPhotos,
        onSelectionClear: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      body: Gallery(
        () => Future.value(_getFilteredPhotos(PhotoRepository.instance.photos)),
        selectedPhotos: _selectedPhotos,
        photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
          setState(() {
            _selectedPhotos = selectedPhotos;
          });
        },
      ),
    );
  }

  List<Photo> _getFilteredPhotos(List<Photo> unfilteredPhotos) {
    final List<Photo> filteredPhotos = List<Photo>();
    for (Photo photo in unfilteredPhotos) {
      if (widget.folder.filter.shouldInclude(photo)) {
        filteredPhotos.add(photo);
      }
    }
    return filteredPhotos;
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
