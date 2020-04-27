import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:myapp/models/photo.dart';
import 'package:myapp/photo_loader.dart';
import 'package:myapp/ui/album_list_widget.dart';
import 'package:myapp/ui/change_notifier_builder.dart';
import 'package:myapp/ui/gallery_app_bar_widget.dart';
import 'package:myapp/ui/gallery_container_widget.dart';
import 'package:provider/provider.dart';

class HomeWidget extends StatefulWidget {
  final String title;

  const HomeWidget(this.title, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  PhotoLoader get photoLoader => Provider.of<PhotoLoader>(context);
  int _selectedNavBarItem = 0;
  Set<Photo> _selectedPhotos = HashSet<Photo>();

  @override
  Widget build(BuildContext context) {
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
}
