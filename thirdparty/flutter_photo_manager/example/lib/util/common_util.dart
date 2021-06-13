import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:oktoast/oktoast.dart';
import 'package:photo_manager/photo_manager.dart';

class CommonUtil {
  static Future<void> showInfoDialog(
      BuildContext context, AssetEntity entity) async {
    final latlng = await entity.latlngAsync();

    final lat = entity.latitude == 0 ? latlng.latitude : entity.latitude;
    final lng = entity.longitude == 0 ? latlng.longitude : entity.longitude;

    Widget w = Center(
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(15),
        child: Material(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              GestureDetector(
                child: _buildInfoItem("id", entity.id),
                onLongPress: () {
                  Clipboard.setData(ClipboardData(text: entity.id));
                  showToast('The id already copied.');
                },
              ),
              _buildInfoItem("create", entity.createDateTime.toString()),
              _buildInfoItem("modified", entity.modifiedDateTime.toString()),
              _buildInfoItem("size", entity.size.toString()),
              _buildInfoItem("orientation", entity.orientation.toString()),
              _buildInfoItem("duration", entity.videoDuration.toString()),
              _buildInfoItemAsync("title", entity.titleAsync),
              _buildInfoItem("lat", lat?.toString()),
              _buildInfoItem("lng", lng?.toString()),
              _buildInfoItem("relative path", entity.relativePath ?? 'null'),
            ],
          ),
        ),
      ),
    );
    showDialog(context: context, builder: (c) => w);
  }

  static Widget _buildInfoItem(String title, String? info) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Container(
            alignment: Alignment.centerLeft,
            child: Text(
              title.padLeft(10, " "),
              textAlign: TextAlign.start,
            ),
            width: 88,
          ),
          Expanded(
            child: Text((info ?? 'null').padLeft(40, " ")),
          ),
        ],
      ),
    );
  }

  static Widget _buildInfoItemAsync(String title, Future<String> info) {
    return FutureBuilder(
      future: info,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return _buildInfoItem(title, "");
        }
        return _buildInfoItem(title, snapshot.data);
      },
    );
  }
}
