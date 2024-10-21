import 'dart:ui';

import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/utils/exif_util.dart';

class ExifInfoDialog extends StatelessWidget {
  final EnteFile file;
  const ExifInfoDialog(this.file, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            S.of(context).exif,
            style: textTheme.h3Bold,
          ),
          Text(
            file.title!,
            style: textTheme.smallMuted,
          ),
        ],
      ),
      content: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: _getInfo(),
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            S.of(context).close,
            style: textTheme.body,
          ),
          onPressed: () {
            Navigator.of(context).pop('dialog');
          },
        ),
      ],
    );
  }

  Widget _getInfo() {
    return FutureBuilder(
      future: getExif(file),
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
