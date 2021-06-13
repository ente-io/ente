import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class RemoveAndroidNotExistsExample extends StatefulWidget {
  @override
  _RemoveAndroidNotExistsExampleState createState() =>
      _RemoveAndroidNotExistsExampleState();
}

class _RemoveAndroidNotExistsExampleState
    extends State<RemoveAndroidNotExistsExample> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Remove android not exists assets."),
      ),
      body: Column(
        children: <Widget>[
          ElevatedButton(
            child: Text("Click and see android logcat log."),
            onPressed: () {
              PhotoManager.editor.android.removeAllNoExistsAsset();
            },
          ),
        ],
      ),
    );
  }
}
