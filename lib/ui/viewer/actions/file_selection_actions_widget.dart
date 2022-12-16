import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_file_breakup.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_file_actions.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/components/blur_menu_item_widget.dart';
import 'package:photos/ui/components/bottom_action_bar/expanded_menu_widget.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';

class FileSelectionActionWidget extends StatefulWidget {
  final GalleryType type;
  final Collection? collection;
  final DeviceCollection? deviceCollection;
  final SelectedFiles selectedFiles;

  const FileSelectionActionWidget(
    this.type,
    this.selectedFiles, {
    Key? key,
    this.collection,
    this.deviceCollection,
  }) : super(key: key);

  @override
  State<FileSelectionActionWidget> createState() =>
      _FileSelectionActionWidgetState();
}

class _FileSelectionActionWidgetState extends State<FileSelectionActionWidget> {
  late int currentUserID;
  late SelectedFileSplit split;
  late CollectionActions collectionActions;

  @override
  void initState() {
    currentUserID = Configuration.instance.getUserID()!;
    split = widget.selectedFiles.split(currentUserID);
    widget.selectedFiles.addListener(_selectFileChangeListener);
    collectionActions = CollectionActions(CollectionsService.instance);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_selectFileChangeListener);
    super.dispose();
  }

  void _selectFileChangeListener() {
    split = widget.selectedFiles.split(currentUserID);
    if (mounted) {
      setState(() => {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showPrefix =
        split.pendingUploads.isNotEmpty || split.ownedByOtherUsers.isNotEmpty;
    final String suffix = showPrefix
        ? " (${split.ownedByCurrentUser.length})"
            ""
        : "";
    final String suffixInPending = showPrefix
        ? " (${split.ownedByCurrentUser.length + split.pendingUploads.length})"
            ""
        : "";
    final bool anyOwnedFiles =
        split.pendingUploads.isNotEmpty || split.ownedByCurrentUser.isNotEmpty;
    final bool anyUploadedFiles = split.ownedByCurrentUser.isNotEmpty;
    debugPrint('$runtimeType building  $mounted');
    final colorScheme = getEnteColorScheme(context);
    final List<List<BlurMenuItemWidget>> items = [];
    final List<BlurMenuItemWidget> firstList = [];
    if (widget.type.showAddToAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.add_outlined,
          labelText: "Add to album$suffixInPending",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyOwnedFiles ? _addToAlbum : null,
        ),
      );
    }
    if (widget.type.showMoveToAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.arrow_forward_outlined,
          labelText: "Move to album$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _moveFiles : null,
        ),
      );
    }

    if (widget.type.showRemoveFromAlbum()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.remove_outlined,
          labelText: "Remove from album$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _removeFilesFromAlbum : null,
        ),
      );
    }

    if (widget.type.showDeleteOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.delete_outline,
          labelText: "Delete$suffixInPending",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyOwnedFiles ? _onDeleteClick : null,
        ),
      );
    }

    if (widget.type.showHideOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.visibility_off_outlined,
          labelText: "Hide$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onHideClick : null,
        ),
      );
    } else if (widget.type.showUnHideOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.visibility_off_outlined,
          labelText: "Unhide$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnhideClick,
        ),
      );
    }
    if (widget.type.showArchiveOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.archive_outlined,
          labelText: "Archive$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onArchiveClick : null,
        ),
      );
    } else if (widget.type.showUnArchiveOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.unarchive,
          labelText: "Unarchive$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnArchiveClick,
        ),
      );
    }

    if (widget.type.showFavoriteOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.favorite_border_rounded,
          labelText: "Favorite$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onFavoriteClick : null,
        ),
      );
    } else if (widget.type.showUnFavoriteOption()) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.favorite,
          labelText: "Remove from favorite$suffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnFavoriteClick,
        ),
      );
    }

    if (firstList.isNotEmpty) {
      items.add(firstList);
    }
    return ExpandedMenuWidget(
      items: items,
    );
  }

  Future<void> _moveFiles() async {
    if (split.pendingUploads.isNotEmpty || split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    await _selectionCollectionForAction(CollectionActionType.moveFiles);
  }

  Future<void> _addToAlbum() async {
    if (split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    await _selectionCollectionForAction(CollectionActionType.addFiles);
  }

  Future<void> _onDeleteClick() async {
    showDeleteSheet(context, widget.selectedFiles);
  }

  Future<void> _removeFilesFromAlbum() async {
    if (split.pendingUploads.isNotEmpty || split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    await collectionActions.showRemoveFromCollectionSheet(
      context,
      widget.collection!,
      widget.selectedFiles,
    );
  }

  Future<void> _onFavoriteClick() async {
    final result = await collectionActions.updateFavorites(
      context,
      split.ownedByCurrentUser,
      true,
    );
    if (result) {
      widget.selectedFiles.clearAll();
    }
  }

  Future<void> _onUnFavoriteClick() async {
    final result = await collectionActions.updateFavorites(
      context,
      split.ownedByCurrentUser,
      false,
    );
    if (result) {
      widget.selectedFiles.clearAll();
    }
  }

  Future<void> _onArchiveClick() async {
    await changeVisibility(
      context,
      split.ownedByCurrentUser,
      visibilityArchive,
    );
    widget.selectedFiles.clearAll();
  }

  Future<void> _onUnArchiveClick() async {
    await changeVisibility(
      context,
      split.ownedByCurrentUser,
      visibilityVisible,
    );
    widget.selectedFiles.clearAll();
  }

  Future<void> _onHideClick() async {
    await CollectionsService.instance.hideFiles(
      context,
      split.ownedByCurrentUser,
    );
    widget.selectedFiles.clearAll();
  }

  Future<void> _onUnhideClick() async {
    if (split.pendingUploads.isNotEmpty || split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    await _selectionCollectionForAction(CollectionActionType.unHide);
  }

  Future<Object?> _selectionCollectionForAction(
    CollectionActionType type,
  ) async {
    return Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        child: CreateCollectionPage(
          widget.selectedFiles,
          null,
          actionType: type,
        ),
      ),
    );
  }
}
