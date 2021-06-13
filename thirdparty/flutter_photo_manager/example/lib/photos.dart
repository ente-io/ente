import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'photo_list.dart';

class PhotoPage extends StatefulWidget {
  const PhotoPage({
    Key? key,
    required this.pathEntity,
    required this.photos,
  }) : super(key: key);

  final AssetPathEntity pathEntity;
  final List<AssetEntity> photos;

  @override
  _PhotoPageState createState() => _PhotoPageState();
}

class _PhotoPageState extends State<PhotoPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pathEntity.name),
      ),
      body: PhotoList(photos: widget.photos),
    );
  }
}
