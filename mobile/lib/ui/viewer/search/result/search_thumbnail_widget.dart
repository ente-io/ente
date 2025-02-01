import "package:flutter/material.dart";
import "package:logging/logging.dart";
import 'package:photos/models/file/file.dart';
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/search_constants.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/search/search_types.dart";
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
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
    super.key,
  });

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

class ContactSearchThumbnailWidget extends StatefulWidget {
  final GenericSearchResult searchResult;
  final String tagPrefix;
  const ContactSearchThumbnailWidget(
    this.tagPrefix, {
    required this.searchResult,
    super.key,
  });

  @override
  State<ContactSearchThumbnailWidget> createState() =>
      _ContactSearchThumbnailWidgetState();
}

class _ContactSearchThumbnailWidgetState
    extends State<ContactSearchThumbnailWidget> {
  Future<EnteFile?>? _mostRecentFileOfPerson;
  late String? _personID;
  final _logger = Logger("_ContactSearchThumbnailWidgetState");
  late final EnteFile? _previewThumbnail;

  @override
  void initState() {
    super.initState();
    _previewThumbnail = widget.searchResult.previewThumbnail();
    _personID = widget.searchResult.params[kPersonParamID];
    if (_personID != null) {
      _mostRecentFileOfPerson =
          PersonService.instance.getPerson(_personID!).then((person) {
        if (person == null) {
          return null;
        } else {
          return PersonService.instance.getRecentFileOfPerson(person);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 60,
      child: ClipRRect(
        borderRadius: const BorderRadius.horizontal(left: Radius.circular(4)),
        child: _mostRecentFileOfPerson != null
            ? FutureBuilder(
                future: _mostRecentFileOfPerson,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return PersonFaceWidget(
                      snapshot.data!,
                      personId: _personID,
                    );
                  } else if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.data == null) {
                    return _previewThumbnail != null
                        ? ThumbnailWidget(
                            _previewThumbnail!,
                          )
                        : const NoFaceOrFileContactWidget();
                  } else if (snapshot.hasError) {
                    _logger.severe(
                      "Error loading personID",
                      snapshot.error,
                    );
                    return const NoFaceOrFileContactWidget();
                  } else {
                    return const EnteLoadingWidget();
                  }
                },
              )
            : _previewThumbnail != null
                ? ThumbnailWidget(
                    _previewThumbnail!,
                  )
                : const NoFaceOrFileContactWidget(),
      ),
    );
  }
}

class NoFaceOrFileContactWidget extends StatelessWidget {
  final bool addBorder;
  const NoFaceOrFileContactWidget({this.addBorder = true, super.key});

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(1),
        border: addBorder
            ? Border.all(
                color: enteColorScheme.strokeFaint,
                width: 1,
              )
            : null,
        color: enteColorScheme.fillFaint,
      ),
      child: Center(
        child: Icon(
          Icons.person_2_outlined,
          color: enteColorScheme.strokeMuted,
          size: 24,
        ),
      ),
    );
  }
}
