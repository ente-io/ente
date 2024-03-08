import 'package:flutter/widgets.dart';
import 'package:photos/models/file/file.dart';
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import 'package:photos/ui/viewer/file/no_thumbnail_widget.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/ui/viewer/search/result/person_face_widget.dart';

class SearchThumbnailWidget extends StatelessWidget {
  final EnteFile? file;
  final SearchResult? searchResult;
  final String tagPrefix;

  const SearchThumbnailWidget(
    this.file,
    this.tagPrefix, {
    this.searchResult,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tagPrefix + (file?.tag ?? ""),
      child: SizedBox(
        height: 60,
        width: 60,
        child: ClipRRect(
          borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
          child: file != null
              ? (searchResult != null &&
                      searchResult!.type() == ResultType.faces)
                  ? PersonFaceWidget(
                      file!,
                      personId: (searchResult as GenericSearchResult)
                          .params[kPersonParamID],
                      clusterID: (searchResult as GenericSearchResult)
                          .params[kClusterParamId],
                    )
                  : ThumbnailWidget(
                      file!,
                    )
              : const NoThumbnailWidget(
                  addBorder: false,
                ),
        ),
      ),
    );
  }
}
