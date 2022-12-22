import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/captioned_text_widget.dart';
import 'package:photos/ui/components/menu_item_widget.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/directory_content.dart';

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
  final PathStorageItem item;
  final bool removeTopRadius;
  final bool removeBottomRadius;
  final bool enableDoubleTapClear;

  const PathStorageViewer(
    this.item, {
    this.removeTopRadius = false,
    this.removeBottomRadius = false,
    this.enableDoubleTapClear = false,
    Key? key,
  }) : super(key: key);

  @override
  State<PathStorageViewer> createState() => _PathStorageViewerState();
}

class _PathStorageViewerState extends State<PathStorageViewer> {
  Map<String, int>? _sizeAndFileCountInfo;

  @override
  void initState() {
    _initLogs();
    super.initState();
  }

  void _initLogs() {
    directoryStat(widget.item.path).then((logs) {
      setState(() {
        _sizeAndFileCountInfo = logs;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _getBody();
  }

  Widget _getBody() {
    if (_sizeAndFileCountInfo == null) {
      return const EnteLoadingWidget();
    }
    final int fileCount = _sizeAndFileCountInfo!["fileCount"] ?? -1;
    final int size = _sizeAndFileCountInfo!['size'] ?? 0;

    return MenuItemWidget(
      alignCaptionedTextToLeft: true,
      captionedTextWidget: CaptionedTextWidget(
        title: widget.item.title,
        subTitle: '$fileCount',
        subTitleColor: getEnteColorScheme(context).textFaint,
      ),
      trailingWidget: Text(
        formatBytes(size),
        style: getEnteTextTheme(context)
            .small
            .copyWith(color: getEnteColorScheme(context).textFaint),
      ),
      borderRadius: 8,
      menuItemColor: getEnteColorScheme(context).fillFaint,
      isBottomBorderRadiusRemoved: widget.removeBottomRadius,
      isTopBorderRadiusRemoved: widget.removeTopRadius,
      onTap: () async {
        if (kDebugMode) {
          await Clipboard.setData(ClipboardData(text: widget.item.path));
          debugPrint(widget.item.path);
        }
      },
      onDoubleTap: () async {
        if (widget.item.allowCacheClear && widget.enableDoubleTapClear) {
          await deleteDirectoryContents(widget.item.path);
          _initLogs();
        }
      },
    );
  }
}
