// @dart=2.9

import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:page_transition/page_transition.dart';
import 'package:photos/core/configuration.dart';
import 'package:photos/core/event_bus.dart';
import 'package:photos/ente_theme_data.dart';
import 'package:photos/events/subscription_purchased_event.dart';
import 'package:photos/models/collection.dart';
import 'package:photos/models/gallery_type.dart';
import 'package:photos/models/magic_metadata.dart';
import 'package:photos/models/selected_files.dart';
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/feature_flag_service.dart';
import 'package:photos/services/hidden_service.dart';
import 'package:photos/ui/create_collection_page.dart';
import 'package:photos/utils/delete_file_util.dart';
import 'package:photos/utils/dialog_util.dart';
import 'package:photos/utils/magic_util.dart';
import 'package:photos/utils/share_util.dart';
import 'package:photos/utils/toast_util.dart';

class GalleryOverlayWidget extends StatefulWidget {
  final GalleryType type;
  final SelectedFiles selectedFiles;
  final String path;
  final Collection collection;

  const GalleryOverlayWidget(
    this.type,
    this.selectedFiles, {
    this.path,
    this.collection,
    Key key,
  }) : super(key: key);

  @override
  State<GalleryOverlayWidget> createState() => _GalleryOverlayWidgetState();
}

class _GalleryOverlayWidgetState extends State<GalleryOverlayWidget> {
  StreamSubscription _userAuthEventSubscription;
  Function() _selectedFilesListener;
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
    final bool filesAreSelected = widget.selectedFiles.files.isNotEmpty;
    final bottomPadding = Platform.isAndroid ? 0.0 : 12.0;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: filesAreSelected ? 108 : 0,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: filesAreSelected ? 1.0 : 0.0,
          curve: Curves.easeIn,
          child: IgnorePointer(
            ignoring: !filesAreSelected,
            child: OverlayWidget(
              widget.type,
              widget.selectedFiles,
              path: widget.path,
              collection: widget.collection,
            ),
          ),
        ),
      ),
    );
  }
}

class OverlayWidget extends StatefulWidget {
  final GalleryType type;
  final SelectedFiles selectedFiles;
  final String path;
  final Collection collection;

  const OverlayWidget(
    this.type,
    this.selectedFiles, {
    this.path,
    this.collection,
    Key key,
  }) : super(key: key);

  @override
  State<OverlayWidget> createState() => _OverlayWidgetState();
}

class _OverlayWidgetState extends State<OverlayWidget> {
  final _logger = Logger("GalleryOverlay");
  StreamSubscription _userAuthEventSubscription;
  Function() _selectedFilesListener;
  final GlobalKey shareButtonKey = GlobalKey();
  bool enableBeta = false;

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
    enableBeta = FeatureFlagService.instance.isInternalUserOrDebugBuild();
    return Container(
      color: Colors.transparent,
      child: ListView(
        //ListView is for animation to work without render overflow
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: Theme.of(context)
                        .colorScheme
                        .frostyBlurBackdropFilterColor,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(13, 13, 0, 13),
                          child: Text(
                            widget.selectedFiles.files.length.toString() +
                                ' selected',
                            style: Theme.of(context)
                                .textTheme
                                .subtitle2
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color:
                                      Theme.of(context).colorScheme.iconColor,
                                ),
                          ),
                        ),
                        Row(
                          children: _getActions(context),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 8)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: GestureDetector(
                  onTap: _clearSelectedFiles,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      //height: 32,
                      width: 86,
                      color: Theme.of(context)
                          .colorScheme
                          .frostyBlurBackdropFilterColor,
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: Theme.of(context).textTheme.subtitle2.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.iconColor,
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _clearSelectedFiles() {
    widget.selectedFiles.clearAll();
  }

  Future<void> _createCollectionAction(CollectionActionType type) async {
    Navigator.push(
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

  Future<void> _moveFiles() async {
    Navigator.push(
      context,
      PageTransition(
        type: PageTransitionType.bottomToTop,
        child: CreateCollectionPage(
          widget.selectedFiles,
          null,
          actionType: CollectionActionType.moveFiles,
        ),
      ),
    );
  }

  List<Widget> _getActions(BuildContext context) {
    final List<Widget> actions = <Widget>[];
    if (widget.type == GalleryType.trash) {
      _addTrashAction(actions);
      return actions;
    }
    final List<PopupMenuItem<String>> items = [];
    // skip add button for incoming collection till this feature is implemented
    if (Configuration.instance.hasConfiguredAccount() &&
        widget.type != GalleryType.sharedCollection &&
        widget.type != GalleryType.hidden) {
      String msg = "Add to album";
      IconData iconData = Platform.isAndroid ? Icons.add : CupertinoIcons.add;
      // show upload icon instead of add for files selected in local gallery
      if (widget.type == GalleryType.localFolder) {
        msg = "Upload to album";
        iconData = Icons.cloud_upload_outlined;
      }
      items.add(
        PopupMenuItem(
          value: "add",
          child: Row(
            children: [
              Icon(iconData),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              Text(msg),
            ],
          ),
        ),
      );
    }

    if (Configuration.instance.hasConfiguredAccount() &&
        widget.type == GalleryType.hidden) {
      String msg = "Unhide";
      IconData iconData = Icons.visibility;
      actions.add(
        Tooltip(
          message: msg,
          child: IconButton(
            color: Theme.of(context).colorScheme.iconColor,
            icon: Icon(iconData),
            onPressed: () {
              _createCollectionAction(CollectionActionType.unHide);
            },
          ),
        ),
      );
    }
    if (Configuration.instance.hasConfiguredAccount() &&
        widget.type == GalleryType.ownedCollection &&
        widget.collection.type != CollectionType.favorites) {
      items.add(
        PopupMenuItem(
          value: "move",
          child: Row(
            children: const [
              Icon(Icons.arrow_forward),
              Padding(
                padding: EdgeInsets.all(8),
              ),
              Text("Move to album"),
            ],
          ),
        ),
      );
    }
    actions.add(
      Tooltip(
        message: "Share",
        child: IconButton(
          color: Theme.of(context).colorScheme.iconColor,
          key: shareButtonKey,
          icon: Icon(Platform.isAndroid ? Icons.share : CupertinoIcons.share),
          onPressed: () {
            _shareSelected(context);
          },
        ),
      ),
    );
    if (widget.type == GalleryType.homepage ||
        widget.type == GalleryType.archive ||
        widget.type == GalleryType.hidden ||
        widget.type == GalleryType.localFolder ||
        widget.type == GalleryType.searchResults) {
      actions.add(
        Tooltip(
          message: "Delete",
          child: IconButton(
            color: Theme.of(context).colorScheme.iconColor,
            icon:
                Icon(Platform.isAndroid ? Icons.delete : CupertinoIcons.delete),
            onPressed: () {
              _showDeleteSheet(context);
            },
          ),
        ),
      );
    } else if (widget.type == GalleryType.ownedCollection) {
      if (widget.collection.type == CollectionType.folder) {
        actions.add(
          Tooltip(
            message: "Delete",
            child: IconButton(
              color: Theme.of(context).colorScheme.iconColor,
              icon: Icon(
                Platform.isAndroid ? Icons.delete : CupertinoIcons.delete,
              ),
              onPressed: () {
                _showDeleteSheet(context);
              },
            ),
          ),
        );
      } else {
        actions.add(
          Tooltip(
            message: "Remove",
            child: IconButton(
              color: Theme.of(context).colorScheme.iconColor,
              icon: const Icon(
                Icons.remove_circle_rounded,
              ),
              onPressed: () {
                _showRemoveFromCollectionSheet(context);
              },
            ),
          ),
        );
      }
    }

    if (widget.type == GalleryType.homepage ||
        widget.type == GalleryType.archive) {
      final bool showArchive = widget.type == GalleryType.homepage;
      if (showArchive) {
        items.add(
          PopupMenuItem(
            value: "archive",
            child: Row(
              children: const [
                Icon(Icons.archive_outlined),
                Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text("Archive"),
              ],
            ),
          ),
        );
      } else {
        actions.insert(
          0,
          Tooltip(
            message: 'Unarchive',
            child: IconButton(
              color: Theme.of(context).colorScheme.iconColor,
              icon: const Icon(
                Icons.unarchive,
              ),
              onPressed: () {
                onActionSelected('unarchive');
              },
            ),
          ),
        );
      }
    }

    if ((widget.type == GalleryType.homepage ||
            widget.type == GalleryType.ownedCollection) &&
        enableBeta) {
      items.add(
        PopupMenuItem(
          value: "hide",
          child: Row(
            children: const [
              Icon(Icons.visibility_off),
              Padding(
                padding: EdgeInsets.all(8),
              ),
              Text("Hide"),
            ],
          ),
        ),
      );
    }
    if (items.isNotEmpty) {
      actions.add(
        PopupMenuButton<String>(
          color: Theme.of(context)
              .colorScheme
              .enteTheme
              .colorScheme
              .backgroundElevated2,
          offset: Offset(0, (items.length * -48.0) - 16),
          // color: Theme.of(context).colorScheme.frostyBlurBackdropFilterColor,
          onSelected: onActionSelected,
          itemBuilder: (context) {
            return items;
          },
        ),
      );
    }
    return actions;
  }

  Future<void> onActionSelected(String value) async {
    debugPrint("Action Selected $value");
    switch (value.toLowerCase()) {
      case 'hide':
        await _handleHideRequest(context);
        break;
      case 'add':
        await _createCollectionAction(CollectionActionType.addFiles);
        break;
      case 'move':
        await _moveFiles();
        break;
      case 'archive':
        await _handleVisibilityChangeRequest(context, visibilityArchive);
        break;
      case 'unarchive':
        await _handleVisibilityChangeRequest(context, visibilityVisible);
        break;
      default:
        break;
    }
  }

  void _addTrashAction(List<Widget> actions) {
    actions.add(
      Tooltip(
        message: "Restore",
        child: IconButton(
          color: Theme.of(context).colorScheme.iconColor,
          icon: const Icon(
            Icons.restore,
          ),
          onPressed: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.bottomToTop,
                child: CreateCollectionPage(
                  widget.selectedFiles,
                  null,
                  actionType: CollectionActionType.restoreFiles,
                ),
              ),
            );
          },
        ),
      ),
    );
    actions.add(
      Tooltip(
        message: "Delete permanently",
        child: IconButton(
          color: Theme.of(context).colorScheme.iconColor,
          icon: const Icon(
            Icons.delete_forever,
          ),
          onPressed: () async {
            if (await deleteFromTrash(
              context,
              widget.selectedFiles.files.toList(),
            )) {
              _clearSelectedFiles();
            }
          },
        ),
      ),
    );
  }

  Future<void> _handleVisibilityChangeRequest(
    BuildContext context,
    int newVisibility,
  ) async {
    try {
      await changeVisibility(
        context,
        widget.selectedFiles.files.toList(),
        newVisibility,
      );
    } catch (e, s) {
      _logger.severe("failed to update file visibility", e, s);
      await showGenericErrorDialog(context);
    } finally {
      _clearSelectedFiles();
    }
  }

  Future<void> _handleHideRequest(BuildContext context) async {
    try {
      final hideResult = await CollectionsService.instance
          .hideFiles(context, widget.selectedFiles.files.toList());
      if (hideResult) {
        _clearSelectedFiles();
      }
    } catch (e, s) {
      _logger.severe("failed to update file visibility", e, s);
      await showGenericErrorDialog(context);
    }
  }

  void _shareSelected(BuildContext context) {
    share(
      context,
      widget.selectedFiles.files.toList(),
      shareButtonKey: shareButtonKey,
    );
  }

  void _showDeleteSheet(BuildContext context) {
    final count = widget.selectedFiles.files.length;
    bool containsUploadedFile = false, containsLocalFile = false;
    for (final file in widget.selectedFiles.files) {
      if (file.uploadedFileID != null) {
        containsUploadedFile = true;
      }
      if (file.localID != null) {
        containsLocalFile = true;
      }
    }
    final actions = <Widget>[];
    if (containsUploadedFile && containsLocalFile) {
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesOnDeviceOnly(
              context,
              widget.selectedFiles.files.toList(),
            );
            _clearSelectedFiles();
            showToast(context, "Files deleted from device");
          },
          child: const Text("Device"),
        ),
      );
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromRemoteOnly(
              context,
              widget.selectedFiles.files.toList(),
            );
            _clearSelectedFiles();
            showShortToast(context, "Moved to trash");
          },
          child: const Text("ente"),
        ),
      );
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromEverywhere(
              context,
              widget.selectedFiles.files.toList(),
            );
            _clearSelectedFiles();
          },
          child: const Text("Everywhere"),
        ),
      );
    } else {
      actions.add(
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            await deleteFilesFromEverywhere(
              context,
              widget.selectedFiles.files.toList(),
            );
            _clearSelectedFiles();
          },
          child: const Text("Delete"),
        ),
      );
    }
    final action = CupertinoActionSheet(
      title: Text(
        "Delete " +
            count.toString() +
            " file" +
            (count == 1 ? "" : "s") +
            (containsUploadedFile && containsLocalFile ? " from" : "?"),
      ),
      actions: actions,
      cancelButton: CupertinoActionSheetAction(
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(
      context: context,
      builder: (_) => action,
      barrierColor: Colors.black.withOpacity(0.75),
    );
  }

  void _showRemoveFromCollectionSheet(BuildContext context) {
    final count = widget.selectedFiles.files.length;
    final action = CupertinoActionSheet(
      title: Text(
        "Remove " +
            count.toString() +
            " file" +
            (count == 1 ? "" : "s") +
            " from " +
            widget.collection.name +
            "?",
      ),
      actions: <Widget>[
        CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () async {
            Navigator.of(context, rootNavigator: true).pop();
            final dialog = createProgressDialog(context, "Removing files...");
            await dialog.show();
            try {
              await CollectionsService.instance.removeFromCollection(
                widget.collection.id,
                widget.selectedFiles.files.toList(),
              );
              await dialog.hide();
              widget.selectedFiles.clearAll();
            } catch (e, s) {
              _logger.severe(e, s);
              await dialog.hide();
              showGenericErrorDialog(context);
            }
          },
          child: const Text("Remove"),
        ),
      ],
      cancelButton: CupertinoActionSheetAction(
        child: const Text("Cancel"),
        onPressed: () {
          Navigator.of(context, rootNavigator: true).pop();
        },
      ),
    );
    showCupertinoModalPopup(context: context, builder: (_) => action);
  }
}
