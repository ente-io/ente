import 'dart:ui';

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:logging/logging.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/loading_widget.dart';
import 'package:photos/utils/file_util.dart';

class ExifInfoDialog extends StatefulWidget {
  final File file;
  ExifInfoDialog(this.file, {Key key}) : super(key: key);

  @override
  _ExifInfoDialogState createState() => _ExifInfoDialogState();
}

class _ExifInfoDialogState extends State<ExifInfoDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.file.title),
      content: SingleChildScrollView(
        child: _getInfo(),
      ),
      actions: [
        TextButton(
          child: Text(
            "close",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );
  }

  Widget _getInfo() {
    return FutureBuilder(
      future: _getExif(),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final exif = snapshot.data;
          String data = "";
          for (String key in exif.keys) {
            data += "$key (${exif[key].tagType}): ${exif[key]}\n";
          }
          if (data.isEmpty) {
            data = "no exif data found";
          }
          return Container(
            padding: EdgeInsets.all(0),
            child: Center(
              child: Text(
                data,
                style: TextStyle(
                  fontSize: 14,
                  fontFeatures: [FontFeature.tabularFigures()],
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          );
        } else {
          return loadWidget;
        }
      },
    );
  }

  Future<Map<String, IfdTag>> _getExif() async {
    final exif = await readExifFromFile(await getFile(widget.file));
    for (String key in exif.keys) {
      Logger("ImageInfo").info("$key (${exif[key].tagType}): ${exif[key]}");
    }
    return exif;
  }
}
