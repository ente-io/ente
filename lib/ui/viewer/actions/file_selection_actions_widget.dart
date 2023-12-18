import "dart:async";

import 'package:fast_base58/fast_base58.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/files_split.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/actions/collection/collection_file_actions.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/sharing/manage_links_widget.dart';
import "package:photos/ui/tools/collage/collage_creator_page.dart";
import "package:photos/ui/viewer/location/update_location_data_widget.dart";
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/share_util.dart";
import 'package:photos/utils/toast_util.dart';

class FileSelectionActionsWidget extends StatefulWidget {
  final GalleryType type;
  final Collection? collection;
  final DeviceCollection? deviceCollection;
  final SelectedFiles selectedFiles;

  const FileSelectionActionsWidget(
    this.type,
    this.selectedFiles, {
    Key? key,
    this.collection,
    this.deviceCollection,
  }) : super(key: key);

  @override
  State<FileSelectionActionsWidget> createState() =>
      _FileSelectionActionsWidgetState();
}

class _FileSelectionActionsWidgetState
    extends State<FileSelectionActionsWidget> {
  late int currentUserID;
  late FilesSplit split;
  late CollectionActions collectionActions;
  late bool isCollectionOwner;

  // _cachedCollectionForSharedLink is primarily used to avoid creating duplicate
  // links if user keeps on creating Create link button after selecting
  // few files. This link is reset on any selection changed;
  Collection? _cachedCollectionForSharedLink;
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  void initState() {
    currentUserID = Configuration.instance.getUserID()!;
    split = FilesSplit.split(<EnteFile>[], currentUserID);
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
    final ownedFilesCount = split.ownedByCurrentUser.length;
    final ownedAndPendingUploadFilesCount =
        ownedFilesCount + split.pendingUploads.length;
    final int removeCount = split.ownedByCurrentUser.length +
        (isCollectionOwner ? split.ownedByOtherUsers.length : 0);

    final bool anyOwnedFiles =
        split.pendingUploads.isNotEmpty || split.ownedByCurrentUser.isNotEmpty;

    final bool anyUploadedFiles = split.ownedByCurrentUser.isNotEmpty;
    final showCollageOption = CollageCreatorPage.isValidCount(
          widget.selectedFiles.files.length,
        ) &&
        !widget.selectedFiles.files.any(
          (element) => element.fileType == FileType.video,
        );

    //To animate adding and removing of [SelectedActionButton], add all items
    //and set [shouldShow] to false for items that should not be shown and true
    //for items that should be shown.
    final List<SelectionActionButton> items = [];

    if (widget.type.showCreateLink()) {
      if (_cachedCollectionForSharedLink != null && anyUploadedFiles) {
        items.add(
          SelectionActionButton(
            icon: Icons.copy_outlined,
            labelText: S.of(context).copyLink,
            onTap: anyUploadedFiles ? _copyLink : null,
          ),
        );
      } else {
        items.add(
          SelectionActionButton(
            icon: Icons.link_outlined,
            labelText: S.of(context).shareLink,
            onTap: anyUploadedFiles ? _onCreatedSharedLinkClicked : null,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      }
    }

    final showUploadIcon = widget.type == GalleryType.localFolder &&
        split.ownedByCurrentUser.isEmpty;
    if (widget.type.showAddToAlbum()) {
      if (showUploadIcon) {
        items.add(
          SelectionActionButton(
            icon: Icons.cloud_upload_outlined,
            labelText: S.of(context).addToEnte,
            onTap: anyOwnedFiles ? _addToAlbum : null,
          ),
        );
      } else {
        items.add(
          SelectionActionButton(
            icon: Icons.add_outlined,
            labelText: S.of(context).addToAlbum,
            onTap: anyOwnedFiles ? _addToAlbum : null,
            shouldShow: ownedAndPendingUploadFilesCount > 0,
          ),
        );
      }
    }

    if (widget.type.showAddtoHiddenAlbum()) {
      items.add(
        SelectionActionButton(
          icon: Icons.add_outlined,
          labelText: S.of(context).addToAlbum,
          onTap: _addToHiddenAlbum,
        ),
      );
    }

    if (widget.type.showMoveToAlbum()) {
      items.add(
        SelectionActionButton(
          icon: Icons.arrow_forward_outlined,
          labelText: S.of(context).moveToAlbum,
          onTap: anyUploadedFiles ? _moveFiles : null,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    }

    if (widget.type.showMovetoHiddenAlbum()) {
      items.add(
        SelectionActionButton(
          icon: Icons.arrow_forward_outlined,
          labelText: S.of(context).moveToAlbum,
          onTap: _moveFilesToHiddenAlbum,
        ),
      );
    }

    if (widget.type.showRemoveFromAlbum()) {
      items.add(
        SelectionActionButton(
          icon: Icons.remove_outlined,
          labelText: S.of(context).removeFromAlbum,
          onTap: removeCount > 0 ? _removeFilesFromAlbum : null,
          shouldShow: removeCount > 0,
        ),
      );
    }

    if (widget.type.showRemoveFromHiddenAlbum()) {
      items.add(
        SelectionActionButton(
          icon: Icons.remove_outlined,
          labelText: S.of(context).removeFromAlbum,
          onTap: _removeFilesFromHiddenAlbum,
        ),
      );
    }

    if (widget.type.showFavoriteOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.favorite_border_rounded,
          labelText: S.of(context).favorite,
          onTap: anyUploadedFiles ? _onFavoriteClick : null,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    } else if (widget.type.showUnFavoriteOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.favorite,
          labelText: S.of(context).removeFromFavorite,
          onTap: _onUnFavoriteClick,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    }

    items.add(
      SelectionActionButton(
        icon: Icons.grid_view_outlined,
        labelText: S.of(context).createCollage,
        onTap: _onCreateCollageClicked,
        shouldShow: showCollageOption,
      ),
    );

    if (widget.type.showDeleteOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.delete_outline,
          labelText: S.of(context).delete,
          onTap: anyOwnedFiles ? _onDeleteClick : null,
          shouldShow: ownedAndPendingUploadFilesCount > 0,
        ),
      );
    }

    if (widget.type.showHideOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.visibility_off_outlined,
          labelText: S.of(context).hide,
          onTap: anyUploadedFiles ? _onHideClick : null,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    } else if (widget.type.showUnHideOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.visibility_outlined,
          labelText: S.of(context).unhide,
          onTap: _onUnhideClick,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    }
    if (widget.type.showArchiveOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.archive_outlined,
          labelText: S.of(context).archive,
          onTap: anyUploadedFiles ? _onArchiveClick : null,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    } else if (widget.type.showUnArchiveOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.unarchive,
          labelText: S.of(context).unarchive,
          onTap: _onUnArchiveClick,
          shouldShow: ownedFilesCount > 0,
        ),
      );
    }

    if (widget.type.showRestoreOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.restore_outlined,
          labelText: S.of(context).restore,
          onTap: _restore,
        ),
      );
    }

    if (widget.type.showPermanentlyDeleteOption()) {
      items.add(
        SelectionActionButton(
          icon: Icons.delete_forever_outlined,
          labelText: S.of(context).permanentlyDelete,
          onTap: _permanentlyDelete,
        ),
      );
    }

    if (widget.type.showEditLocation()) {
      items.add(
        SelectionActionButton(
          shouldShow: widget.selectedFiles.files.any(
            (element) => (element.ownerID == currentUserID),
          ),
          labelText: S.of(context).editLocation,
          icon: Icons.edit_location_alt_outlined,
          onTap: () async {
            await showBarModalBottomSheet(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
              ),
              backgroundColor: getEnteColorScheme(context).backgroundElevated,
              barrierColor: backdropFaintDark,
              topControl: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // This container is for increasing the tap area
                  Container(
                    width: double.infinity,
                    height: 36,
                    color: Colors.transparent,
                  ),
                  Container(
                    height: 5,
                    width: 40,
                    decoration: const BoxDecoration(
                      color: backgroundElevated2Light,
                      borderRadius: BorderRadius.all(
                        Radius.circular(5),
                      ),
                    ),
                  ),
                ],
              ),
              context: context,
              builder: (context) {
                return UpdateLocationDataWidget(
                  widget.selectedFiles.files.toList(),
                );
              },
            );
          },
        ),
      );
    }

    items.add(
      SelectionActionButton(
        labelText: S.of(context).share,
        icon: Icons.adaptive.share_outlined,
        onTap: () => shareSelected(
          context,
          shareButtonKey,
          widget.selectedFiles.files.toList(),
        ),
      ),
    );

    if (items.isNotEmpty) {
      final scrollController = ScrollController();
      // h4ck: https://github.com/flutter/flutter/issues/57920#issuecomment-893970066
      return MediaQuery(
        data: MediaQuery.of(context).removePadding(removeBottom: true),
        child: SafeArea(
          child: Scrollbar(
            radius: const Radius.circular(1),
            thickness: 2,
            controller: scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(
                decelerationRate: ScrollDecelerationRate.fast,
              ),
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 4),
                    ...items,
                    const SizedBox(width: 4),
                  ],
                ),
              ),
            ),
          ),
        ),
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

  Future<void> _moveFilesToHiddenAlbum() async {
    showCollectionActionSheet(
      context,
      selectedFiles: widget.selectedFiles,
      actionType: CollectionActionType.moveToHiddenCollection,
    );
  }

  Future<void> _addToAlbum() async {
    if (split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    showCollectionActionSheet(context, selectedFiles: widget.selectedFiles);
  }

  Future<void> _addToHiddenAlbum() async {
    showCollectionActionSheet(
      context,
      selectedFiles: widget.selectedFiles,
      actionType: CollectionActionType.addToHiddenAlbum,
    );
  }

  Future<void> _onDeleteClick() async {
    return showDeleteSheet(context, widget.selectedFiles, split);
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

  Future<void> _removeFilesFromHiddenAlbum() async {
    await collectionActions.showRemoveFromCollectionSheetV2(
      context,
      widget.collection!,
      widget.selectedFiles,
      false,
      isHidden: true,
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
      CollageCreatorPage(widget.selectedFiles.files.toList()),
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
        ),
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
        await routeToPage(
          context,
          ManageSharedLinkWidget(collection: _cachedCollectionForSharedLink),
        );
      }
    }
    widget.selectedFiles.clearAll();
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
      widget.selectedFiles.files.toList(),
    )) {
      widget.selectedFiles.clearAll();
    }
  }
}
