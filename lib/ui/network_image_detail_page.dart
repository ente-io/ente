import 'package:flutter/material.dart';
import 'package:myapp/core/constants.dart' as Constants;

class NetworkImageDetailPage extends StatelessWidget {
  final String _path;

  const NetworkImageDetailPage(this._path, {Key key}) : super(key: key);

  @override
  Widget build(Object context) {
    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[
          // action button
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // TODO
            },
          )
        ],
      ),
      body: Center(
        child: Container(
          child: _buildContent(context),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        Navigator.pop(context);
      },
      child: Image.network(Constants.ENDPOINT + "/" + _path),
    );
  }
}
