import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:myapp/db/db_helper.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:provider/provider.dart';
import 'package:share_extend/share_extend.dart';

import 'gallery_container_widget.dart';

class HomeWidget extends StatefulWidget {
  final String title;

  const HomeWidget(this.title, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = Set<Photo>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: _buildAppBar(context),
        bottomNavigationBar: _buildBottomNavigationBar(),
        body: GalleryContainer(
          _selectedNavBarItem == 0
              ? GalleryType.important_photos
              : GalleryType.all_photos,
          photoSelectionChangeCallback: (Set<Photo> selectedPhotos) {
            setState(() {
              _selectedPhotos = selectedPhotos;
            });
          },
        ),
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

  Widget _buildAppBar(BuildContext context) {
    if (_selectedPhotos.isEmpty) {
      return AppBar(title: Text(widget.title));
    }

    return AppBar(
      leading: IconButton(
        icon: Icon(Icons.close),
        onPressed: () {
          setState(() {
            _selectedPhotos.clear();
          });
        },
      ),
      title: Text(_selectedPhotos.length.toString()),
      actions: _getActions(context),
    );
  }

  List<Widget> _getActions(BuildContext context) {
    List<Widget> actions = List<Widget>();
    if (_selectedPhotos.isNotEmpty) {
      actions.add(IconButton(
        icon: Icon(Icons.delete),
        onPressed: () {
          _showDeletePhotosSheet(context);
        },
      ));
      actions.add(IconButton(
        icon: Icon(Icons.share),
        onPressed: () {
          _shareSelectedPhotos(context);
        },
      ));
    }
    return actions;
  }

  void _shareSelectedPhotos(BuildContext context) {
    var photoPaths = List<String>();
    for (Photo photo in _selectedPhotos) {
      photoPaths.add(photo.localPath);
    }
    ShareExtend.shareMultiple(photoPaths, "image");
  }

  void _showDeletePhotosSheet(BuildContext context) {
    final action = CupertinoActionSheet(
      actions: <Widget>[
        CupertinoActionSheetAction(
          child: Text("Delete on device"),
          isDestructiveAction: true,
          onPressed: () async {
            for (Photo photo in _selectedPhotos) {
              await DatabaseHelper.instance.deletePhoto(photo);
              File file = File(photo.localPath);
              await file.delete();
            }
            photoLoader.reloadPhotos();
            setState(() {
              _selectedPhotos.clear();
            });
            Navigator.pop(context);
          },
        ),
        CupertinoActionSheetAction(
          child: Text("Delete everywhere [WiP]"),
          isDestructiveAction: true,
          onPressed: () async {
            for (Photo photo in _selectedPhotos) {
              await DatabaseHelper.instance.markPhotoAsDeleted(photo);
              File file = File(photo.localPath);
              await file.delete();
            }
            photoLoader.reloadPhotos();
            setState(() {
              _selectedPhotos.clear();
            });
            Navigator.pop(context);
          },
        )
      ],
      cancelButton: CupertinoActionSheetAction(
        child: Text("Cancel"),
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }
}
