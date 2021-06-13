import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:image_scanner_example/widget/gallery_item_widget.dart';
import 'package:provider/provider.dart';

class GalleryListPage extends StatefulWidget {
  const GalleryListPage({Key? key}) : super(key: key);

  @override
  _GalleryListPageState createState() => _GalleryListPageState();
}

class _GalleryListPageState extends State<GalleryListPage> {
  PhotoProvider get provider => context.watch<PhotoProvider>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gallery list"),
      ),
      body: Container(
        child: Scrollbar(
          child: ListView.builder(
            itemBuilder: _buildItem,
            itemCount: provider.list.length,
          ),
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = provider.list[index];
    return GalleryItemWidget(
      path: item,
      setState: setState,
    );
  }
}
