import 'package:flutter/material.dart';
import 'package:image_scanner_example/page/detail_page.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class CreateEntityById extends StatefulWidget {
  @override
  _CreateEntityByIdState createState() => _CreateEntityByIdState();
}

class _CreateEntityByIdState extends State<CreateEntityById> {
  TextEditingController controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller.text = '1016711';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create AssetEntity by id'),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "input asset id",
            ),
          ),
          ElevatedButton(
            child: Text('Create assetEntity'),
            onPressed: createAssetEntityAndShow,
          ),
        ],
      ),
    );
  }

  void createAssetEntityAndShow() async {
    final id = controller.text.trim();
    final asset = await AssetEntity.fromId(id);
    if (asset == null) {
      showToast("Cannot create asset by $id");
      return;
    }
    final mediaUrl = await asset.getMediaUrl();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (c) => DetailPage(
          entity: asset,
          mediaUrl: mediaUrl,
        ),
      ),
    );
  }
}
