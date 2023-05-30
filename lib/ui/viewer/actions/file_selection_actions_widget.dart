import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file.dart';
import "package:photos/models/file_type.dart";
import 'package:photos/models/files_split.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/actions/collection/collection_file_actions.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/collection_action_sheet.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/blur_menu_item_widget.dart';
import 'package:photos/ui/components/bottom_action_bar/expanded_menu_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/sharing/manage_links_widget.dart';
import "package:photos/ui/tools/collage/collage_creator_page.dart";
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

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
  late FilesSplit split;
  late CollectionActions collectionActions;
  late bool isCollectionOwner;

  // _cachedCollectionForSharedLink is primarily used to avoid creating duplicate
  // links if user keeps on creating Create link button after selecting
  // few files. This link is reset on any selection changed;
  Collection? _cachedCollectionForSharedLink;

  @override
  void initState() {
    currentUserID = Configuration.instance.getUserID()!;
    split = FilesSplit.split(<File>[], currentUserID);
    widget.selectedFiles.addListener(_selectFileChangeListener);
    collectionActions = CollectionActions(CollectionsService.instance);
    isCollectionOwner =
        widget.collection != null && widget.collection!.isOwner(currentUserID);
    super.initState();
  }

  @override
  void dispose() {
    widget.selectedFiles.removeListener(_selectFileChangeListener);
    super.dispose();
  }

  void _selectFileChangeListener() {
    if (_cachedCollectionForSharedLink != null) {
      _cachedCollectionForSharedLink = null;
    }
    split = FilesSplit.split(widget.selectedFiles.files, currentUserID);
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
    final int removeCount = split.ownedByCurrentUser.length +
        (isCollectionOwner ? split.ownedByOtherUsers.length : 0);
    final String removeSuffix = showPrefix
        ? " ($removeCount)"
            ""
        : "";
    final String suffixInPending = split.ownedByOtherUsers.isNotEmpty
        ? " (${split.ownedByCurrentUser.length + split.pendingUploads.length})"
            ""
        : "";

    final bool anyOwnedFiles =
        split.pendingUploads.isNotEmpty || split.ownedByCurrentUser.isNotEmpty;
    final bool anyUploadedFiles = split.ownedByCurrentUser.isNotEmpty;
    final bool showRemoveOption = widget.type.showRemoveFromAlbum();
    debugPrint('$runtimeType building  $mounted');
    final colorScheme = getEnteColorScheme(context);
    final List<List<BlurMenuItemWidget>> items = [];
    final List<BlurMenuItemWidget> firstList = [];
    final List<BlurMenuItemWidget> secondList = [];

    if (widget.type.showCreateLink()) {
      if (_cachedCollectionForSharedLink != null && anyUploadedFiles) {
        firstList.add(
          BlurMenuItemWidget(
            leadingIcon: Icons.copy_outlined,
            labelText: S.of(context).copyLink,
            menuItemColor: colorScheme.fillFaint,
            onTap: anyUploadedFiles ? _copyLink : null,
          ),
        );
      } else {
        firstList.add(
          BlurMenuItemWidget(
            leadingIcon: Icons.link_outlined,
            labelText: S.of(context).shareLink + suffix,
            menuItemColor: colorScheme.fillFaint,
            onTap: anyUploadedFiles ? _onCreatedSharedLinkClicked : null,
          ),
        );
      }
    }

    bool hasVideoFile = false;
    for (final file in widget.selectedFiles.files) {
      if (file.fileType == FileType.video) {
        hasVideoFile = true;
      }
    }

    if (!hasVideoFile &&
        widget.selectedFiles.files.length >=
            CollageCreatorPage.collageItemsMin &&
        widget.selectedFiles.files.length <=
            CollageCreatorPage.collageItemsMax) {
      firstList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.grid_view_outlined,
          labelText: S.of(context).createCollage,
          menuItemColor: colorScheme.fillFaint,
          onTap: _onCreateCollageClicked,
        ),
      );
    }

    final showUploadIcon = widget.type == GalleryType.localFolder &&
        split.ownedByCurrentUser.isEmpty;
    if (widget.type.showAddToAlbum()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon:
              showUploadIcon ? Icons.cloud_upload_outlined : Icons.add_outlined,
          labelText: showUploadIcon
              ? S.of(context).addToEnte
              : S.of(context).addToAlbum + suffixInPending,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyOwnedFiles ? _addToAlbum : null,
        ),
      );
    }
    if (widget.type.showMoveToAlbum()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.arrow_forward_outlined,
          labelText: S.of(context).moveToAlbum + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _moveFiles : null,
        ),
      );
    }

    if (showRemoveOption) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.remove_outlined,
          labelText: "${S.of(context).removeFromAlbum}$removeSuffix",
          menuItemColor: colorScheme.fillFaint,
          onTap: removeCount > 0 ? _removeFilesFromAlbum : null,
        ),
      );
    }

    if (widget.type.showDeleteOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.delete_outline,
          labelText: S.of(context).delete + suffixInPending,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyOwnedFiles ? _onDeleteClick : null,
        ),
      );
    }

    if (widget.type.showHideOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.visibility_off_outlined,
          labelText: S.of(context).hide + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onHideClick : null,
        ),
      );
    } else if (widget.type.showUnHideOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.visibility_off_outlined,
          labelText: S.of(context).unhide + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnhideClick,
        ),
      );
    }
    if (widget.type.showArchiveOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.archive_outlined,
          labelText: S.of(context).archive + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onArchiveClick : null,
        ),
      );
    } else if (widget.type.showUnArchiveOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.unarchive,
          labelText: S.of(context).unarchive + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnArchiveClick,
        ),
      );
    }

    if (widget.type.showFavoriteOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.favorite_border_rounded,
          labelText: S.of(context).favorite + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: anyUploadedFiles ? _onFavoriteClick : null,
        ),
      );
    } else if (widget.type.showUnFavoriteOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.favorite,
          labelText: S.of(context).removeFromFavorite + suffix,
          menuItemColor: colorScheme.fillFaint,
          onTap: _onUnFavoriteClick,
        ),
      );
    }

    if (widget.type.showRestoreOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.restore_outlined,
          labelText: S.of(context).restore,
          menuItemColor: colorScheme.fillFaint,
          onTap: _restore,
        ),
      );
    }

    if (widget.type.showPermanentlyDeleteOption()) {
      secondList.add(
        BlurMenuItemWidget(
          leadingIcon: Icons.delete_forever_outlined,
          labelText: S.of(context).permanentlyDelete,
          menuItemColor: colorScheme.fillFaint,
          onTap: _permanentlyDelete,
        ),
      );
    }

    if (firstList.isNotEmpty || secondList.isNotEmpty) {
      if (firstList.isNotEmpty) {
        items.add(firstList);
      }
      items.add(secondList);
      return ExpandedMenuWidget(
        items: items,
      );
    } else {
      // TODO: Return "Select All" here
      return const SizedBox.shrink();
    }
  }

  Future<void> _moveFiles() async {
    if (split.pendingUploads.isNotEmpty || split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    showCollectionActionSheet(
      context,
      selectedFiles: widget.selectedFiles,
      actionType: CollectionActionType.moveFiles,
    );
  }

  Future<void> _addToAlbum() async {
    if (split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    showCollectionActionSheet(context, selectedFiles: widget.selectedFiles);
  }

  Future<void> _onDeleteClick() async {
    return showDeleteSheet(context, widget.selectedFiles);
  }

  Future<void> _removeFilesFromAlbum() async {
    if (split.pendingUploads.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
    }
    if (!isCollectionOwner && split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    final bool removingOthersFile =
        isCollectionOwner && split.ownedByOtherUsers.isNotEmpty;
    await collectionActions.showRemoveFromCollectionSheetV2(
      context,
      widget.collection!,
      widget.selectedFiles,
      removingOthersFile,
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
      archiveVisibility,
    );
    widget.selectedFiles.clearAll();
  }

  Future<void> _onUnArchiveClick() async {
    await changeVisibility(
      context,
      split.ownedByCurrentUser,
      visibleVisibility,
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
    showCollectionActionSheet(
      context,
      selectedFiles: widget.selectedFiles,
      actionType: CollectionActionType.unHide,
    );
  }

  Future<void> _onCreateCollageClicked() async {
    final bool? result = await routeToPage(
      context,
      CollageCreatorPage(widget.selectedFiles.files),
    );
    if (result != null && result) {
      widget.selectedFiles.clearAll();
    }
  }

  Future<void> _onCreatedSharedLinkClicked() async {
    if (split.ownedByCurrentUser.isEmpty) {
      showShortToast(
        context,
        S.of(context).canOnlyCreateLinkForFilesOwnedByYou,
      );
      return;
    }
    _cachedCollectionForSharedLink ??= await collectionActions
        .createSharedCollectionLink(context, split.ownedByCurrentUser);
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: S.of(context).copyLink,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: S.of(context).manageLink,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: S.of(context).done,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.third,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        )
      ],
      title: S.of(context).publicLinkCreated,
      body: S.of(context).youCanManageYourLinksInTheShareTab,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    if (actionResult?.action != null) {
      if (actionResult!.action == ButtonAction.first) {
        await _copyLink();
      }
      if (actionResult.action == ButtonAction.second) {
        routeToPage(
          context,
          ManageSharedLinkWidget(collection: _cachedCollectionForSharedLink),
        );
      }
    }

    if (mounted) {
      setState(() => {});
    }
  }

  Future<void> _copyLink() async {
    if (_cachedCollectionForSharedLink != null) {
      final String collectionKey = Base58Encode(
        CollectionsService.instance
            .getCollectionKey(_cachedCollectionForSharedLink!.id),
      );
      final String url =
          "${_cachedCollectionForSharedLink!.publicURLs?.first?.url}#$collectionKey";
      await Clipboard.setData(ClipboardData(text: url));
      showShortToast(context, S.of(context).linkCopiedToClipboard);
    }
  }

  void _restore() {
    showCollectionActionSheet(
      context,
      selectedFiles: widget.selectedFiles,
      actionType: CollectionActionType.restoreFiles,
    );
  }

  Future<void> _permanentlyDelete() async {
    if (await deleteFromTrash(
      context,
      widget.selectedFiles.files,
    )) {
      widget.selectedFiles.clearAll();
    }
  }
}
