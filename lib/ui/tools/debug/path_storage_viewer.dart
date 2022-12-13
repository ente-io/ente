// @dart=2.9

import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/ui/components/menu_section_description_widget.dart';
import 'package:photos/utils/app_size.dart';
import 'package:photos/utils/data_util.dart';

class PathStorageViewer extends StatefulWidget {
  final String path;
  final bool allowClear;

  const PathStorageViewer(
    this.path, {
    Key key,
    this.allowClear = false,
  }) : super(key: key);

  @override
  State<PathStorageViewer> createState() => _PathStorageViewerState();
}

class _PathStorageViewerState extends State<PathStorageViewer> {
  Map<String, int> _logs;

  @override
  void initState() {
    directoryStat(widget.path).then((logs) {
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
    var pathVale = widget.path;
    if (pathVale.endsWith("/")) {
      pathVale = pathVale.substring(0, pathVale.length - 1);
    }
    int pathEle = pathVale.split("/").length;
    final title =
        pathVale.split("/")[pathEle - 2] + "/" + pathVale.split("/").last;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          MenuItemWidget(
            alignCaptionedTextToLeft: true,
            captionedTextWidget: CaptionedTextWidget(
              title: title,
              subTitle: '$fileCount - ${formatBytes(size)}',
            ),
            trailingIcon: widget.allowClear ? Icons.chevron_right : null,
            menuItemColor: getEnteColorScheme(context).fillFaint,
            onTap: () async {
              // await showPicker();
            },
          ),
          MenuSectionDescriptionWidget(content: widget.path)
        ],
      ),
    );
  }
}
