import 'package:flutter/material.dart';
import 'package:photos/models/file.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class FilenameResultWidget extends StatelessWidget {
  final File matchedFile;
  const FilenameResultWidget(this.matchedFile, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'File',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    matchedFile.title,
                    style: const TextStyle(fontSize: 18),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text('1 memory')
                ],
              ),
            ),
            Hero(
              tag: "fileDetails" + matchedFile.tag(),
              child: SizedBox(
                height: 50,
                width: 50,
                child: ThumbnailWidget(matchedFile),
              ),
            ),
          ],
        ),
      ),
      onTap: () {
        _routeToDetailPage(matchedFile, context);
      },
    );
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable([file]),
        null,
        0,
        "fileDetails",
      ),
    );
    routeToPage(context, page, forceCustomPageRoute: true);
  }
}
