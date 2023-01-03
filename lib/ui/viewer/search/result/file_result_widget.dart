

import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/models/file.dart';
import 'package:photos/models/search/file_search_result.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/search/result/search_thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class FileSearchResultWidget extends StatelessWidget {
  final FileSearchResult matchedFile;

  const FileSearchResultWidget(this.matchedFile, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: Theme.of(context).colorScheme.searchResultsColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SearchThumbnailWidget(
                matchedFile.file,
                "file_details",
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'File',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.subTextColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 220,
                    child: Text(
                      matchedFile.file.title!,
                      style: const TextStyle(fontSize: 18),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.subTextColor,
              ),
            ],
          ),
        ),
      ),
      onTap: () {
        _routeToDetailPage(matchedFile.file, context);
      },
    );
  }

  void _routeToDetailPage(File file, BuildContext context) {
    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable([file]),
        null,
        0,
        "file_details",
      ),
    );
    routeToPage(context, page);
  }
}
