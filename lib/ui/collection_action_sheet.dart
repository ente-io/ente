import "dart:async";
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/core/configuration.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/collection_items.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/collections_list_widget.dart";
import 'package:photos/ui/common/loading_widget.dart';
import 'package:photos/ui/components/bottom_of_title_bar_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/text_input_widget.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum CollectionActionType {
  addFiles,
  moveFiles,
  restoreFiles,
  unHide,
  shareCollection,
  collectPhotos,
}

String _actionName(CollectionActionType type, bool plural) {
  bool addTitleSuffix = false;
  final titleSuffix = (plural ? "s" : "");
  String text = "";
  switch (type) {
    case CollectionActionType.addFiles:
      text = "Add item";
      addTitleSuffix = true;
      break;
    case CollectionActionType.moveFiles:
      text = "Move item";
      addTitleSuffix = true;
      break;
    case CollectionActionType.restoreFiles:
      text = "Restore to album";
      break;
    case CollectionActionType.unHide:
      text = "Unhide to album";
      break;
    case CollectionActionType.shareCollection:
      text = "Share";
      break;
    case CollectionActionType.collectPhotos:
      text = "Share";
      break;
  }
  return addTitleSuffix ? text + titleSuffix : text;
}

void showCollectionActionSheet(
  BuildContext context, {
  SelectedFiles? selectedFiles,
  List<SharedMediaFile>? sharedFiles,
  CollectionActionType actionType = CollectionActionType.addFiles,
  bool showOptionToCreateNewAlbum = true,
}) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return CollectionActionSheet(
        selectedFiles: selectedFiles,
        sharedFiles: sharedFiles,
        actionType: actionType,
        showOptionToCreateNewAlbum: showOptionToCreateNewAlbum,
      );
    },
    shape: const RoundedRectangleBorder(
      side: BorderSide(width: 0),
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(5),
      ),
    ),
    topControl: const SizedBox.shrink(),
    backgroundColor: getEnteColorScheme(context).backgroundElevated,
    barrierColor: backdropFaintDark,
    enableDrag: false,
  );
}

class CollectionActionSheet extends StatefulWidget {
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final CollectionActionType actionType;
  final bool showOptionToCreateNewAlbum;
  const CollectionActionSheet({
    required this.selectedFiles,
    required this.sharedFiles,
    required this.actionType,
    required this.showOptionToCreateNewAlbum,
    super.key,
  });

  @override
  State<CollectionActionSheet> createState() => _CollectionActionSheetState();
}

class _CollectionActionSheetState extends State<CollectionActionSheet> {
  static const int cancelButtonSize = 80;
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.sharedFiles != null
        ? widget.sharedFiles!.length
        : widget.selectedFiles?.files.length ?? 0;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardUp = bottomInset > 100;
    return Padding(
      padding: EdgeInsets.only(
        bottom: isKeyboardUp ? bottomInset - cancelButtonSize : 0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: min(428, MediaQuery.of(context).size.width),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 32, 0, 8),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        BottomOfTitleBarWidget(
                          title: TitleBarTitleWidget(
                            title:
                                _actionName(widget.actionType, filesCount > 1),
                          ),
                          caption: widget.showOptionToCreateNewAlbum
                              ? "Create or select album"
                              : "Select album",
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: TextInputWidget(
                            hintText: "Album name",
                            prefixIcon: Icons.search_rounded,
                            onChange: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            cancellable: true,
                            shouldUnfocusOnCancelOrSubmit: true,
                          ),
                        ),
                        _getCollectionItems(filesCount),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Container(
                      //inner stroke of 1pt + 15 pts of top padding = 16 pts
                      padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: getEnteColorScheme(context).strokeFaint,
                          ),
                        ),
                      ),
                      child: const ButtonWidget(
                        buttonType: ButtonType.secondary,
                        buttonAction: ButtonAction.cancel,
                        isInAlert: true,
                        labelText: "Cancel",
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Flexible _getCollectionItems(int filesCount) {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 0),
        child: FutureBuilder(
          future: _getCollectionsWithThumbnail(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              //Need to show an error on the UI here
              return const SizedBox.shrink();
            } else if (snapshot.hasData) {
              final collectionsWithThumbnail =
                  snapshot.data as List<CollectionWithThumbnail>;
              _removeIncomingCollections(collectionsWithThumbnail);
              final shouldShowCreateAlbum =
                  widget.showOptionToCreateNewAlbum && _searchQuery.isEmpty;
              final searchResults = _searchQuery.isNotEmpty
                  ? collectionsWithThumbnail
                      .where(
                        (element) => element.collection.name!
                            .toLowerCase()
                            .contains(_searchQuery),
                      )
                      .toList()
                  : collectionsWithThumbnail;
              return Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CollectionsListWidget(
                    searchResults,
                    widget.actionType,
                    widget.selectedFiles,
                    widget.sharedFiles,
                    _searchQuery,
                    shouldShowCreateAlbum,
                  ),
                ),
              );
            } else {
              return const EnteLoadingWidget();
            }
          },
        ),
      ),
    );
  }

  Future<List<CollectionWithThumbnail>> _getCollectionsWithThumbnail() async {
    final List<CollectionWithThumbnail> collectionsWithThumbnail =
        await CollectionsService.instance.getCollectionsWithThumbnails(
      // in collections where user is a collaborator, only addTo and remove
      // action can to be performed
      includeCollabCollections:
          widget.actionType == CollectionActionType.addFiles,
    );
    collectionsWithThumbnail.removeWhere(
      (element) => (element.collection.type == CollectionType.favorites ||
          element.collection.type == CollectionType.uncategorized ||
          element.collection.isSharedFilesCollection()),
    );
    collectionsWithThumbnail.sort((first, second) {
      return compareAsciiLowerCaseNatural(
        first.collection.name ?? "",
        second.collection.name ?? "",
      );
    });
    return collectionsWithThumbnail;
  }

  void _removeIncomingCollections(List<CollectionWithThumbnail> items) {
    if (widget.actionType == CollectionActionType.shareCollection ||
        widget.actionType == CollectionActionType.collectPhotos) {
      final ownerID = Configuration.instance.getUserID();
      items.removeWhere(
        (e) => !e.collection.isOwner(ownerID!),
      );
    }
  }
}
