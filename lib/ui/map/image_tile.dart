import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:photos/models/file.dart";
import "package:photos/models/file_load_result.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/navigation_util.dart";

class ImageTile extends StatelessWidget {
  final File image;
  final int index;
  final List<File> visibleImages;
  const ImageTile({
    super.key,
    required this.image,
    required this.index,
    required this.visibleImages,
  });

  void onTap(BuildContext context, File image, int index) {
    if (kDebugMode) {
      debugPrint('size of visibleImages: ${visibleImages.length}');
    }

    final page = DetailPage(
      DetailPageConfiguration(
        List.unmodifiable(visibleImages),
        (
          creationStartTime,
          creationEndTime, {
          limit,
          asc,
        }) async {
          final result = FileLoadResult(visibleImages, false);
          return result;
        },
        index,
        'Map',
      ),
    );

    routeToPage(
      context,
      page,
      forceCustomPageRoute: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(context, image, index),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(2, 0, 2, 4),
        child: SizedBox(
          width: 112,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: ThumbnailWidget(image),
          ),
        ),
      ),
    );
  }
}
