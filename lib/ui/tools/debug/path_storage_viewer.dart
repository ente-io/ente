// @dart=2.9

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/utils/app_size.dart';
import 'package:photos/utils/data_util.dart';

class PathStorageItem {
  final String path;
  final String title;
  final bool allowCacheClear;

  PathStorageItem.name(
    this.path,
    this.title, {
    this.allowCacheClear = false,
  });
}

class PathStorageViewer extends StatefulWidget {
  final PathStorageItem path;

  const PathStorageViewer(
    this.path, {
    Key key,
  }) : super(key: key);

  @override
  State<PathStorageViewer> createState() => _PathStorageViewerState();
}

class _PathStorageViewerState extends State<PathStorageViewer> {
  Map<String, int> _logs;

  @override
  void initState() {
    directoryStat(widget.path.path).then((logs) {
      setState(() {
        _logs = logs;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _getBody();
  }

  Widget _getBody() {
    if (_logs == null) {
      return const EnteLoadingWidget();
    }
    final int fileCount = _logs["fileCount"] ?? -1;
    final int size = _logs['size'];

    return MenuItemWidget(
      alignCaptionedTextToLeft: true,
      captionedTextWidget: CaptionedTextWidget(
        title: widget.path.title,
        subTitle: '$fileCount',
        subTitleColor: getEnteColorScheme(context).textFaint,
      ),
      trailingWidget: Text(
        formatBytes(size),
        style: getEnteTextTheme(context)
            .small
            .copyWith(color: getEnteColorScheme(context).textFaint),
      ),
      trailingIcon: widget.path.allowCacheClear ? Icons.chevron_right : null,
      menuItemColor: getEnteColorScheme(context).fillFaint,
      onTap: () async {
        if (kDebugMode) {
          await Clipboard.setData(ClipboardData(text: widget.path.path));
          debugPrint(widget.path.path);
        }
      },
    );
  }
}
