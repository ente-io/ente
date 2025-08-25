import "dart:async";
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/create_new_album_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/actions/collection/collection_file_actions.dart";
import "package:photos/ui/actions/collection/collection_sharing_actions.dart";
import 'package:photos/ui/collections/album/vertical_list.dart';
import 'package:photos/ui/common/loading_widget.dart';
import "package:photos/ui/common/progress_dialog.dart";
import 'package:photos/ui/components/bottom_of_title_bar_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/components/text_input_widget.dart";
import 'package:photos/ui/components/title_bar_title_widget.dart';
import "package:photos/ui/notification/toast.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/separators_util.dart";
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

enum CollectionActionType {
  addFiles,
  moveFiles,
  restoreFiles,
  unHide,
  shareCollection,
  addToHiddenAlbum,
  moveToHiddenCollection,
  autoAddPeople;
}

extension CollectionActionTypeExtension on CollectionActionType {
  bool get isHiddenAction =>
      this == CollectionActionType.moveToHiddenCollection ||
      this == CollectionActionType.addToHiddenAlbum;
}

String _actionName(
  BuildContext context,
  CollectionActionType type,
  int fileCount,
) {
  String text = "";
  switch (type) {
    case CollectionActionType.addFiles:
      text = AppLocalizations.of(context).addItem(count: fileCount);
      break;
    case CollectionActionType.moveFiles:
      text = AppLocalizations.of(context).moveItem(count: fileCount);
      break;
    case CollectionActionType.restoreFiles:
      text = AppLocalizations.of(context).restoreToAlbum;
      break;
    case CollectionActionType.unHide:
      text = AppLocalizations.of(context).unhideToAlbum;
      break;
    case CollectionActionType.shareCollection:
      text = AppLocalizations.of(context).share;
      break;
    case CollectionActionType.addToHiddenAlbum:
      text = AppLocalizations.of(context).addToHiddenAlbum;
      break;
    case CollectionActionType.moveToHiddenCollection:
      text = AppLocalizations.of(context).moveToHiddenAlbum;
      break;
    case CollectionActionType.autoAddPeople:
      text = AppLocalizations.of(context).autoAddToAlbum;
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
  List<String>? selectedPeople,
}) {
  showBarModalBottomSheet(
    context: context,
    builder: (context) {
      return CollectionActionSheet(
        selectedFiles: selectedFiles,
        sharedFiles: sharedFiles,
        actionType: actionType,
        showOptionToCreateNewAlbum: showOptionToCreateNewAlbum,
        selectedPeople: selectedPeople,
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
    enableDrag: true,
  );
}

class CollectionActionSheet extends StatefulWidget {
  final SelectedFiles? selectedFiles;
  final List<SharedMediaFile>? sharedFiles;
  final List<String>? selectedPeople;
  final CollectionActionType actionType;
  final bool showOptionToCreateNewAlbum;
  const CollectionActionSheet({
    required this.selectedFiles,
    required this.sharedFiles,
    required this.actionType,
    required this.showOptionToCreateNewAlbum,
    this.selectedPeople,
    super.key,
  });

  @override
  State<CollectionActionSheet> createState() => _CollectionActionSheetState();
}

class _CollectionActionSheetState extends State<CollectionActionSheet> {
  late final bool _showOnlyHiddenCollections;
  late final bool _enableSelection;
  static const int okButtonSize = 80;
  String _searchQuery = "";
  final _selectedCollections = <Collection>[];
  final _recentlyCreatedCollections = <Collection>[];
  late StreamSubscription<CreateNewAlbumEvent> _createNewAlbumSubscription;
  final _logger = Logger("CollectionActionSheet");

  @override
  void initState() {
    super.initState();
    _showOnlyHiddenCollections = widget.actionType.isHiddenAction;
    _enableSelection = (widget.actionType ==
                CollectionActionType.autoAddPeople &&
            widget.selectedPeople != null) ||
        ((widget.actionType == CollectionActionType.addFiles ||
                widget.actionType == CollectionActionType.addToHiddenAlbum) &&
            (widget.sharedFiles == null || widget.sharedFiles!.isEmpty));
    _createNewAlbumSubscription =
        Bus.instance.on<CreateNewAlbumEvent>().listen((event) {
      setState(() {
        _recentlyCreatedCollections.insert(0, event.collection);
        _selectedCollections.add(event.collection);
      });
    });
  }

  @override
  void dispose() {
    _createNewAlbumSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filesCount = widget.sharedFiles != null
        ? widget.sharedFiles!.length
        : widget.selectedPeople != null
            ? widget.selectedPeople!.length
            : widget.selectedFiles?.files.length ?? 0;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardUp = bottomInset > 100;
    final double bottomPadding =
        max(0, bottomInset - (_enableSelection ? okButtonSize : 0));
    return Padding(
      padding: EdgeInsets.only(
        bottom: isKeyboardUp ? bottomPadding : 0,
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
                              ? AppLocalizations.of(context).createOrSelectAlbum
                              : AppLocalizations.of(context).selectAlbum,
                          showCloseButton: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                          ),
                          child: TextInputWidget(
                            hintText: AppLocalizations.of(context)
                                .searchByAlbumNameHint,
                            prefixIcon: Icons.search_rounded,
                            onChange: (value) {
                              setState(() {
                                _searchQuery = value.trim();
                              });
                            },
                            isClearable: true,
                            shouldUnfocusOnClearOrSubmit: true,
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
                            color: _enableSelection
                                ? getEnteColorScheme(context).strokeFaint
                                : Colors.transparent,
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          ..._actionButtons(),
                        ],
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

  List<Widget> _actionButtons() {
    final List<Widget> widgets = [];
    if (_enableSelection) {
      widgets.add(
        ButtonWidget(
          key: const ValueKey('add_button'),
          buttonType: ButtonType.primary,
          isInAlert: true,
          labelText: AppLocalizations.of(context).add,
          shouldSurfaceExecutionStates: false,
          isDisabled: _selectedCollections.isEmpty,
          onTap: () async {
            if (widget.selectedPeople != null) {
              final ProgressDialog? dialog = createProgressDialog(
                context,
                AppLocalizations.of(context).uploadingFilesToAlbum,
                isDismissible: true,
              );
              await dialog?.show();
              for (final collection in _selectedCollections) {
                try {
                  await smartAlbumsService.addPeopleToSmartAlbum(
                    collection.id,
                    widget.selectedPeople!,
                  );
                } catch (error, stackTrace) {
                  _logger.severe(
                    "Error while adding people to smart album",
                    error,
                    stackTrace,
                  );
                }
              }
              unawaited(smartAlbumsService.syncSmartAlbums());
              await dialog?.hide();
              return;
            }
            final CollectionActions collectionActions =
                CollectionActions(CollectionsService.instance);
            final result = await collectionActions.addToMultipleCollections(
              context,
              _selectedCollections,
              true,
              selectedFiles: widget.selectedFiles?.files.toList(),
            );
            if (result) {
              showShortToast(
                context,
                AppLocalizations.of(context)
                    .addedToAlbums(count: _selectedCollections.length),
              );
              widget.selectedFiles?.clearAll();
            }
          },
        ),
      );
    }
    final widgetsWithSpaceBetween = addSeparators(
      widgets,
      const SizedBox(height: 8),
    );
    return widgetsWithSpaceBetween;
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
                interactive: true,
                radius: const Radius.circular(2),
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AlbumVerticalListWidget(
                    searchResults,
                    widget.actionType,
                    widget.selectedFiles,
                    widget.sharedFiles,
                    widget.selectedPeople,
                    _searchQuery,
                    shouldShowCreateAlbum,
                    enableSelection: _enableSelection,
                    selectedCollections: _selectedCollections,
                    onSelectionChanged: () {
                      setState(() {});
                    },
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
      final List<Collection> recentlyCreated = [];
      final List<Collection> hidden = [];

      final hiddenCollections = CollectionsService.instance
          .getHiddenCollections(includeDefaultHidden: false);
      for (final collection in hiddenCollections) {
        if (_recentlyCreatedCollections.contains(collection)) {
          recentlyCreated.add(collection);
        } else {
          hidden.add(collection);
        }
      }
      hidden.sort((first, second) {
        return compareAsciiLowerCaseNatural(
          first.displayName,
          second.displayName,
        );
      });
      return recentlyCreated + hidden;
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
      final List<Collection> recentlyCreated = [];
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
        if (_recentlyCreatedCollections.contains(collection)) {
          recentlyCreated.add(collection);
          continue;
        }
        if (collection.isPinned) {
          pinned.add(collection);
        } else {
          unpinned.add(collection);
        }
      }

      return uncategorized != null
          ? [uncategorized] + recentlyCreated + pinned + unpinned
          : recentlyCreated + pinned + unpinned;
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
