import 'package:flutter/material.dart';
import 'package:image_scanner_example/widget/gallery_item_widget.dart';
import 'package:photo_manager/photo_manager.dart';

class SubFolderPage extends StatefulWidget {
  const SubFolderPage({
    Key? key,
    required this.pathList,
    required this.title,
  }) : super(key: key);

  final List<AssetPathEntity> pathList;
  final String title;

  @override
  _SubFolderPageState createState() => _SubFolderPageState();
}

class _SubFolderPageState extends State<SubFolderPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemBuilder: _buildItem,
        itemCount: widget.pathList.length,
      ),
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    final item = widget.pathList[index];
    return GalleryItemWidget(
      path: item,
      setState: setState,
    );
  }
}
