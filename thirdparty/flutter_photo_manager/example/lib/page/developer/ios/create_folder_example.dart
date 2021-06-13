import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class CreateFolderExample extends StatefulWidget {
  @override
  _CreateFolderExampleState createState() => _CreateFolderExampleState();
}

class _CreateFolderExampleState extends State<CreateFolderExample> {
  final TextEditingController nameController = TextEditingController();

  List<AssetPathEntity> subDir = [];

  AssetPathEntity? parent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Create folder")),
      body: Column(
        children: <Widget>[
          TextField(
            controller: nameController,
          ),
          Row(
            children: <Widget>[
              ElevatedButton.icon(
                onPressed: createFolder,
                icon: Icon(Icons.create_new_folder),
                label: Text("Create folder"),
              ),
              ElevatedButton.icon(
                onPressed: createAlbum,
                icon: Icon(Icons.create_new_folder),
                label: Text("Create album"),
              ),
            ],
          ),
          _buildParentTarget(),
          ElevatedButton.icon(
            onPressed: () async {
              final path =
                  (await PhotoManager.getAssetPathList(onlyAll: true))[0];
              final subPath = await path.getSubPathList();
              this.subDir = subPath;
              this.parent = null;
              setState(() {});
            },
            icon: Icon(Icons.refresh),
            label: Text("Refresh sub path"),
          ),
        ],
      ),
    );
  }

  void createFolder() {
    final name = nameController.text;
    PhotoManager.editor.iOS.createFolder(
      name,
      parent: parent,
    );
  }

  void createAlbum() {
    final name = nameController.text;
    PhotoManager.editor.iOS.createAlbum(
      name,
      parent: parent,
    );
  }

  Widget _buildParentTarget() {
    return DropdownButton<AssetPathEntity>(
      items: subDir
          .map<DropdownMenuItem<AssetPathEntity>>((v) => _buildItem(v))
          .toList(),
      onChanged: (path) {
        this.parent = path;
        setState(() {});
      },
      value: parent,
      hint: Text("Select parent path."),
    );
  }

  DropdownMenuItem<AssetPathEntity> _buildItem(AssetPathEntity pathEntity) {
    return DropdownMenuItem<AssetPathEntity>(
      value: pathEntity,
      child: Container(child: Text(pathEntity.name)),
    );
  }
}
