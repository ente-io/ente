// @dart=2.9

import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/backup_status.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/device_collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/sync_service.dart';
import 'package:photos/ui/common/dialogs.dart';
import 'package:photos/ui/common/rename_dialog.dart';
import 'package:photos/ui/sharing/share_collection_widget.dart';
import 'package:photos/ui/tools/free_space_page.dart';
import 'package:photos/utils/data_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/toast_util.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GalleryAppBarWidget extends StatefulWidget {
  final GalleryType type;
  final String title;
  final SelectedFiles selectedFiles;
  final DeviceCollection deviceCollection;
  final Collection collection;

  const GalleryAppBarWidget(
    this.type,
    this.title,
    this.selectedFiles, {
    Key key,
    this.deviceCollection,
    this.collection,
  }) : super(key: key);

  @override
  State<GalleryAppBarWidget> createState() => _GalleryAppBarWidgetState();
}

class _GalleryAppBarWidgetState extends State<GalleryAppBarWidget> {
  final _logger = Logger("GalleryAppBar");
  StreamSubscription _userAuthEventSubscription;
  Function() _selectedFilesListener;
  String _appBarTitle;
  final GlobalKey shareButtonKey = GlobalKey();

  @override
  void initState() {
    _selectedFilesListener = () {
      setState(() {});
    };
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
                      _appBarTitle,
                      style: Theme.of(context)
                          .textTheme
                          .headline5
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
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return RenameDialog(_appBarTitle, 'Album');
      },
      barrierColor: Colors.black.withOpacity(0.85),
    );
    // indicates user cancelled the rename request
    if (result == null || result.trim() == _appBarTitle.trim()) {
      return;
    }

    final dialog = createProgressDialog(context, "Changing name...");
    await dialog.show();
    try {
      await CollectionsService.instance.rename(widget.collection, result);
      await dialog.hide();
      if (mounted) {
        _appBarTitle = result;
        setState(() {});
      }
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<dynamic> _leaveAlbum(BuildContext context) async {
    final DialogUserChoice result = await showChoiceDialog(
      context,
      "Leave shared album?",
      "You will leave the album, and it will stop being visible to you.",
      firstAction: "Cancel",
      secondAction: "Yes, Leave",
      secondActionColor:
          Theme.of(context).colorScheme.enteTheme.colorScheme.warning700,
    );
    if (result != DialogUserChoice.secondChoice) {
      return;
    }
    final dialog = createProgressDialog(context, "Leaving album...");
    await dialog.show();
    try {
      await CollectionsService.instance.leaveAlbum(widget.collection);
      await dialog.hide();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
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
          .getBackupStatus(pathID: widget.deviceCollection.id);
    } catch (e) {
      await dialog.hide();
      showGenericErrorDialog(context);
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
      final bool result = await routeToPage(
        context,
        FreeSpacePage(status, clearSpaceForFolder: true),
      );
      if (result == true) {
        _showSpaceFreedDialog(status);
      }
    }
  }

  void _showSpaceFreedDialog(BackupStatus status) {
    final AlertDialog alert = AlertDialog(
      title: const Text("Success"),
      content: Text(
        "You have successfully freed up " + formatBytes(status.size) + "!",
      ),
      actions: [
        TextButton(
          child: Text(
            "Rate us",
            style: TextStyle(
              color: Theme.of(context).colorScheme.greenAlternative,
            ),
          ),
          onPressed: () {
            Navigator.of(context, rootNavigator: true).pop('dialog');
            // TODO: Replace with https://pub.dev/packages/in_app_review
            if (Platform.isAndroid) {
              launchUrlString(
                "https://play.google.com/store/apps/details?id=io.ente.photos",
              );
            } else {
              launchUrlString(
                "https://apps.apple.com/in/app/ente-photos/id1542026904",
              );
            }
          },
        ),
        TextButton(
          child: const Text(
            "Ok",
          ),
          onPressed: () {
            if (Platform.isIOS) {
              showToast(
                context,
                "Also empty \"Recently Deleted\" from \"Settings\" -> \"Storage\" to claim the freed space",
              );
            }
            Navigator.of(context, rootNavigator: true).pop('dialog');
          },
        ),
      ],
    );
    showConfettiDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
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
        widget.type == GalleryType.ownedCollection) {
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
      if (widget.collection.type != CollectionType.favorites) {
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
      final bool isArchived = widget.collection.isArchived();
      // Do not show archive option for favorite collection. If collection is
      // already archived, allow user to unarchive that collection.
      if (isArchived || widget.collection.type != CollectionType.favorites) {
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
      if (widget.collection.type != CollectionType.favorites) {
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
          onSelected: (value) async {
            if (value == 1) {
              await _renameAlbum(context);
            } else if (value == 2) {
              await changeCollectionVisibility(
                context,
                widget.collection,
                widget.collection.isArchived()
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
              (element) => element.collection.id == widget.collection.id,
            )
            ?.thumbnail ==
        null;
    if (!isEmptyCollection) {
      final result = await showChoiceDialog(
        context,
        "Delete album?",
        "Files that are unique to this album "
            "will be moved to trash, and this album will be deleted.",
        firstAction: "Cancel",
        secondAction: "Delete album",
        secondActionColor: Colors.red,
      );
      if (result != DialogUserChoice.secondChoice) {
        return;
      }
    }
    final dialog = createProgressDialog(
      context,
      "Please wait, deleting album",
    );
    await dialog.show();
    try {
      await CollectionsService.instance
          .trashCollection(widget.collection, isEmptyCollection);
      showShortToast(context, "Successfully deleted album");
      await dialog.hide();
      Navigator.of(context).pop();
    } catch (e, s) {
      _logger.severe("failed to trash collection", e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }

  Future<void> _showShareCollectionDialog() async {
    var collection = widget.collection;
    final dialog = createProgressDialog(context, "Please wait...");
    await dialog.show();
    try {
      if (collection == null || widget.type != GalleryType.ownedCollection) {
        throw Exception(
          "Cannot share empty collection of type ${widget.type}",
        );
      } else {
        final sharees =
            await CollectionsService.instance.getSharees(collection.id);
        collection = collection.copyWith(sharees: sharees);
      }
      await dialog.hide();
      return showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return SharingDialog(
            collection,
          );
        },
      );
    } catch (e, s) {
      _logger.severe(e, s);
      await dialog.hide();
      showGenericErrorDialog(context);
    }
  }
}
