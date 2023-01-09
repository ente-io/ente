import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/exif_util.dart';

class ExifInfoDialog extends StatefulWidget {
  final File file;
  const ExifInfoDialog(this.file, {Key? key}) : super(key: key);

  @override
  State<ExifInfoDialog> createState() => _ExifInfoDialogState();
}

class _ExifInfoDialogState extends State<ExifInfoDialog> {
  @override
  Widget build(BuildContext context) {
    final scrollController = ScrollController();
    return AlertDialog(
      title: Text(
        widget.file.title!,
        style: Theme.of(context).textTheme.headline5,
      ),
      content: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: scrollController,
          child: _getInfo(),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            "Close",
            style: Theme.of(context).textTheme.bodyText1,
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
      future: getExif(widget.file),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.hasData) {
          final exif = snapshot.data;
          String data = "";
          for (String key in exif.keys) {
            data += "$key: ${exif[key]}\n";
          }
          if (data.isEmpty) {
            data = "no exif data found";
          }
          return Container(
            padding: const EdgeInsets.all(2),
            color: Colors.white.withOpacity(0.05),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  data,
                  style: TextStyle(
                    fontSize: 14,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                    height: 1.4,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                ),
              ),
            ),
          );
        } else {
          return const EnteLoadingWidget();
        }
      },
    );
  }
}
