import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import "package:photos/core/constants.dart";
import 'package:photos/core/event_bus.dart';
import "package:photos/core/network/network.dart";
import "package:photos/db/files_db.dart";
import "package:photos/events/collection_meta_event.dart";
import "package:photos/events/magic_sort_change_event.dart";
import 'package:photos/events/subscription_purchased_event.dart';
import "package:photos/gateways/cast_gw.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import 'package:photos/models/backup_status.dart';
import "package:photos/models/button_result.dart";
import 'package:photos/models/collection/collection.dart';
import 'package:photos/models/device_collection.dart';
import "package:photos/models/file/file.dart";
import 'package:photos/models/gallery_type.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/services/collections_service.dart';
import "package:photos/services/files_service.dart";
import "package:photos/states/location_screen_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
import "package:photos/ui/cast/auto.dart";
import "package:photos/ui/cast/choose.dart";
import "package:photos/ui/collections/album/smart_album_people.dart";
import "package:photos/ui/common/popup_item.dart";
import "package:photos/ui/common/popup_item_async.dart";
import "package:photos/ui/common/web_page.dart";
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import "package:photos/ui/map/enable_map.dart";
import "package:photos/ui/map/map_screen.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/sharing/album_participants_page.dart';
import "package:photos/ui/sharing/manage_links_widget.dart";
import 'package:photos/ui/sharing/share_collection_page.dart';
import 'package:photos/ui/tools/free_space_page.dart';
import "package:photos/ui/viewer/gallery/hooks/add_photos_sheet.dart";
import 'package:photos/ui/viewer/gallery/hooks/pick_cover_photo.dart';
import "package:photos/ui/viewer/gallery/state/inherited_search_filter_data.dart";
import "package:photos/ui/viewer/hierarchicial_search/applied_filters_for_appbar.dart";
import "package:photos/ui/viewer/hierarchicial_search/recommended_filters_for_appbar.dart";
import "package:photos/ui/viewer/location/edit_location_sheet.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/file_download_util.dart";
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/standalone/data.dart';
import "package:uuid/uuid.dart";

class GalleryAppBarWidget extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final DeviceCollection? deviceCollection;
  final Collection? collection;
  final bool isFromCollectPhotos;
  final List<EnteFile>? files;

  const GalleryAppBarWidget(
    this.type,
    this.title,
    this.selectedFiles, {
    super.key,
    this.deviceCollection,
    this.collection,
    this.isFromCollectPhotos = false,
    this.files,
  });

  @override
  State<GalleryAppBarWidget> createState() => _GalleryAppBarWidgetState();
}

enum AlbumPopupAction {
  rename,
  delete,
  map,
  ownedArchive,
  sharedArchive,
  ownedHide,
  playOnTv,
  autoAddPhotos,
  sort,
  leave,
  freeUpSpace,
  setCover,
  addPhotos,
  pinAlbum,
  removeLink,
  cleanUncategorized,
  downloadAlbum,
  sortByMostRecent,
  sortByMostRelevant,
  editLocation,
  deleteLocation,
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  final _logger = Logger("GalleryAppBar");
  late StreamSubscription _userAuthEventSubscription;
  late StreamSubscription<CollectionMetaEvent> _collectionMetaEventSubscription;
  late Function() _selectedFilesListener;
  String? _appBarTitle;
  late CollectionActions collectionActions;
  bool isQuickLink = false;
  late GalleryType galleryType;

  final ValueNotifier<int> castNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _selectedFilesListener = () {
      setState(() {});
    };
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _collectionMetaEventSubscription = Bus.instance
        .on<CollectionMetaEvent>()
        .where(
          (event) =>
              event.id == widget.collection?.id &&
              event.type == CollectionMetaEventType.autoAddPeople,
        )
        .listen(stateRefresh);

    _appBarTitle = widget.title;
    galleryType = widget.type;
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    _collectionMetaEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  void stateRefresh(dynamic event) {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final inheritedSearchFilterData =
        InheritedSearchFilterData.maybeOf(context);
    final isHierarchicalSearchable =
        inheritedSearchFilterData?.isHierarchicalSearchable ?? false;
    return galleryType == GalleryType.homepage
        ? const SizedBox.shrink()
        : isHierarchicalSearchable
            ? ValueListenableBuilder(
                valueListenable: inheritedSearchFilterData!
                    .searchFilterDataProvider!.isSearchingNotifier,
                child: const PreferredSize(
                  preferredSize: Size.fromHeight(0),
                  child: Flexible(child: RecommendedFiltersForAppbar()),
                ),
                builder: (context, isSearching, child) {
                  return AppBar(
                    elevation: 0,
                    centerTitle: false,
                    title: isSearching
                        ? const SizedBox(
                            // +1 to account for the filter's outer stroke width
                            height: kFilterChipHeight + 1,
                            child: AppliedFiltersForAppbar(),
                          )
                        : Text(
                            _appBarTitle!,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(fontSize: 16),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    actions: isSearching ? null : _getDefaultActions(context),
                    bottom: child as PreferredSizeWidget,
                    surfaceTintColor: Colors.transparent,
                  );
                },
              )
            : AppBar(
                elevation: 0,
                centerTitle: false,
                title: Text(
                  _appBarTitle!,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall!
                      .copyWith(fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                actions: _getDefaultActions(context),
              );
  }

  Future<dynamic> _renameAlbum(BuildContext context) async {
    if (galleryType != GalleryType.ownedCollection &&
        galleryType != GalleryType.hiddenOwnedCollection &&
        galleryType != GalleryType.quickLink) {
      showToast(
        context,
        AppLocalizations.of(context)
            .typeOfGallerGallerytypeIsNotSupportedForRename(
                galleryType: "$galleryType",),
      );

      return;
    }
    final result = await showTextInputDialog(
      context,
      title: isQuickLink
          ? AppLocalizations.of(context).enterAlbumName
          : AppLocalizations.of(context).renameAlbum,
      submitButtonLabel: isQuickLink
          ? AppLocalizations.of(context).done
          : AppLocalizations.of(context).rename,
      hintText: AppLocalizations.of(context).enterAlbumName,
      alwaysShowSuccessState: true,
      initialValue: widget.collection?.displayName ?? "",
      textCapitalization: TextCapitalization.words,
      onSubmit: (String text) async {
        // indicates user cancelled the rename request
        if (text == "" || text.trim() == _appBarTitle!.trim()) {
          return;
        }

        try {
          await CollectionsService.instance.rename(widget.collection!, text);
          if (mounted) {
            _appBarTitle = text;
            if (isQuickLink) {
              // update the gallery type to owned collection so that correct
              // actions are shown
              galleryType = GalleryType.ownedCollection;
            }
            setState(() {});
          }
        } catch (e, s) {
          _logger.warning("Failed to rename album", e, s);
          rethrow;
        }
      },
    );
    if (result is Exception) {
      await showGenericErrorDialog(context: context, error: result);
    }
  }

  Future<dynamic> _leaveAlbum(BuildContext context) async {
    final actionResult = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: AppLocalizations.of(context).leaveAlbum,
          onTap: () async {
            await CollectionsService.instance.leaveAlbum(widget.collection!);
          },
        ),
        ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: AppLocalizations.of(context).cancel,
        ),
      ],
      title: AppLocalizations.of(context).leaveSharedAlbum,
      body: AppLocalizations.of(context)
          .photosAddedByYouWillBeRemovedFromTheAlbum,
    );
    if (actionResult?.action != null && mounted) {
      if (actionResult!.action == ButtonAction.error) {
        await showGenericErrorDialog(
          context: context,
          error: actionResult.exception,
        );
      } else if (actionResult.action == ButtonAction.first) {
        Navigator.of(context).pop();
      }
    }
  }

  // todo: In the new design, clicking on free up space will directly open
  // the free up space page and show loading indicator while calculating
  // the space which can be claimed up. This code duplication should be removed
  // whenever we move to the new design for free up space.
  Future<dynamic> _deleteBackedUpFiles(BuildContext context) async {
    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).calculating);
    await dialog.show();
    BackupStatus status;
    try {
      status = await FilesService.instance
          .getBackupStatus(pathID: widget.deviceCollection!.id);
    } catch (e) {
      await dialog.hide();
      unawaited(showGenericErrorDialog(context: context, error: e));
      return;
    }

    await dialog.hide();
    if (status.localIDs.isEmpty) {
      await showErrorDialog(
        context,
        AppLocalizations.of(context).allClear,
        AppLocalizations.of(context).youveNoFilesInThisAlbumThatCanBeDeleted,
      );
    } else {
      final bool? result = await routeToPage(
        context,
        FreeSpacePage(status, clearSpaceForFolder: true),
      );
      if (result == true) {
        _showSpaceFreedDialog(status);
      }
    }
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    showChoiceDialog(
      context,
      title: AppLocalizations.of(context).success,
      body: AppLocalizations.of(context)
          .youHaveSuccessfullyFreedUp(storageSaved: formatBytes(status.size)),
      firstButtonLabel: AppLocalizations.of(context).rateUs,
      firstButtonOnTap: () async {
        await updateService.launchReviewUrl();
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: AppLocalizations.of(context).ok,
      secondButtonOnTap: () async {
        if (Platform.isIOS) {
          showToast(
            context,
            AppLocalizations.of(context).remindToEmptyDeviceTrash,
          );
        }
      },
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    // If the user has selected files, don't show any actions
    if (widget.selectedFiles.files.isNotEmpty ||
        !Configuration.instance.hasConfiguredAccount()) {
      return actions;
    }

    if (galleryType == GalleryType.magic) {
      actions.add(
        Tooltip(
          message: AppLocalizations.of(context).sort,
          child: PopupMenuButton(
            icon: const Icon(Icons.sort_rounded),
            itemBuilder: (context) {
              return [
                PopupMenuItem(
                  value: AlbumPopupAction.sortByMostRecent,
                  child: Text(AppLocalizations.of(context).mostRecent),
                ),
                PopupMenuItem(
                  value: AlbumPopupAction.sortByMostRelevant,
                  child: Text(AppLocalizations.of(context).mostRelevant),
                ),
              ];
            },
            onSelected: (AlbumPopupAction value) {
              if (value == AlbumPopupAction.sortByMostRecent) {
                Bus.instance
                    .fire(MagicSortChangeEvent(MagicSortType.mostRecent));
              } else if (value == AlbumPopupAction.sortByMostRelevant) {
                Bus.instance
                    .fire(MagicSortChangeEvent(MagicSortType.mostRelevant));
              }
            },
          ),
        ),
      );
    }

    final int userId = Configuration.instance.getUserID()!;
    isQuickLink = widget.collection?.isQuickLinkCollection() ?? false;
    if (galleryType.canAddFiles(widget.collection, userId)) {
      actions.add(
        Tooltip(
          message: AppLocalizations.of(context).addFiles,
          child: IconButton(
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: () async {
              await _showAddPhotoDialog(context);
            },
          ),
        ),
      );
    }

    if (galleryType.isSharable() && !widget.isFromCollectPhotos) {
      actions.add(
        Tooltip(
          message: AppLocalizations.of(context).share,
          child: IconButton(
            icon: Icon(
              isQuickLink && (widget.collection!.hasLink)
                  ? Icons.link_outlined
                  : Icons.adaptive.share,
            ),
            onPressed: () async {
              await _showShareCollectionDialog();
            },
          ),
        ),
      );
    }

    if (widget.collection != null && castService.isSupported) {
      actions.add(
        Tooltip(
          message: AppLocalizations.of(context).castAlbum,
          child: IconButton(
            icon: ValueListenableBuilder<int>(
              valueListenable: castNotifier,
              builder: (context, value, child) {
                return castService.getActiveSessions().isNotEmpty
                    ? const Icon(Icons.cast_connected_rounded)
                    : const Icon(Icons.cast_outlined);
              },
            ),
            onPressed: () async {
              await _castChoiceDialog();
            },
          ),
        ),
      );
    }
    final bool isArchived = widget.collection?.isArchived() ?? false;
    final bool isHidden = widget.collection?.isHidden() ?? false;

    final items = [
      if (galleryType.canRename())
        EntePopupMenuItem(
          isQuickLink
              ? AppLocalizations.of(context).convertToAlbum
              : AppLocalizations.of(context).renameAlbum,
          value: AlbumPopupAction.rename,
          icon: isQuickLink ? Icons.photo_album_outlined : Icons.edit,
        ),
      if (galleryType.canSetCover())
        EntePopupMenuItem(
          AppLocalizations.of(context).setCover,
          value: AlbumPopupAction.setCover,
          icon: Icons.image_outlined,
        ),
      if (galleryType.showMap())
        EntePopupMenuItem(
          AppLocalizations.of(context).map,
          value: AlbumPopupAction.map,
          icon: Icons.map_outlined,
        ),
      if (galleryType.canSort())
        EntePopupMenuItem(
          AppLocalizations.of(context).sortAlbumsBy,
          value: AlbumPopupAction.sort,
          icon: Icons.sort_outlined,
        ),
      if (galleryType == GalleryType.uncategorized)
        EntePopupMenuItem(
          AppLocalizations.of(context).cleanUncategorized,
          value: AlbumPopupAction.cleanUncategorized,
          icon: Icons.crop_original_outlined,
        ),
      if (galleryType.canPin())
        EntePopupMenuItem(
          widget.collection!.isPinned
              ? AppLocalizations.of(context).unpinAlbum
              : AppLocalizations.of(context).pinAlbum,
          value: AlbumPopupAction.pinAlbum,
          iconWidget: widget.collection!.isPinned
              ? const Icon(CupertinoIcons.pin_slash)
              : Transform.rotate(
                  angle: 45 * math.pi / 180, // rotate by 45 degrees
                  child: const Icon(CupertinoIcons.pin),
                ),
        ),
      if (galleryType == GalleryType.locationTag)
        EntePopupMenuItem(
          AppLocalizations.of(context).editLocation,
          value: AlbumPopupAction.editLocation,
          icon: Icons.edit_outlined,
        ),
      if (galleryType == GalleryType.locationTag)
        EntePopupMenuItem(
          AppLocalizations.of(context).deleteLocation,
          value: AlbumPopupAction.deleteLocation,
          icon: Icons.delete_outline,
          iconColor: warning500,
          labelColor: warning500,
        ),
      // Do not show archive option for favorite collection. If collection is
      // already archived, allow user to unarchive that collection.
      if (isArchived || (galleryType.canArchive() && !isHidden))
        EntePopupMenuItem(
          value: AlbumPopupAction.ownedArchive,
          isArchived
              ? AppLocalizations.of(context).unarchiveAlbum
              : AppLocalizations.of(context).archiveAlbum,
          icon: isArchived ? Icons.unarchive : Icons.archive_outlined,
        ),
      if (!isArchived && galleryType.canHide())
        EntePopupMenuItem(
          value: AlbumPopupAction.ownedHide,
          isHidden
              ? AppLocalizations.of(context).unhide
              : AppLocalizations.of(context).hide,
          icon: isHidden
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
        ),
      if (widget.collection != null)
        EntePopupMenuItem(
          value: AlbumPopupAction.playOnTv,
          context.l10n.playOnTv,
          icon: Icons.tv_outlined,
        ),
      if (flagService.hasGrantedMLConsent &&
          (widget.collection?.canAutoAdd(userId) ?? false))
        EntePopupMenuItemAsync(
          (value) => (value?[widget.collection!.id]?.personIDs.isEmpty ?? true)
              ? AppLocalizations.of(context).autoAddPeople
              : AppLocalizations.of(context).editAutoAddPeople,
          value: AlbumPopupAction.autoAddPhotos,
          future: smartAlbumsService.getSmartConfigs,
          iconWidget: (value) => Image.asset(
            (value?[widget.collection!.id]?.personIDs.isEmpty ?? true)
                ? "assets/auto-add-people.png"
                : "assets/edit-auto-add-people.png",
            width: 20,
            height: 20,
            color: EnteTheme.isDark(context) ? Colors.white : Colors.black,
          ),
        ),
      if (galleryType.canDelete())
        EntePopupMenuItem(
          isQuickLink
              ? AppLocalizations.of(context).removeLink
              : AppLocalizations.of(context).deleteAlbum,
          value: isQuickLink
              ? AlbumPopupAction.removeLink
              : AlbumPopupAction.delete,
          icon:
              isQuickLink ? Icons.remove_circle_outline : Icons.delete_outline,
        ),
      if (galleryType == GalleryType.sharedCollection)
        EntePopupMenuItem(
          widget.collection!.hasShareeArchived()
              ? AppLocalizations.of(context).unarchiveAlbum
              : AppLocalizations.of(context).archiveAlbum,
          value: AlbumPopupAction.sharedArchive,
          icon: widget.collection!.hasShareeArchived()
              ? Icons.unarchive
              : Icons.archive_outlined,
        ),
      if (galleryType == GalleryType.sharedCollection)
        EntePopupMenuItem(
          AppLocalizations.of(context).leaveAlbum,
          value: AlbumPopupAction.leave,
          icon: Icons.logout,
        ),
      if (galleryType == GalleryType.localFolder)
        EntePopupMenuItem(
          AppLocalizations.of(context).freeUpDeviceSpace,
          value: AlbumPopupAction.freeUpSpace,
          icon: Icons.delete_sweep_outlined,
        ),
      if (galleryType == GalleryType.sharedPublicCollection &&
          widget.collection!.isDownloadEnabledForPublicLink())
        EntePopupMenuItem(
          AppLocalizations.of(context).download,
          value: AlbumPopupAction.downloadAlbum,
          icon: Platform.isAndroid
              ? Icons.download
              : Icons.cloud_download_outlined,
        ),
    ];

    if (items.isEmpty) {
      return actions;
    }

    actions.add(
      PopupMenuButton(
        itemBuilder: (context) {
          return items;
        },
        onSelected: (AlbumPopupAction value) async {
          if (value == AlbumPopupAction.rename) {
            await _renameAlbum(context);
          } else if (value == AlbumPopupAction.pinAlbum) {
            await updateOrder(
              context,
              widget.collection!,
              widget.collection!.isPinned ? 0 : 1,
            );
            if (mounted) setState(() {});
          } else if (value == AlbumPopupAction.ownedArchive) {
            await archiveOrUnarchive();
          } else if (value == AlbumPopupAction.ownedHide) {
            await hideOrUnhide();
          } else if (value == AlbumPopupAction.delete) {
            await _trashCollection();
          } else if (value == AlbumPopupAction.removeLink) {
            await _removeQuickLink();
          } else if (value == AlbumPopupAction.leave) {
            await _leaveAlbum(context);
          } else if (value == AlbumPopupAction.playOnTv) {
            await _castChoiceDialog();
          } else if (value == AlbumPopupAction.autoAddPhotos) {
            await routeToPage(
              context,
              SmartAlbumPeople(
                collectionId: widget.collection!.id,
              ),
            );
            setState(() {});
          } else if (value == AlbumPopupAction.freeUpSpace) {
            await _deleteBackedUpFiles(context);
          } else if (value == AlbumPopupAction.setCover) {
            await setCoverPhoto(context);
          } else if (value == AlbumPopupAction.sort) {
            await _showSortOption(context);
          } else if (value == AlbumPopupAction.sharedArchive) {
            final hasShareeArchived = widget.collection!.hasShareeArchived();
            final int prevVisiblity =
                hasShareeArchived ? archiveVisibility : visibleVisibility;
            final int newVisiblity =
                hasShareeArchived ? visibleVisibility : archiveVisibility;

            await changeCollectionVisibility(
              context,
              collection: widget.collection!,
              newVisibility: newVisiblity,
              prevVisibility: prevVisiblity,
              isOwner: false,
            );
            if (mounted) {
              setState(() {});
            }
          } else if (value == AlbumPopupAction.map) {
            await showOnMap();
          } else if (value == AlbumPopupAction.cleanUncategorized) {
            await onCleanUncategorizedClick(context);
          } else if (value == AlbumPopupAction.downloadAlbum) {
            await _downloadPublicAlbumToGallery(widget.files!);
          } else if (value == AlbumPopupAction.editLocation) {
            editLocation();
          } else if (value == AlbumPopupAction.deleteLocation) {
            await deleteLocation();
          } else {
            showToast(context, AppLocalizations.of(context).somethingWentWrong);
          }
        },
      ),
    );

    return actions;
  }

  Future<void> _downloadPublicAlbumToGallery(List<EnteFile>? files) async {
    if (files == null || files.isEmpty) {
      return;
    }
    final totalFiles = files.length;
    final dialog = createProgressDialog(
      context,
      "Downloading... 0/$totalFiles",
      isDismissible: false,
    );
    await dialog.show();

    try {
      for (var i = 0; i < files.length; i++) {
        await downloadToGallery(files[i]);
        dialog.update(message: "Downloading... ${i + 1}/$totalFiles");
      }
    } catch (e, s) {
      _logger.severe("Failed to download album", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
    await dialog.hide();
  }

  void editLocation() {
    showEditLocationSheet(
      context,
      InheritedLocationScreenState.of(context).locationTagEntity,
    );
  }

  Future<void> deleteLocation() async {
    try {
      await locationService.deleteLocationTag(
        InheritedLocationScreenState.of(context).locationTagEntity.id,
      );
      Navigator.of(context).pop();
    } catch (e) {
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> onCleanUncategorizedClick(BuildContext buildContext) async {
    final actionResult = await showChoiceActionSheet(
      context,
      isCritical: true,
      title: AppLocalizations.of(context).cleanUncategorized,
      firstButtonLabel: AppLocalizations.of(context).confirm,
      body: AppLocalizations.of(context).cleanUncategorizedDescription,
    );
    if (actionResult?.action != null && mounted) {
      if (actionResult!.action == ButtonAction.first) {
        await collectionActions.removeFromUncatIfPresentInOtherAlbum(
          widget.collection!,
          buildContext,
        );
      }
    }
  }

  Future<void> setCoverPhoto(BuildContext context) async {
    final int? coverPhotoID = await showPickCoverPhotoSheet(
      context,
      widget.collection!,
    );
    if (coverPhotoID != null) {
      unawaited(changeCoverPhoto(context, widget.collection!, coverPhotoID));
    }
  }

  Future<void> showOnMap() async {
    final bool result = await requestForMapEnable(context);
    if (result) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MapScreen(
              filesFutureFn: () async {
                return FilesDB.instance.getAllFilesCollection(
                  widget.collection!.id,
                );
              },
            ),
          ),
        ),
      );
    }
  }

  Future<void> _showSortOption(BuildContext bContext) async {
    final bool? sortByAsc = await showMenu<bool>(
      context: bContext,
      position: RelativeRect.fromLTRB(
        MediaQuery.of(context).size.width,
        kToolbarHeight + 12,
        12,
        0,
      ),
      items: [
        PopupMenuItem(
          value: false,
          child: Text(AppLocalizations.of(context).sortNewestFirst),
        ),
        PopupMenuItem(
          value: true,
          child: Text(AppLocalizations.of(context).sortOldestFirst),
        ),
      ],
    );
    if (sortByAsc != null) {
      unawaited(changeSortOrder(bContext, widget.collection!, sortByAsc));
    }
  }

  Future<void> _trashCollection() async {
    // Fetch the count by-passing the cache to avoid any stale data
    final int count = await CollectionsService.instance.getFileCount(
      widget.collection!,
      useCache: false,
    );
    final bool isEmptyCollection = count == 0;
    if (isEmptyCollection) {
      final dialog = createProgressDialog(
        context,
        AppLocalizations.of(context).pleaseWaitDeletingAlbum,
      );
      await dialog.show();
      try {
        await CollectionsService.instance
            .trashEmptyCollection(widget.collection!);
        await dialog.hide();
        Navigator.of(context).pop();
      } catch (e, s) {
        _logger.warning("failed to trash collection", e, s);
        await dialog.hide();
        await showGenericErrorDialog(context: context, error: e);
      }
    } else {
      final bool result = await collectionActions.deleteCollectionSheet(
        context,
        widget.collection!,
      );
      if (result == true) {
        Navigator.of(context).pop();
      } else {
        debugPrint("No pop");
      }
    }
  }

  Future<void> _removeQuickLink() async {
    try {
      final bool result =
          await CollectionActions(CollectionsService.instance).disableUrl(
        context,
        widget.collection!,
      );
      if (result && mounted) {
        Navigator.of(context).pop();
      }
    } catch (e, s) {
      _logger.severe("failed to trash collection", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _showShareCollectionDialog() async {
    final collection = widget.collection;
    try {
      if (collection == null ||
          (galleryType != GalleryType.ownedCollection &&
              galleryType != GalleryType.sharedCollection &&
              galleryType != GalleryType.hiddenOwnedCollection &&
              galleryType != GalleryType.favorite &&
              !isQuickLink)) {
        throw Exception(
          "Cannot share collection of type $galleryType",
        );
      }
      if (Configuration.instance.getUserID() == widget.collection!.owner.id) {
        unawaited(
          routeToPage(
            context,
            (isQuickLink && (collection.hasLink))
                ? ManageSharedLinkWidget(collection: collection)
                : ShareCollectionPage(collection),
          ),
        );
      } else {
        unawaited(
          routeToPage(
            context,
            AlbumParticipantsPage(collection),
          ),
        );
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _showAddPhotoDialog(BuildContext bContext) async {
    final collection = widget.collection;
    try {
      if (galleryType == GalleryType.sharedPublicCollection &&
          collection!.isCollectEnabledForPublicLink()) {
        final authToken = CollectionsService.instance
            .getSharedPublicAlbumToken(collection.id);
        final albumKey =
            CollectionsService.instance.getSharedPublicAlbumKey(collection.id);

        final res = await showChoiceDialog(
          context,
          title: AppLocalizations.of(context).openAlbumInBrowserTitle,
          firstButtonLabel: AppLocalizations.of(context).openAlbumInBrowser,
          secondButtonLabel: AppLocalizations.of(context).cancel,
          firstButtonType: ButtonType.primary,
        );

        if (res != null && res.action == ButtonAction.first) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => WebPage(
                widget.title ?? "",
                "https://albums.ente.io/?t=$authToken#$albumKey",
              ),
            ),
          );
        }
      } else {
        await showAddPhotosSheet(bContext, collection!);
      }
    } catch (e, s) {
      _logger.severe(e, s);
      await showGenericErrorDialog(context: bContext, error: e);
    }
  }

  Future<void> hideOrUnhide() async {
    final isHidden = widget.collection!.isHidden();
    final int prevVisiblity = isHidden ? hiddenVisibility : visibleVisibility;
    final int newVisiblity = isHidden ? visibleVisibility : hiddenVisibility;

    await changeCollectionVisibility(
      context,
      collection: widget.collection!,
      newVisibility: newVisiblity,
      prevVisibility: prevVisiblity,
    );
    setState(() {});
  }

  Future<void> archiveOrUnarchive() async {
    final isArchived = widget.collection!.isArchived();
    final int prevVisiblity =
        isArchived ? archiveVisibility : visibleVisibility;
    final int newVisiblity = isArchived ? visibleVisibility : archiveVisibility;

    await changeCollectionVisibility(
      context,
      collection: widget.collection!,
      newVisibility: newVisiblity,
      prevVisibility: prevVisiblity,
    );
    setState(() {});
  }

  Future<void> _castChoiceDialog() async {
    final gw = CastGateway(NetworkClient.instance.enteDio);
    if (castService.getActiveSessions().isNotEmpty) {
      await showChoiceDialog(
        context,
        title: AppLocalizations.of(context).stopCastingTitle,
        firstButtonLabel: AppLocalizations.of(context).yes,
        secondButtonLabel: AppLocalizations.of(context).no,
        body: AppLocalizations.of(context).stopCastingBody,
        firstButtonOnTap: () async {
          gw.revokeAllTokens().ignore();
          await castService.closeActiveCasts();
        },
      );
      castNotifier.value++;
      return;
    }

    // stop any existing cast session
    gw.revokeAllTokens().ignore();
    if (!Platform.isAndroid && !kDebugMode) {
      await _pairWithPin(gw, '');
    } else {
      final result = await showDialog<ButtonResult?>(
        context: context,
        barrierDismissible: true,
        useRootNavigator: false,
        builder: (BuildContext context) {
          return const CastChooseDialog();
        },
      );
      if (result == null) {
        return;
      }
      // wait to allow the dialog to close
      await Future.delayed(const Duration(milliseconds: 100));
      if (result.action == ButtonAction.first) {
        await showDialog(
          useRootNavigator: false,
          context: context,
          barrierDismissible: true,
          builder: (BuildContext bContext) {
            return AutoCastDialog(
              (device) async {
                await _castPair(bContext, gw, device);
                Navigator.pop(bContext);
              },
            );
          },
        );
      }
      if (result.action == ButtonAction.second) {
        await _pairWithPin(gw, '');
      }
    }
  }

  Future<void> _pairWithPin(CastGateway gw, String code) async {
    await showTextInputDialog(
      context,
      title: context.l10n.playOnTv,
      body: AppLocalizations.of(context).castInstruction.replaceFirst(
            'cast.ente.io',
            flagService.castUrl,
          ),
      submitButtonLabel: AppLocalizations.of(context).pair,
      textInputType: TextInputType.streetAddress,
      hintText: context.l10n.deviceCodeHint,
      showOnlyLoadingState: true,
      alwaysShowSuccessState: false,
      initialValue: code,
      onSubmit: (String text) async {
        final bool paired = await _castPair(context, gw, text);
        if (!paired) {
          Future.delayed(Duration.zero, () => _pairWithPin(gw, code));
        }
      },
    );
  }

  String lastCode = '';
  Future<bool> _castPair(
    BuildContext bContext,
    CastGateway gw,
    String code,
  ) async {
    try {
      if (lastCode == code) {
        return false;
      }
      lastCode = code;
      _logger.info("Casting album to device with code $code");
      final String? publicKey = await gw.getPublicKey(code);
      if (publicKey == null) {
        showToast(context, AppLocalizations.of(context).deviceNotFound);

        return false;
      }
      final String castToken = const Uuid().v4().toString();
      final castPayload = CollectionsService.instance
          .getCastData(castToken, widget.collection!, publicKey);
      await gw.publishCastPayload(
        code,
        castPayload,
        widget.collection!.id,
        castToken,
      );
      _logger.info("cast album completed");
      // showToast(bContext, AppLocalizations.of(context).pairingComplete);
      castNotifier.value++;
      return true;
    } catch (e, s) {
      lastCode = '';
      _logger.severe("Failed to cast album", e, s);
      if (e is CastIPMismatchException) {
        await showErrorDialog(
          context,
          AppLocalizations.of(context).castIPMismatchTitle,
          AppLocalizations.of(context).castIPMismatchBody,
        );
      } else {
        await showGenericErrorDialog(context: bContext, error: e);
      }
      castNotifier.value++;
      return false;
    }
  }
}
