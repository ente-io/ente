import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class PhotoList extends StatefulWidget {
  const PhotoList({required this.photos});

  final List<AssetEntity> photos;

  @override
  _PhotoListState createState() => _PhotoListState();
}

class _PhotoListState extends State<PhotoList> {
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
      ),
      itemBuilder: _buildItem,
      itemCount: widget.photos.length,
    );
  }

  Widget _buildItem(BuildContext context, int index) {
    AssetEntity entity = widget.photos[index];
    // print(
    //     "request index = $index , image id = ${entity.id} type = ${entity.type}");

    // Future<Uint8List> thumbDataWithSize =
    //     entity.thumbDataWithSize(500, 500); // get thumb with width and height.
    // Future<Uint8List> thumbData =
    //     entity.thumbData; // the method will get thumbData is size 64*64.
    // Future<Uint8List> imageFullData = entity.fullData; // get the origin data.
    // Future<File> file = entity.file; // get file
    // Future<Duration> length = entity.videoDuration;
    // length.then((v) {
    //   print("duration = $v");
    // });

    return FutureBuilder<Uint8List?>(
      future: entity.thumbDataWithSize(150, 150),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return InkWell(
            onTap: () => showInfo(entity),
            child: Stack(
              children: <Widget>[
                Image.memory(
                  snapshot.data!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                IgnorePointer(
                  child: Container(
                    alignment: Alignment.center,
                    child: Text(
                      '${entity.type}',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        return Center(child: Text('loading...'));
      },
    );
  }

  Future<void> showInfo(AssetEntity entity) async {
    if (entity.type == AssetType.video) {
      var file = await entity.file;
      if (file == null) {
        return;
      }
      var length = file.lengthSync();
      var size = entity.size;
      print(
        "${entity.id} length = $length, "
        "size = $size, "
        "dateTime = ${entity.createDateTime}",
      );
    } else {
      final Size size = entity.size;
      print("${entity.id} size = $size, dateTime = ${entity.createDateTime}");
    }

    /// copy log id , and create AssetEntity with id from main.dart
  }
}
