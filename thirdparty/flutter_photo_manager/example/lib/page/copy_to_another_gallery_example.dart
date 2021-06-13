import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_scanner_example/model/photo_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:provider/provider.dart';

class CopyToAnotherGalleryPage extends StatefulWidget {
  const CopyToAnotherGalleryPage({
    Key? key,
    required this.assetEntity,
  }) : super(key: key);

  final AssetEntity assetEntity;

  @override
  _CopyToAnotherGalleryPageState createState() =>
      _CopyToAnotherGalleryPageState();
}

class _CopyToAnotherGalleryPageState extends State<CopyToAnotherGalleryPage> {
  AssetPathEntity? targetGallery;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PhotoProvider>(context, listen: false);
    final list = provider.list;
    return Scaffold(
      appBar: AppBar(
        title: Text("move to another"),
      ),
      body: Column(
        children: <Widget>[
          AspectRatio(
            aspectRatio: 1,
            child: FutureBuilder<Uint8List?>(
              future: widget.assetEntity.thumbDataWithSize(500, 500),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return Image.memory(snapshot.data!);
                }
                return Text("loading");
              },
            ),
          ),
          DropdownButton<AssetPathEntity>(
            onChanged: (value) {
              this.targetGallery = value;
              setState(() {});
            },
            value: targetGallery,
            hint: Text("Select target gallery"),
            items: list.map<DropdownMenuItem<AssetPathEntity>>((item) {
              return _buildItem(item);
            }).toList(),
          ),
          _buildCopyButton(),
        ],
      ),
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity item) {
    return DropdownMenuItem<AssetPathEntity>(
      value: item,
      child: Text(item.name),
    );
  }

  void _copy() async {
    if (targetGallery == null) {
      return null;
    }
    final result = await PhotoManager.editor.copyAssetToPath(
      asset: widget.assetEntity,
      pathEntity: this.targetGallery!,
    );

    print("copy result = $result");
  }

  Widget _buildCopyButton() {
    return ElevatedButton(
      onPressed: _copy,
      child: Text(
        targetGallery == null
            ? "Please select gallery"
            : "copy to ${targetGallery!.name}",
      ),
    );
  }
}
