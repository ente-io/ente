import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/collection/collection_items.dart";
import "package:photos/models/search/search_result.dart";
import "package:photos/models/typedefs.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/services/search_service.dart";
import "package:photos/ui/viewer/gallery/collection_page.dart";
import "package:photos/ui/viewer/location/add_location_sheet.dart";
import "package:photos/ui/viewer/location/pick_center_point_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/share_util.dart";

enum ResultType {
  collection,
  file,
  location,
  month,
  year,
  fileType,
  fileExtension,
  fileCaption,
  event,
  shared,
}

enum SectionType {
  face,
  location,
  // Grouping based on ML or manual tagging
  content,
  // includes year, month , day, event ResultType
  moment,
  // People section shows the files shared by other persons
  people,
  fileCaption,
  fileTypesAndExtension,
  album,
}

extension SectionTypeExtensions on SectionType {
  // passing context for internalization in the future
  String sectionTitle(BuildContext context) {
    switch (this) {
      case SectionType.face:
        return "Faces";
      case SectionType.content:
        return "Contents";
      case SectionType.moment:
        return S.of(context).moments;
      case SectionType.location:
        return S.of(context).location;
      case SectionType.people:
        return S.of(context).people;
      case SectionType.album:
        return S.of(context).albums;
      case SectionType.fileTypesAndExtension:
        return S.of(context).fileTypes;
      case SectionType.fileCaption:
        return S.of(context).photoDescriptions;
    }
  }

  // get int id to each section for ordering them
  int get orderID {
    switch (this) {
      case SectionType.face:
        return 0;
      case SectionType.content:
        return 1;
      case SectionType.moment:
        return 2;
      case SectionType.location:
        return 3;
      case SectionType.people:
        return 4;
      case SectionType.album:
        return 5;
      case SectionType.fileTypesAndExtension:
        return 6;
      case SectionType.fileCaption:
        return 7;
    }
  }

  String getEmptyStateText(BuildContext context) {
    switch (this) {
      case SectionType.face:
        return S.of(context).searchFaceEmptySection;
      case SectionType.content:
        return "Contents";
      case SectionType.moment:
        return S.of(context).searchDatesEmptySection;
      case SectionType.location:
        return S.of(context).searchLocationEmptySection;
      case SectionType.people:
        return S.of(context).searchPeopleEmptySection;
      case SectionType.album:
        return S.of(context).searchAlbumsEmptySection;
      case SectionType.fileTypesAndExtension:
        return S.of(context).searchFileTypesAndNamesEmptySection;
      case SectionType.fileCaption:
        return S.of(context).searchCaptionEmptySection;
    }
  }

  // isCTAVisible is used to show/hide the CTA button in the empty state
  // Disable the CTA for face, content, moment, fileTypesAndExtension, fileCaption
  bool get isCTAVisible {
    switch (this) {
      case SectionType.face:
        return false;
      case SectionType.content:
        return false;
      case SectionType.moment:
        return false;
      case SectionType.location:
        return true;
      case SectionType.people:
        return true;
      case SectionType.album:
        return true;
      case SectionType.fileTypesAndExtension:
        return false;
      case SectionType.fileCaption:
        return false;
    }
  }

  bool get isEmptyCTAVisible {
    switch (this) {
      case SectionType.face:
        return true;
      case SectionType.content:
        return false;
      case SectionType.moment:
        return false;
      case SectionType.location:
        return true;
      case SectionType.people:
        return true;
      case SectionType.album:
        return true;
      case SectionType.fileTypesAndExtension:
        return false;
      case SectionType.fileCaption:
        return false;
    }
  }

  String getCTAText(BuildContext context) {
    switch (this) {
      case SectionType.face:
        return "Setup";
      case SectionType.content:
        return "Add tags";
      case SectionType.moment:
        return "Add new";
      case SectionType.location:
        return "Add new";
      case SectionType.people:
        return "Invite";
      case SectionType.album:
        return "Add new";
      case SectionType.fileTypesAndExtension:
        return "";
      case SectionType.fileCaption:
        return "Add new";
    }
  }

  IconData? getCTAIcon() {
    switch (this) {
      case SectionType.face:
        return Icons.adaptive.arrow_forward_outlined;
      case SectionType.content:
        return null;
      case SectionType.moment:
        return null;
      case SectionType.location:
        return Icons.add_location_alt_outlined;
      case SectionType.people:
        return Icons.adaptive.share;
      case SectionType.album:
        return Icons.add;
      case SectionType.fileTypesAndExtension:
        return null;
      case SectionType.fileCaption:
        return null;
    }
  }

  FutureVoidCallback ctaOnTap(BuildContext context) {
    switch (this) {
      case SectionType.people:
        return () async {
          shareText(
            S.of(context).shareTextRecommendUsingEnte,
          );
        };
      case SectionType.location:
        return () async {
          final centerPoint = await showPickCenterPointSheet(context);
          if (centerPoint != null) {
            showAddLocationSheet(context, centerPoint);
          }
        };
      case SectionType.album:
        return () async {
          final result = await showTextInputDialog(
            context,
            title: S.of(context).newAlbum,
            submitButtonLabel: S.of(context).create,
            hintText: S.of(context).enterAlbumName,
            alwaysShowSuccessState: false,
            initialValue: "",
            textCapitalization: TextCapitalization.words,
            onSubmit: (String text) async {
              // indicates user cancelled the rename request
              if (text.trim() == "") {
                return;
              }
              try {
                final Collection c =
                    await CollectionsService.instance.createAlbum(text);
                routeToPage(
                  context,
                  CollectionPage(CollectionWithThumbnail(c, null)),
                );
              } catch (e, s) {
                Logger("CreateNewAlbumIcon")
                    .severe("Failed to create a new album", e, s);
                rethrow;
              }
            },
          );
          if (result is Exception) {
            showGenericErrorDialog(context: context);
          }
        };
      default:
        {
          return () async {};
        }
    }
  }

  Future<List<SearchResult>> getData({int? limit, BuildContext? context}) {
    if (this == SectionType.moment && context == null) {
      AssertionError("context cannot be null for SectionType.moment");
    }
    switch (this) {
      case SectionType.face:
        return SearchService.instance.getAllLocationTags(limit);

      case SectionType.content:
        return SearchService.instance.getAllLocationTags(limit);

      case SectionType.moment:
        return SearchService.instance.getRandomMomentsSearchResults(context!);

      case SectionType.location:
        return SearchService.instance.getAllLocationTags(limit);

      case SectionType.people:
        return SearchService.instance.getPeopleSearchResults(limit);

      case SectionType.album:
        return SearchService.instance.getAllCollectionSearchResults(limit);

      case SectionType.fileTypesAndExtension:
        return SearchService.instance
            .getAllFileTypesAndExtensionsResults(limit);

      case SectionType.fileCaption:
        return SearchService.instance.getAllDescriptionSearchResults(limit);
    }
  }
}
