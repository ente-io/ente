import 'package:exif/exif.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/file_type.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/utils/date_time_util.dart';
import 'package:photos/utils/file_util.dart';

class FileInfoWidget extends StatefulWidget {
  final File file;
  final AssetEntity entity;
  final int fileSize;

  const FileInfoWidget(
    this.file,
    this.entity,
    this.fileSize, {
    Key key,
  }) : super(key: key);

  @override
  _FileInfoWidgetState createState() => _FileInfoWidgetState();
}

class _FileInfoWidgetState extends State<FileInfoWidget> {
  @override
  void initState() {
    _getExif();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var items = <Widget>[
      Row(
        children: [
          Icon(Icons.calendar_today_outlined),
          Padding(padding: EdgeInsets.all(4)),
          Text(getFormattedTime(
              DateTime.fromMicrosecondsSinceEpoch(widget.file.creationTime))),
        ],
      ),
      Padding(padding: EdgeInsets.all(4)),
      Row(
        children: [
          Icon(Icons.folder_outlined),
          Padding(padding: EdgeInsets.all(4)),
          Text(widget.file.deviceFolder ??
              CollectionsService.instance
                  .getCollectionByID(widget.file.collectionID)
                  .name),
        ],
      ),
      Padding(padding: EdgeInsets.all(4)),
    ];
    if (widget.file.localID != null) {
      items.add(
        Row(
          children: [
            Icon(Icons.sd_storage_outlined),
            Padding(padding: EdgeInsets.all(4)),
            Text((widget.fileSize / (1024 * 1024)).toStringAsFixed(2) + " MB"),
          ],
        ),
      );
      items.add(
        Padding(padding: EdgeInsets.all(4)),
      );
      if (widget.file.fileType == FileType.image) {
        items.add(
          Row(
            children: [
              Icon(Icons.photo_size_select_actual_outlined),
              Padding(padding: EdgeInsets.all(4)),
              Text(widget.entity.width.toString() +
                  " x " +
                  widget.entity.height.toString()),
            ],
          ),
        );
      } else {
        items.add(
          Row(
            children: [
              Icon(Icons.timer_outlined),
              Padding(padding: EdgeInsets.all(4)),
              Text(widget.entity.videoDuration.toString().split(".")[0]),
            ],
          ),
        );
      }
      items.add(
        Padding(padding: EdgeInsets.all(4)),
      );
    }
    if (widget.file.uploadedFileID != null) {
      items.add(
        Row(
          children: [
            Icon(Icons.cloud_upload_outlined),
            Padding(padding: EdgeInsets.all(4)),
            Text(getFormattedTime(
                DateTime.fromMicrosecondsSinceEpoch(widget.file.updationTime))),
          ],
        ),
      );
    }
    items.add(
      Padding(padding: EdgeInsets.all(12)),
    );
    items.add(
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Icon(
                  Icons.camera_outlined,
                  color: Colors.white,
                ),
                Padding(padding: EdgeInsets.all(4)),
                Text(
                  "view exif",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop('dialog');
            },
          ),
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
      ),
    );
    return AlertDialog(
      title: Text(widget.file.title),
      content: SingleChildScrollView(
        child: ListBody(
          children: items,
        ),
      ),
    );
  }

  Future<void> _getExif() async {
    final exif = await readExifFromFile(await getFile(widget.file));
    for (String key in exif.keys) {
      Logger("ImageInfo").info("$key (${exif[key].tagType}): ${exif[key]}");
    }
  }
}
