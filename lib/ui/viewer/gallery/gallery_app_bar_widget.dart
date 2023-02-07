import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/services/update_service.dart';
import 'package:photos/ui/actions/collection/collection_sharing_actions.dart';
// import 'package:photos/ui/common/rename_dialog.dart';
import 'package:photos/ui/components/action_sheet_widget.dart';
import 'package:photos/ui/components/button_widget.dart';
import 'package:photos/ui/components/dialog_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/sharing/album_participants_page.dart';
import 'package:photos/ui/sharing/share_collection_page.dart';
import 'package:photos/ui/tools/free_space_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';

class GalleryAppBarWidget extends StatefulWidget {
  final GalleryType type;
  final String? title;
  final SelectedFiles selectedFiles;
  final DeviceCollection? deviceCollection;
  final Collection? collection;

  const GalleryAppBarWidget(
    this.type,
    this.title,
    this.selectedFiles, {
    Key? key,
    this.deviceCollection,
    this.collection,
  }) : super(key: key);

  @override
  State<GalleryAppBarWidget> createState() => _GalleryAppBarWidgetState();
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  final _logger = Logger("GalleryAppBar");
  late StreamSubscription _userAuthEventSubscription;
  late Function() _selectedFilesListener;
  String? _appBarTitle;
  late CollectionActions collectionActions;
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  void initState() {
    _selectedFilesListener = () {
      setState(() {});
    };
    collectionActions = CollectionActions(CollectionsService.instance);
    widget.selectedFiles.addListener(_selectedFilesListener);
    _userAuthEventSubscription =
        Bus.instance.on<SubscriptionPurchasedEvent>().listen((event) {
      setState(() {});
    });
    _appBarTitle = widget.title;
    super.initState();
  }

  @override
  void dispose() {
    _userAuthEventSubscription.cancel();
    widget.selectedFiles.removeListener(_selectedFilesListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.type == GalleryType.homepage
        ? const SizedBox.shrink()
        : AppBar(
            backgroundColor: widget.type == GalleryType.homepage
                ? const Color(0x00000000)
                : null,
            elevation: 0,
            centerTitle: false,
            title: widget.type == GalleryType.homepage
                ? const SizedBox.shrink()
                : TextButton(
                    child: Text(
                      _appBarTitle!,
                      style: Theme.of(context)
                          .textTheme
                          .headline5!
                          .copyWith(fontSize: 16),
                    ),
                    onPressed: () => _renameAlbum(context),
                  ),
            actions: _getDefaultActions(context),
          );
  }

  Future<dynamic> _renameAlbum(BuildContext context) async {
    if (widget.type != GalleryType.ownedCollection) {
      return;
    }
    final result = await showTextInputDialog(
      context,
      title: "Rename album",
      confirmationButtonLabel: "Rename",
      hintText: "Enter album name",
      onConfirm: (String text) async {
        // indicates user cancelled the rename request
        if (text == "" || text.trim() == _appBarTitle!.trim()) {
          return;
        }

        try {
          await CollectionsService.instance.rename(widget.collection!, text);
          if (mounted) {
            _appBarTitle = text;
            setState(() {});
          }
        } catch (e) {
          rethrow;
        }
      },
    );
    if (result == ButtonAction.error) {
      showGenericErrorDialog(context: context);
    }
  }

  Future<dynamic> _leaveAlbum(BuildContext context) async {
    final ButtonAction? result = await showActionSheet(
      context: context,
      buttons: [
        ButtonWidget(
          buttonType: ButtonType.critical,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          buttonAction: ButtonAction.first,
          shouldSurfaceExecutionStates: true,
          labelText: "Leave album",
          onTap: () async {
            await CollectionsService.instance.leaveAlbum(widget.collection!);
          },
        ),
        const ButtonWidget(
          buttonType: ButtonType.secondary,
          buttonAction: ButtonAction.cancel,
          isInAlert: true,
          shouldStickToDarkTheme: true,
          labelText: "Cancel",
        )
      ],
      title: "Leave shared album?",
      body: "Photos added by you will be removed from the album",
    );
    if (result != null && mounted) {
      if (result == ButtonAction.error) {
        showGenericErrorDialog(context: context);
      } else if (result == ButtonAction.first) {
        Navigator.of(context).pop();
      }
    }
  }

  // todo: In the new design, clicking on free up space will directly open
  // the free up space page and show loading indicator while calculating
  // the space which can be claimed up. This code duplication should be removed
  // whenever we move to the new design for free up space.
  Future<dynamic> _deleteBackedUpFiles(BuildContext context) async {
    final dialog = createProgressDialog(context, "Calculating...");
    await dialog.show();
    BackupStatus status;
    try {
      status = await SyncService.instance
          .getBackupStatus(pathID: widget.deviceCollection!.id);
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context: context);
      return;
    }

    await dialog.hide();
    if (status.localIDs.isEmpty) {
      showErrorDialog(
        context,
        "✨ All clear",
        "You've no files in this album that can be deleted",
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
    final DialogWidget dialog = choiceDialog(
      title: "Success",
      body: "You have successfully freed up " + formatBytes(status.size) + "!",
      firstButtonLabel: "Rate us",
      firstButtonOnTap: () async {
        UpdateService.instance.launchReviewUrl();
      },
      firstButtonType: ButtonType.primary,
      secondButtonLabel: "OK",
      secondButtonOnTap: () async {
        if (Platform.isIOS) {
          showToast(
            context,
            "Also empty \"Recently Deleted\" from \"Settings\" -> \"Storage\" to claim the freed space",
          );
        }
      },
    );

    showConfettiDialog(
      context: context,
      dialogBuilder: (BuildContext context) {
        return dialog;
      },
      barrierColor: Colors.black87,
      confettiAlignment: Alignment.topCenter,
      useRootNavigator: true,
    );
  }

  List<Widget> _getDefaultActions(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    if (Configuration.instance.hasConfiguredAccount() &&
        widget.selectedFiles.files.isEmpty &&
        (widget.type == GalleryType.ownedCollection ||
            widget.type == GalleryType.sharedCollection) &&
        widget.collection?.type != CollectionType.favorites) {
      actions.add(
        Tooltip(
          message: "Share",
          child: IconButton(
            icon: const Icon(Icons.people_outlined),
            onPressed: () async {
              await _showShareCollectionDialog();
            },
          ),
        ),
      );
    }
    final List<PopupMenuItem> items = [];
    if (widget.type == GalleryType.ownedCollection) {
      if (widget.collection!.type != CollectionType.favorites) {
        items.add(
          PopupMenuItem(
            value: 1,
            child: Row(
              children: const [
                Icon(Icons.edit),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Rename album"),
              ],
            ),
          ),
        );
      }
      final bool isArchived = widget.collection!.isArchived();
      // Do not show archive option for favorite collection. If collection is
      // already archived, allow user to unarchive that collection.
      if (isArchived || widget.collection!.type != CollectionType.favorites) {
        items.add(
          PopupMenuItem(
            value: 2,
            child: Row(
              children: [
                Icon(isArchived ? Icons.unarchive : Icons.archive_outlined),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(isArchived ? "Unarchive album" : "Archive album"),
              ],
            ),
          ),
        );
      }
      if (widget.collection!.type != CollectionType.favorites) {
        items.add(
          PopupMenuItem(
            value: 3,
            child: Row(
              children: const [
                Icon(Icons.delete_outline),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Delete album"),
              ],
            ),
          ),
        );
      }
    } // ownedCollection open ends

    if (widget.type == GalleryType.sharedCollection) {
      items.add(
        PopupMenuItem(
          value: 4,
          child: Row(
            children: const [
              Icon(Icons.logout),
              Padding(
                padding: EdgeInsets.all(8),
              ),
              Text("Leave album"),
            ],
          ),
        ),
      );
    }
    if (widget.type == GalleryType.localFolder) {
      items.add(
        PopupMenuItem(
          value: 5,
          child: Row(
            children: const [
              Icon(Icons.delete_sweep_outlined),
              Padding(
                padding: EdgeInsets.all(8),
              ),
              Text("Free up device space"),
            ],
          ),
        ),
      );
    }
    if (items.isNotEmpty) {
      actions.add(
        PopupMenuButton(
          itemBuilder: (context) {
            return items;
          },
          onSelected: (dynamic value) async {
            if (value == 1) {
              await _renameAlbum(context);
            } else if (value == 2) {
              await changeCollectionVisibility(
                context,
                widget.collection!,
                widget.collection!.isArchived()
                    ? visibilityVisible
                    : visibilityArchive,
              );
            } else if (value == 3) {
              await _trashCollection();
            } else if (value == 4) {
              await _leaveAlbum(context);
            } else if (value == 5) {
              await _deleteBackedUpFiles(context);
            } else {
              showToast(context, "Something went wrong");
            }
          },
        ),
      );
    }

    return actions;
  }

  Future<void> _trashCollection() async {
    final collectionWithThumbnail =
        await CollectionsService.instance.getCollectionsWithThumbnails();
    final bool isEmptyCollection = collectionWithThumbnail
            .firstWhereOrNull(
              (element) => element.collection.id == widget.collection!.id,
            )
            ?.thumbnail ==
        null;
    if (isEmptyCollection) {
      final dialog = createProgressDialog(
        context,
        "Please wait, deleting album",
      );
      await dialog.show();
      try {
        await CollectionsService.instance
            .trashEmptyCollection(widget.collection!);
        await dialog.hide();
        Navigator.of(context).pop();
      } catch (e, s) {
        _logger.severe("failed to trash collection", e, s);
        await dialog.hide();
        showGenericErrorDialog(context: context);
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

  Future<void> _showShareCollectionDialog() async {
    final collection = widget.collection;
    try {
      if (collection == null ||
          (widget.type != GalleryType.ownedCollection &&
              widget.type != GalleryType.sharedCollection)) {
        throw Exception(
          "Cannot share empty collection of typex ${widget.type}",
        );
      }
      if (Configuration.instance.getUserID() == widget.collection!.owner!.id) {
        unawaited(
          routeToPage(
            context,
            ShareCollectionPage(collection),
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
      showGenericErrorDialog(context: context);
    }
  }
}
