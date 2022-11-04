// @dart=2.9

import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import "package:photos/models/file.dart";
import 'package:photos/ui/viewer/file/exif_info_dialog.dart';
import 'package:photos/utils/toast_util.dart';

enum Status {
  loading,
  exifIsAvailable,
  noExif,
}

class RawExifListTileWidget extends StatelessWidget {
  final File file;
  final Map<String, IfdTag> exif;
  const RawExifListTileWidget(this.exif, this.file, {Key key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Status exifStatus = Status.loading;
    if (exif == null) {
      exifStatus = Status.loading;
    } else if (exif.isNotEmpty) {
      exifStatus = Status.exifIsAvailable;
    } else {
      exifStatus = Status.noExif;
    }
    return GestureDetector(
      onTap: exifStatus == Status.exifIsAvailable
          ? () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return ExifInfoDialog(file);
                },
                barrierColor: Colors.black87,
              );
            }
          : exifStatus == Status.noExif
              ? () {
                  showShortToast(context, "This image has no exif data");
                }
              : null,
      child: ListTile(
        horizontalTitleGap: 2,
        leading: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Icon(Icons.feed_outlined),
        ),
        title: const Text("EXIF"),
        subtitle: Text(
          exifStatus == Status.loading
              ? "Loading EXIF data.."
              : exifStatus == Status.exifIsAvailable
                  ? "View all EXIF data"
                  : "No EXIF data",
          style: Theme.of(context).textTheme.bodyText2.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .defaultTextColor
                    .withOpacity(0.5),
              ),
        ),
      ),
    );
  }
}
