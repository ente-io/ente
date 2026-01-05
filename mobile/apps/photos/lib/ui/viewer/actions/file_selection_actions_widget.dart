import "dart:async";

import 'package:ente_icons/ente_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import "package:local_auth/local_auth.dart";
import "package:logging/logging.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";
import 'package:photos/core/configuration.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/files_updated_event.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/events/people_changed_event.dart";
import "package:photos/generated/l10n.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/files_split.dart';
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import "package:photos/models/ml/face/person.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart';
import "package:photos/services/machine_learning/face_ml/person/person_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/actions/collection/collection_file_actions.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import "package:photos/ui/components/bottom_action_bar/selection_action_button_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/tools/collage/collage_creator_page.dart";
import "package:photos/ui/viewer/date/edit_date_sheet.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/location/update_location_data_widget.dart";
import "package:photos/ui/viewer/people/add_files_to_person_page.dart";
import 'package:photos/utils/delete_file_util.dart';
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/file_download_util.dart";
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import "package:photos/utils/share_util.dart";
import "package:photos/utils/standalone/simple_task_queue.dart";

class FileSelectionActionsWidget extends StatefulWidget {
  final GalleryType type;
  final Collection? collection;
  final DeviceCollection? deviceCollection;
  final SelectedFiles selectedFiles;
  final PersonEntity? person;
  final String? clusterID;

  const FileSelectionActionsWidget(
    this.type,
    this.selectedFiles, {
    super.key,
    this.collection,
    this.person,
    this.clusterID,
    this.deviceCollection,
  });

  @override
  State<FileSelectionActionsWidget> createState() =>
      _FileSelectionActionsWidgetState();
}

class _FileSelectionActionsWidgetState
    extends State<FileSelectionActionsWidget> {
  static final _logger = Logger("FileSelectionActionsWidget");
  late int currentUserID;
  late FilesSplit split;
  late CollectionActions collectionActions;
  late bool isCollectionOwner;
  // _cachedCollectionForSharedLink is primarily used to avoid creating duplicate
  // links if user keeps on creating Create link button after selecting
  // few files. This link is reset on any selection changed;
  Collection? _cachedCollectionForSharedLink;
  final GlobalKey shareButtonKey = GlobalKey();
  final GlobalKey sendLinkButtonKey = GlobalKey();
  final StreamController<double> _progressController =
      StreamController<double>();

  bool get _canRemoveOthersFiles =>
      widget.collection != null &&
      CollectionsService.instance
          .canRemoveFilesFromAllParticipants(widget.collection!);

  @override
  void initState() {
    super.initState();
    //User ID will be null if the user is not logged in (links-in-app)
    currentUserID = Configuration.instance.getUserID() ?? -1;

    split = FilesSplit.split(<EnteFile>[], currentUserID);
    widget.selectedFiles.addListener(_selectFileChangeListener);
    collectionActions = CollectionActions(CollectionsService.instance);
    if (widget.selectedFiles.files.isNotEmpty) {
      _selectFileChangeListener();
    }
  }

  @override
  void dispose() {
    _progressController.close();
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
    if (widget.selectedFiles.files.isEmpty) {
      return const SizedBox();
    }
    final ownedFilesCount = split.ownedByCurrentUser.length;
    final ownedAndPendingUploadFilesCount =
        ownedFilesCount + split.pendingUploads.length;
    final bool canRemoveOthersFiles = _canRemoveOthersFiles;
    final int removeCount = split.ownedByCurrentUser.length +
        (canRemoveOthersFiles ? split.ownedByOtherUsers.length : 0);

    final bool anyOwnedFiles =
        split.pendingUploads.isNotEmpty || split.ownedByCurrentUser.isNotEmpty;
    final bool allOwnedFiles =
        ownedAndPendingUploadFilesCount > 0 && split.ownedByOtherUsers.isEmpty;

    final bool anyUploadedFiles = split.ownedByCurrentUser.isNotEmpty;
    final bool hasUploadedFileIDs =
        widget.selectedFiles.files.any((file) => file.uploadedFileID != null);
    final showCollageOption = CollageCreatorPage.isValidCount(
          widget.selectedFiles.files.length,
        ) &&
        !widget.selectedFiles.files.any(
          (element) => element.fileType == FileType.video,
        );
    final showDownloadOption =
        widget.selectedFiles.files.any((element) => element.localID == null);
    final bool isCollectionOwnerOrAdmin = widget.collection != null &&
        (widget.collection!.isOwner(currentUserID) ||
            widget.collection!.isAdmin(currentUserID));
    final bool canSuggestDeleteAction =
        (widget.type == GalleryType.sharedCollection ||
                widget.type == GalleryType.ownedCollection) &&
            isCollectionOwnerOrAdmin &&
            split.ownedByOtherUsers.isNotEmpty;

    //To animate adding and removing of [SelectedActionButton], add all items
    //and set [shouldShow] to false for items that should not be shown and true
    //for items that should be shown.
    final List<SelectionActionButton> items = [];
    if (widget.type == GalleryType.trash) {
      items.add(
        SelectionActionButton(
          icon: Icons.restore_outlined,
          labelText: AppLocalizations.of(context).restore,
          onTap: _restore,
        ),
      );
      items.add(
        SelectionActionButton(
          icon: Icons.delete_forever_outlined,
          labelText: AppLocalizations.of(context).permanentlyDelete,
          onTap: _permanentlyDelete,
        ),
      );
    } else if (widget.type == GalleryType.deleteSuggestions) {
      items.add(
        SelectionActionButton(
          icon: Icons.delete_outline,
          labelText: AppLocalizations.of(context).delete,
          onTap: split.ownedByCurrentUser.isNotEmpty ? _onDeleteClick : null,
        ),
      );
      items.add(
        SelectionActionButton(
          icon: Icons.clear,
          labelText: AppLocalizations.of(context).rejectSuggestions,
          onTap: widget.selectedFiles.files.isNotEmpty
              ? _rejectDeleteSuggestions
              : null,
        ),
      );
    } else {
      if (widget.type.showCreateLink()) {
        if (_cachedCollectionForSharedLink != null && anyUploadedFiles) {
          items.add(
            SelectionActionButton(
              icon: Icons.copy_outlined,
              labelText: AppLocalizations.of(context).copyLink,
              onTap: anyUploadedFiles ? _sendLink : null,
            ),
          );
        } else {
          items.add(
            SelectionActionButton(
              icon: Icons.navigation_rounded,
              labelText: AppLocalizations.of(context).sendLink,
              onTap: anyUploadedFiles ? _onSendLinkTapped : null,
              shouldShow: ownedFilesCount > 0,
              key: sendLinkButtonKey,
            ),
          );
        }
      }
      if (widget.type == GalleryType.peopleTag && widget.person != null) {
        items.add(
          SelectionActionButton(
            icon: Icons.remove_circle_outline,
            labelText: AppLocalizations.of(context)
                .notPersonLabel(name: widget.person!.data.name),
            onTap: _onNotpersonClicked,
          ),
        );
        if (ownedFilesCount == 1) {
          items.add(
            SelectionActionButton(
              icon: Icons.image_outlined,
              labelText: AppLocalizations.of(context).useAsCover,
              onTap: anyUploadedFiles ? _setPersonCover : null,
            ),
          );
        }
      }

      if (widget.type == GalleryType.cluster && widget.clusterID != null) {
        items.add(
          SelectionActionButton(
            labelText: AppLocalizations.of(context).notThisPerson,
            icon: Icons.remove_circle_outline,
            onTap: _onRemoveFromClusterClicked,
          ),
        );
      }

      final showUploadIcon = widget.type == GalleryType.localFolder &&
          split.ownedByCurrentUser.isEmpty;
      if (widget.type.showAddToAlbum()) {
        if (showUploadIcon) {
          items.add(
            SelectionActionButton(
              icon: Icons.cloud_upload_outlined,
              labelText: AppLocalizations.of(context).addToEnte,
              onTap: _addToAlbum,
            ),
          );
        } else {
          items.add(
            SelectionActionButton(
              icon: Icons.add_outlined,
              labelText: AppLocalizations.of(context).addToAlbum,
              onTap: _addToAlbum,
            ),
          );
        }
      }

      if (widget.type.showAddtoHiddenAlbum()) {
        items.add(
          SelectionActionButton(
            icon: Icons.add_outlined,
            labelText: AppLocalizations.of(context).addToAlbum,
            onTap: _addToHiddenAlbum,
          ),
        );
      }

      if (widget.type.showMoveToAlbum()) {
        items.add(
          SelectionActionButton(
            icon: Icons.arrow_forward_outlined,
            labelText: AppLocalizations.of(context).moveToAlbum,
            onTap: anyUploadedFiles ? _moveFiles : null,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      }

      if (widget.type.showMovetoHiddenAlbum()) {
        items.add(
          SelectionActionButton(
            icon: Icons.arrow_forward_outlined,
            labelText: AppLocalizations.of(context).moveToAlbum,
            onTap: _moveFilesToHiddenAlbum,
          ),
        );
      }

      if (widget.type.showDeleteOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.delete_outline,
            labelText: AppLocalizations.of(context).delete,
            onTap: anyOwnedFiles ? _onDeleteClick : null,
            shouldShow: allOwnedFiles,
          ),
        );
      }

      if (widget.type.showRemoveFromAlbum()) {
        items.add(
          SelectionActionButton(
            icon: Icons.remove_outlined,
            labelText: AppLocalizations.of(context).removeFromAlbum,
            onTap: removeCount > 0 ? _removeFilesFromAlbum : null,
            shouldShow: removeCount > 0,
          ),
        );
      }

      if (canSuggestDeleteAction) {
        items.add(
          SelectionActionButton(
            icon: Icons.flag_outlined,
            labelText: AppLocalizations.of(context).suggestDeletion,
            onTap: _onSuggestDelete,
          ),
        );
      }

      if (widget.type.showRemoveFromHiddenAlbum()) {
        items.add(
          SelectionActionButton(
            icon: Icons.remove_outlined,
            labelText: AppLocalizations.of(context).removeFromAlbum,
            onTap: _removeFilesFromHiddenAlbum,
          ),
        );
      }

      if (widget.type.showFavoriteOption()) {
        items.add(
          SelectionActionButton(
            icon: EnteIcons.favoriteStroke,
            labelText: AppLocalizations.of(context).favorite,
            onTap: anyUploadedFiles ? _onFavoriteClick : null,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      } else if (widget.type.showUnFavoriteOption()) {
        items.add(
          SelectionActionButton(
            icon: EnteIcons.favoriteFilled,
            labelText: AppLocalizations.of(context).removeFromFavorite,
            onTap: _onUnFavoriteClick,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      }
      items.add(
        SelectionActionButton(
          svgAssetPath: "assets/icons/guest_view_icon.svg",
          labelText: AppLocalizations.of(context).guestView,
          onTap: _onGuestViewClick,
        ),
      );

      if (flagService.manualTagFileToPerson &&
          widget.type.showAddToPersonOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.person_add_alt_1_outlined,
            labelText: AppLocalizations.of(context).addToPerson,
            onTap: hasUploadedFileIDs ? _onAddFilesToPerson : null,
            shouldShow: hasUploadedFileIDs,
          ),
        );
      }
      if (widget.type != GalleryType.sharedPublicCollection) {
        items.add(
          SelectionActionButton(
            icon: Icons.grid_view_outlined,
            labelText: AppLocalizations.of(context).createCollage,
            onTap: _onCreateCollageClicked,
            shouldShow: showCollageOption,
          ),
        );
      }

      if (widget.type.showHideOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.visibility_off_outlined,
            labelText: AppLocalizations.of(context).hide,
            onTap: anyUploadedFiles ? _onHideClick : null,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      } else if (widget.type.showUnHideOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.visibility_outlined,
            labelText: AppLocalizations.of(context).unhide,
            onTap: _onUnhideClick,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      }
      if (widget.type.showArchiveOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.archive_outlined,
            labelText: AppLocalizations.of(context).archive,
            onTap: anyUploadedFiles ? _onArchiveClick : null,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      } else if (widget.type.showUnArchiveOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.unarchive,
            labelText: AppLocalizations.of(context).unarchive,
            onTap: _onUnArchiveClick,
            shouldShow: ownedFilesCount > 0,
          ),
        );
      }

      if (widget.type.showRestoreOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.restore_outlined,
            labelText: AppLocalizations.of(context).restore,
            onTap: _restore,
          ),
        );
      }

      if (widget.type.showPermanentlyDeleteOption()) {
        items.add(
          SelectionActionButton(
            icon: Icons.delete_forever_outlined,
            labelText: AppLocalizations.of(context).permanentlyDelete,
            onTap: _permanentlyDelete,
          ),
        );
      }

      if (widget.type.showBulkEditTime()) {
        items.add(
          SelectionActionButton(
            shouldShow: widget.selectedFiles.files.every(
              (element) => (element.ownerID == currentUserID),
            ),
            labelText: AppLocalizations.of(context).editTime,
            icon: Icons.edit_calendar_outlined,
            onTap: () async {
              final newDate = await showEditDateSheet(
                context,
                widget.selectedFiles.files,
              );
              if (newDate != null) {
                widget.selectedFiles.clearAll();
              }
            },
          ),
        );
      }

      if (widget.type.showEditLocation()) {
        items.add(
          SelectionActionButton(
            shouldShow: widget.selectedFiles.files.any(
              (element) => (element.ownerID == currentUserID),
            ),
            labelText: AppLocalizations.of(context).editLocation,
            icon: Icons.edit_location_alt_outlined,
            onTap: _editLocation,
          ),
        );
      }

      if (showDownloadOption) {
        items.add(
          SelectionActionButton(
            labelText: AppLocalizations.of(context).download,
            icon: Icons.cloud_download_outlined,
            onTap: () => _download(widget.selectedFiles.files.toList()),
          ),
        );
      }
      if (widget.type != GalleryType.sharedPublicCollection) {
        items.add(
          SelectionActionButton(
            labelText: AppLocalizations.of(context).share,
            icon: Icons.adaptive.share_outlined,
            key: shareButtonKey,
            onTap: _shareSelectedFiles,
          ),
        );
      }
    }

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
    }
    return const SizedBox();
  }

  Future<void> _editLocation() async {
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
  }

  Future<void> _shareSelectedFiles() async {
    shareSelected(
      context,
      shareButtonKey,
      widget.selectedFiles.files.toList(),
    );
    widget.selectedFiles.clearAll();
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

  Future<void> _rejectDeleteSuggestions() async {
    final fileIDs = widget.selectedFiles.files
        .map((file) => file.uploadedFileID)
        .whereType<int>()
        .toSet()
        .toList();
    if (fileIDs.isEmpty) {
      return;
    }
    try {
      await CollectionsService.instance.rejectDeleteSuggestions(fileIDs);
      widget.selectedFiles.clearAll();
      Bus.instance.fire(
        FilesUpdatedEvent(
          const [],
          source: "reject-delete-suggestions",
        ),
      );
    } catch (e, s) {
      _logger.warning("Failed to reject delete suggestions", e, s);
      await showGenericErrorDialog(
        context: context,
        error: e,
      );
    }
  }

  Future<void> _onSuggestDelete() async {
    if (widget.collection == null) {
      return;
    }
    final List<EnteFile> filesToSuggest = split.ownedByOtherUsers
        .where((file) => file.uploadedFileID != null)
        .toList();
    if (filesToSuggest.isEmpty) {
      return;
    }
    final l10n = AppLocalizations.of(context);
    final actionResult = await showActionSheet(
      context: context,
      title: l10n.suggestDeletion,
      body: l10n.suggestDeletionDescription,
      actionSheetType: ActionSheetType.defaultActionSheet,
      buttons: [
        ButtonWidget(
          labelText: l10n.suggestDeletion,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          isInAlert: true,
          onTap: () async {
            await CollectionsService.instance.suggestDeleteFromCollection(
              widget.collection!.id,
              filesToSuggest,
            );
            showShortToast(
              context,
              l10n.deleteSuggestionSent,
            );
          },
        ),
        ButtonWidget(
          labelText: l10n.cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
    );
    if (actionResult?.action == ButtonAction.error) {
      await showGenericErrorDialog(
        context: context,
        error: actionResult?.exception ??
            Exception("Failed to send delete suggestion"),
      );
    } else if (actionResult?.action == ButtonAction.first) {
      widget.selectedFiles.clearAll();
      if (mounted) {
        setState(() => {});
      }
    }
  }

  Future<void> _removeFilesFromAlbum() async {
    if (split.pendingUploads.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.pendingUploads.toSet(), skipNotify: true);
    }
    if (!_canRemoveOthersFiles && split.ownedByOtherUsers.isNotEmpty) {
      widget.selectedFiles
          .unSelectAll(split.ownedByOtherUsers.toSet(), skipNotify: true);
    }
    final bool removingOthersFile =
        _canRemoveOthersFiles && split.ownedByOtherUsers.isNotEmpty;
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

  Future<void> _onAddFilesToPerson() async {
    final filesWithIds = widget.selectedFiles.files
        .where((file) => file.uploadedFileID != null)
        .toList();
    if (filesWithIds.isEmpty) {
      showShortToast(
        context,
        AppLocalizations.of(context).onlyUploadedFilesCanBeAddedToPerson,
      );
      return;
    }
    final hasPersons =
        await AddFilesToPersonPage.ensureNamedPersonsExist(context);
    if (!mounted || !hasPersons) {
      return;
    }
    final result = await routeToPage(
      context,
      AddFilesToPersonPage(files: filesWithIds),
      forceCustomPageRoute: true,
    );
    if (result is! ManualPersonAssignmentResult) {
      return;
    }
    final addedCount = result.addedFileIds.length;
    if (addedCount > 0) {
      final addedFiles = filesWithIds
          .where(
            (file) =>
                file.uploadedFileID != null &&
                result.addedFileIds.contains(file.uploadedFileID),
          )
          .toList();
      Bus.instance.fire(
        PeopleChangedEvent(
          type: PeopleEventType.saveOrEditPerson,
          source: "manual-add-files-to-person",
          person: result.person,
          relevantFiles: addedFiles,
        ),
      );
      showToast(
        context,
        AppLocalizations.of(context).addedFilesToPerson(
          count: addedCount,
          personName: result.person.data.name,
        ),
      );
      widget.selectedFiles.clearAll();
      if (mounted) {
        setState(() => {});
      }
      return;
    }
    final alreadyCount = result.alreadyAssignedFileIds.length;
    if (alreadyCount > 0) {
      showShortToast(
        context,
        AppLocalizations.of(context).filesAlreadyLinkedToPerson(
          count: alreadyCount,
          personName: result.person.data.name,
        ),
      );
    }
  }

  Future<void> _onGuestViewClick() async {
    final List<EnteFile> selectedFiles = widget.selectedFiles.files.toList();
    if (await LocalAuthentication().isDeviceSupported()) {
      final page = DetailPage(
        DetailPageConfiguration(
          selectedFiles,
          0,
          "guest_view",
        ),
      );
      await localSettings.setOnGuestView(true);
      routeToPage(context, page, forceCustomPageRoute: true).ignore();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Bus.instance.fire(GuestViewEvent(true, false));
      });
    } else {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).noSystemLockFound,
        AppLocalizations.of(context).guestViewEnablePreSteps,
      );
    }
    widget.selectedFiles.clearAll();
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

  Future<void> _onSendLinkTapped() async {
    if (split.ownedByCurrentUser.isEmpty) {
      showShortToast(
        context,
        AppLocalizations.of(context).canOnlyCreateLinkForFilesOwnedByYou,
      );
      return;
    }
    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).creatingLink,
      isDismissible: true,
    );
    await dialog.show();
    _cachedCollectionForSharedLink ??= await collectionActions
        .createSharedCollectionLink(context, split.ownedByCurrentUser);

    if (_cachedCollectionForSharedLink == null) {
      await dialog.hide();
      return;
    }
    await dialog.hide();
    await _sendLink();
    widget.selectedFiles.clearAll();
    if (mounted) {
      setState(() => {});
    }
  }

  Future<void> _setPersonCover() async {
    final EnteFile file = widget.selectedFiles.files.first;
    final updatedPerson =
        await PersonService.instance.updateAvatar(widget.person!, file);
    widget.selectedFiles.clearAll();
    if (mounted) {
      setState(() => {});
    }
    Bus.instance.fire(
      PeopleChangedEvent(
        type: PeopleEventType.saveOrEditPerson,
        source: "setPersonCover",
        person: updatedPerson,
      ),
    );
  }

  Future<void> _onNotpersonClicked() async {
    try {
      final actionResult = await showActionSheet(
        context: context,
        buttons: [
          ButtonWidget(
            labelText: AppLocalizations.of(context).yesRemove,
            buttonType: ButtonType.neutral,
            buttonSize: ButtonSize.large,
            shouldStickToDarkTheme: true,
            buttonAction: ButtonAction.first,
            isInAlert: true,
          ),
          ButtonWidget(
            labelText: AppLocalizations.of(context).cancel,
            buttonType: ButtonType.secondary,
            buttonSize: ButtonSize.large,
            buttonAction: ButtonAction.second,
            shouldStickToDarkTheme: true,
            isInAlert: true,
          ),
        ],
        body: AppLocalizations.of(context)
            .selectedItemsWillBeRemovedFromThisPerson,
        actionSheetType: ActionSheetType.defaultActionSheet,
      );
      if (actionResult?.action != null) {
        if (actionResult!.action == ButtonAction.first) {
          await ClusterFeedbackService.instance.removeFilesFromPerson(
            widget.selectedFiles.files.toList(),
            widget.person!,
          );
        }
      }
      widget.selectedFiles.clearAll();
      if (mounted) {
        setState(() => {});
      }
    } catch (e, s) {
      _logger.severe("Failed to initiate `notPersonLabel`", e, s);
    }
  }

  Future<void> _onRemoveFromClusterClicked() async {
    if (widget.clusterID == null) {
      showShortToast(context, 'Cluster ID is null. Cannot remove files.');
      return;
    }
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          labelText: AppLocalizations.of(context).yesRemove,
          buttonType: ButtonType.neutral,
          buttonSize: ButtonSize.large,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          isInAlert: true,
        ),
        ButtonWidget(
          labelText: AppLocalizations.of(context).cancel,
          buttonType: ButtonType.secondary,
          buttonSize: ButtonSize.large,
          buttonAction: ButtonAction.second,
          shouldStickToDarkTheme: true,
          isInAlert: true,
        ),
      ],
      body:
          AppLocalizations.of(context).selectedItemsWillBeRemovedFromThisPerson,
      actionSheetType: ActionSheetType.defaultActionSheet,
    );
    if (actionResult?.action != null) {
      if (actionResult!.action == ButtonAction.first) {
        await ClusterFeedbackService.instance.removeFilesFromCluster(
          widget.selectedFiles.files.toList(),
          widget.clusterID!,
        );
      }
    }
    widget.selectedFiles.clearAll();
    if (mounted) {
      setState(() => {});
    }
  }

  Future<void> _sendLink() async {
    if (_cachedCollectionForSharedLink != null) {
      final String url = CollectionsService.instance.getPublicUrl(
        _cachedCollectionForSharedLink!,
      );
      unawaited(Clipboard.setData(ClipboardData(text: url)));
      await shareText(
        url,
        context: context,
        key: sendLinkButtonKey,
      );
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

  Future<void> _download(List<EnteFile> files) async {
    final totalFiles = files.length;
    int downloadedFiles = 0;

    final dialog = createProgressDialog(
      context,
      AppLocalizations.of(context).downloading +
          " ($downloadedFiles/$totalFiles)",
      isDismissible: true,
    );
    await dialog.show();
    try {
      final taskQueue = SimpleTaskQueue(maxConcurrent: 5);
      final futures = <Future>[];
      for (final file in files) {
        if (file.localID == null) {
          futures.add(
            taskQueue.add(() async {
              await downloadToGallery(file);
              downloadedFiles++;
              dialog.update(
                message: AppLocalizations.of(context).downloading +
                    " ($downloadedFiles/$totalFiles)",
              );
            }),
          );
        }
      }
      await Future.wait(futures);
      await dialog.hide();
      widget.selectedFiles.clearAll();
      showToast(context, AppLocalizations.of(context).filesSavedToGallery);
    } catch (e) {
      _logger.warning("Failed to save files", e);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}
