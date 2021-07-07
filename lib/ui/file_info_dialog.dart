import 'package:exif/exif.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/ui/exif_info_dialog.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';

class FileInfoWidget extends StatelessWidget {
  final File file;
  final AssetEntity entity;

  const FileInfoWidget(
    this.file,
    this.entity, {
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isImage = file.fileType == FileType.image;
    var items = <Widget>[
      Row(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            color: Colors.white.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            getFormattedTime(
              DateTime.fromMicrosecondsSinceEpoch(file.creationTime),
            ),
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
      Padding(padding: EdgeInsets.all(6)),
      Row(
        children: [
          Icon(
            Icons.folder_outlined,
            color: Colors.white.withOpacity(0.85),
          ),
          Padding(padding: EdgeInsets.all(4)),
          Text(
            file.deviceFolder ??
                CollectionsService.instance
                    .getCollectionByID(file.collectionID)
                    .name,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
      Padding(padding: EdgeInsets.all(6)),
    ];
    items.addAll(
      [
        Row(
          children: [
            Icon(
              Icons.sd_storage_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            _getFileSize(),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ],
    );
    if (file.localID != null && !isImage) {
      items.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.timer_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                entity.videoDuration.toString().split(".")[0],
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsets.all(6)),
        ],
      );
    }
    if (isImage) {
      items.add(
        FutureBuilder(
          future: _getExif(),
          builder: (c, snapshot) {
            if (snapshot.hasData) {
              return _getExifWidgets(snapshot.data);
            } else {
              return Container();
            }
          },
        ),
      );
    }
    if (file.uploadedFileID != null) {
      items.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.cloud_upload_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                getFormattedTime(
                    DateTime.fromMicrosecondsSinceEpoch(file.updationTime)),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
        ],
      );
    }
    items.add(
      Padding(padding: EdgeInsets.all(12)),
    );
    final List<Widget> actions = [];
    if (isImage) {
      actions.add(
        TextButton(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(
                Icons.feed_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                "view exif",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return ExifInfoDialog(file);
              },
              barrierColor: Colors.black87,
            );
          },
        ),
      );
    }
    actions.add(
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
    );
    items.add(
      Row(
        mainAxisAlignment:
            isImage ? MainAxisAlignment.spaceBetween : MainAxisAlignment.end,
        children: actions,
      ),
    );
    return AlertDialog(
      title: Text(file.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: items,
        ),
      ),
    );
  }

  Widget _getExifWidgets(Map<String, IfdTag> exif) {
    final focalLength = exif["EXIF FocalLength"] != null
        ? (exif["EXIF FocalLength"].values.toList()[0] as Ratio).numerator /
            (exif["EXIF FocalLength"].values.toList()[0] as Ratio).denominator
        : null;
    final fNumber = exif["EXIF FNumber"] != null
        ? (exif["EXIF FNumber"].values.toList()[0] as Ratio).numerator /
            (exif["EXIF FNumber"].values.toList()[0] as Ratio).denominator
        : null;
    final List<Widget> children = [];
    if (exif["EXIF ExifImageWidth"] != null &&
        exif["EXIF ExifImageLength"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.photo_size_select_actual_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExifImageWidth"].toString() +
                  " x " +
                  exif["EXIF ExifImageLength"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    } else if (exif["Image ImageWidth"] != null &&
        exif["Image ImageLength"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.photo_size_select_actual_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["Image ImageWidth"].toString() +
                  " x " +
                  exif["Image ImageLength"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["Image Make"] != null && exif["Image Model"] != null) {
      children.addAll(
        [
          Row(
            children: [
              Icon(
                Icons.camera_outlined,
                color: Colors.white.withOpacity(0.85),
              ),
              Padding(padding: EdgeInsets.all(4)),
              Text(
                exif["Image Make"].toString() +
                    " " +
                    exif["Image Model"].toString(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                ),
              ),
            ],
          ),
          Padding(padding: EdgeInsets.all(6)),
        ],
      );
    }
    if (fNumber != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              CupertinoIcons.f_cursive,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              fNumber.toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (focalLength != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.center_focus_strong_outlined,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(focalLength.toString() + " mm",
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                )),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    if (exif["EXIF ExposureTime"] != null) {
      children.addAll([
        Row(
          children: [
            Icon(
              Icons.shutter_speed,
              color: Colors.white.withOpacity(0.85),
            ),
            Padding(padding: EdgeInsets.all(4)),
            Text(
              exif["EXIF ExposureTime"].toString(),
              style: TextStyle(
                color: Colors.white.withOpacity(0.85),
              ),
            ),
          ],
        ),
        Padding(padding: EdgeInsets.all(6)),
      ]);
    }
    return Column(
      children: children,
    );
  }

  Widget _getFileSize() {
    return FutureBuilder(
      future: getFile(file).then((f) => f.lengthSync()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Text(
            (snapshot.data / (1024 * 1024)).toStringAsFixed(2) + " MB",
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
            ),
          );
        } else {
          return Center(
            child: SizedBox.fromSize(
              size: Size.square(24),
              child: CupertinoActivityIndicator(
                radius: 8,
              ),
            ),
          );
        }
      },
    );
  }

  Future<Map<String, IfdTag>> _getExif() async {
    return await readExifFromFile(await getFile(file));
  }
}
