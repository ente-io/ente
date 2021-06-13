import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class MoveToAnotherExample extends StatefulWidget {
  const MoveToAnotherExample({
    Key? key,
    required this.entity,
  }) : super(key: key);

  final AssetEntity entity;

  @override
  _MoveToAnotherExampleState createState() => _MoveToAnotherExampleState();
}

class _MoveToAnotherExampleState extends State<MoveToAnotherExample> {
  List<AssetPathEntity> targetPathList = [];
  AssetPathEntity? target;

  @override
  void initState() {
    super.initState();
    PhotoManager.getAssetPathList(hasAll: false).then((value) {
      this.targetPathList = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Move to another gallery"),
      ),
      body: Column(
        children: <Widget>[
          Center(
            child: Container(
              color: Colors.grey,
              width: 300,
              height: 300,
              child: _buildPreview(),
            ),
          ),
          buildTarget(),
          buildMoveButton(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return FutureBuilder<Uint8List?>(
      future: widget.entity.thumbDataWithSize(500, 500),
      builder: (_, snapshot) {
        if (snapshot.data != null) {
          return Image.memory(snapshot.data!);
        }
        return Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  Widget buildTarget() {
    return DropdownButton(
      items: targetPathList.map((v) => _buildItem(v)).toList(),
      value: target,
      onChanged: (AssetPathEntity? value) {
        this.target = value;
        setState(() {});
      },
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity v) {
    return DropdownMenuItem(
      child: Text(v.name),
      value: v,
    );
  }

  Widget buildMoveButton() {
    if (target == null) {
      return const SizedBox.shrink();
    }
    return ElevatedButton(
      onPressed: () {
        PhotoManager.editor.android.moveAssetToAnother(
          entity: widget.entity,
          target: target!,
        );
      },
      child: Text("Move to ' ${target!.name} '"),
    );
  }
}
