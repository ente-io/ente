import "dart:async";
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/collections/album/vertical_list.dart';
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
  addToHiddenAlbum,
  moveToHiddenCollection,
}

String _actionName(
  BuildContext context,
  CollectionActionType type,
  int fileCount,
) {
  String text = "";
  switch (type) {
    case CollectionActionType.addFiles:
      text = S.of(context).addItem(fileCount);
      break;
    case CollectionActionType.moveFiles:
      text = S.of(context).moveItem(fileCount);
      break;
    case CollectionActionType.restoreFiles:
      text = S.of(context).restoreToAlbum;
      break;
    case CollectionActionType.unHide:
      text = S.of(context).unhideToAlbum;
      break;
    case CollectionActionType.shareCollection:
      text = S.of(context).share;
      break;
    case CollectionActionType.addToHiddenAlbum:
      text = S.of(context).addToHiddenAlbum;
    case CollectionActionType.moveToHiddenCollection:
      text = S.of(context).moveToHiddenAlbum;
      break;
  }
  return text;
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
  late final bool _showOnlyHiddenCollections;
  static const int cancelButtonSize = 80;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _showOnlyHiddenCollections =
        widget.actionType == CollectionActionType.moveToHiddenCollection ||
            widget.actionType == CollectionActionType.addToHiddenAlbum;
  }

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
                            title: _actionName(
                              context,
                              widget.actionType,
                              filesCount,
                            ),
                          ),
                          caption: widget.showOptionToCreateNewAlbum
                              ? S.of(context).createOrSelectAlbum
                              : S.of(context).selectAlbum,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: TextInputWidget(
                            hintText: S.of(context).searchByAlbumNameHint,
                            prefixIcon: Icons.search_rounded,
                            onChange: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            isClearable: true,
                            shouldUnfocusOnClearOrSubmit: true,
                            borderRadius: 2,
                          ),
                        ),
                        _getCollectionItems(),
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
                      child: ButtonWidget(
                        buttonType: ButtonType.secondary,
                        buttonAction: ButtonAction.cancel,
                        isInAlert: true,
                        labelText: S.of(context).cancel,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Flexible _getCollectionItems() {
    return Flexible(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 4, 0),
        child: FutureBuilder<List<Collection>>(
          future: _getCollections(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              //Need to show an error on the UI here
              return const SizedBox.shrink();
            } else if (snapshot.hasData) {
              final collections = snapshot.data as List<Collection>;
              _removeIncomingCollections(collections);
              final shouldShowCreateAlbum =
                  widget.showOptionToCreateNewAlbum && _searchQuery.isEmpty;
              final searchResults = _searchQuery.isNotEmpty
                  ? collections
                      .where(
                        (element) => element.displayName
                            .toLowerCase()
                            .contains(_searchQuery),
                      )
                      .toList()
                  : collections;
              return Scrollbar(
                thumbVisibility: true,
                radius: const Radius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlbumVerticalListWidget(
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

  Future<List<Collection>> _getCollections() async {
    if (_showOnlyHiddenCollections) {
      final hiddenCollections = CollectionsService.instance
          .getHiddenCollections(includeDefaultHidden: false);
      hiddenCollections.sort((first, second) {
        return compareAsciiLowerCaseNatural(
          first.displayName,
          second.displayName,
        );
      });
      return hiddenCollections;
    } else {
      final List<Collection> collections =
          CollectionsService.instance.getCollectionsForUI(
        // in collections where user is a collaborator, only addTo and remove
        // action can to be performed
        includeCollab: widget.actionType == CollectionActionType.addFiles,
        includeUncategorized: true,
      );
      collections.sort((first, second) {
        return compareAsciiLowerCaseNatural(
          first.displayName,
          second.displayName,
        );
      });
      final List<Collection> pinned = [];
      final List<Collection> unpinned = [];
      // show uncategorized collection only for restore files action
      Collection? uncategorized;
      for (final collection in collections) {
        if (collection.isQuickLinkCollection() ||
            collection.type == CollectionType.favorites ||
            collection.type == CollectionType.uncategorized) {
          if (collection.type == CollectionType.uncategorized) {
            uncategorized = collection;
          }
          continue;
        }
        if (collection.isPinned) {
          pinned.add(collection);
        } else {
          unpinned.add(collection);
        }
      }
      return (uncategorized != null ? [uncategorized] + pinned + unpinned : []);
    }
  }

  void _removeIncomingCollections(List<Collection> items) {
    if (widget.actionType == CollectionActionType.shareCollection) {
      final ownerID = Configuration.instance.getUserID();
      items.removeWhere(
        (e) => !e.isOwner(ownerID!),
      );
    }
  }
}
