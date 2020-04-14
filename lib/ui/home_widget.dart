import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'gallery_container_widget.dart';

class HomeWidget extends StatefulWidget {
  final String title;

  const HomeWidget(this.title, {Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.title,
      theme: ThemeData.dark(),
      home: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        bottomNavigationBar: BottomNavigationBar(
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
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.yellow[800],
          onTap: _onItemTapped,
        ),
        body: GalleryContainer(_selectedIndex == 0
            ? GalleryType.important_photos
            : GalleryType.all_photos),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
}
