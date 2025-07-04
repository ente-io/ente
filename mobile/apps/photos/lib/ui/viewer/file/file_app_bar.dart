import "dart:async";
import 'dart:io';

import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension.dart';
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import 'package:photos/models/file/trash_file.dart';
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import "package:photos/services/local_authentication_service.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/theme/ente_theme.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import 'package:photos/ui/notification/toast.dart';
import "package:photos/ui/viewer/file_details/favorite_widget.dart";
import "package:photos/ui/viewer/file_details/upload_icon_widget.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/file_download_util.dart";
import 'package:photos/utils/file_util.dart';
import "package:photos/utils/magic_util.dart";

class FileAppBar extends StatefulWidget {
  final EnteFile file;
  final Function(EnteFile) onFileRemoved;
  final bool shouldShowActions;
  final ValueNotifier<bool> enableFullScreenNotifier;

  const FileAppBar(
    this.file,
    this.onFileRemoved,
    this.shouldShowActions, {
    required this.enableFullScreenNotifier,
    super.key,
  });

  @override
  FileAppBarState createState() => FileAppBarState();
}

class FileAppBarState extends State<FileAppBar> {
  final _logger = Logger("FadingAppBar");
  final List<Widget> _actions = [];
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  bool isGuestView = false;
  bool shouldLoopVideo = localSettings.shouldLoopVideo();
  bool _reloadActions = false;

  @override
  void didUpdateWidget(FileAppBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.generatedID != widget.file.generatedID) {
      _getActions();
    }
  }

  @override
  void initState() {
    super.initState();
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
      });
    });
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.info("building app bar ${widget.file.generatedID?.toString()}");

    //When the widget is initialized, the actions are not available.
    //Cannot call _getActions() in initState.
    if (_actions.isEmpty || _reloadActions) {
      _getActions();
      _reloadActions = false;
    }

    final isTrashedFile = widget.file is TrashFile;
    final shouldShowActions = widget.shouldShowActions && !isTrashedFile;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: ValueListenableBuilder(
        valueListenable: widget.enableFullScreenNotifier,
        builder: (context, bool isFullScreen, child) {
          return IgnorePointer(
            ignoring: isFullScreen,
            child: AnimatedOpacity(
              opacity: isFullScreen ? 0 : 1,
              duration: const Duration(milliseconds: 150),
              child: child,
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.72),
                Colors.black.withValues(alpha: 0.6),
                Colors.transparent,
              ],
              stops: const [0, 0.2, 1],
            ),
          ),
          child: SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: AppBar(
                clipBehavior: Clip.none,
                key: ValueKey(isGuestView),
                iconTheme: const IconThemeData(
                  color: Colors.white,
                ), //same for both themes
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    isGuestView
                        ? _requestAuthentication()
                        : Navigator.of(context).pop();
                  },
                ),
                actions: shouldShowActions && !isGuestView ? _actions : [],
                elevation: 0,
                backgroundColor: const Color(0x00000000),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _getActions() {
    _actions.clear();
    final bool isOwnedByUser = widget.file.isOwner;
    final bool isFileUploaded = widget.file.isUploaded;
    bool isFileHidden = false;
    if (isOwnedByUser && isFileUploaded) {
      isFileHidden = CollectionsService.instance
              .getCollectionByID(widget.file.collectionID!)
              ?.isHidden() ??
          false;
    }
    if (widget.file.isLiveOrMotionPhoto) {
      _actions.add(
        IconButton(
          icon: const Icon(Icons.album_outlined),
          onPressed: () {
            showShortToast(
              context,
              S.of(context).pressAndHoldToPlayVideoDetailed,
            );
          },
        ),
      );
    }
    if (!isFileHidden && isFileUploaded) {
      _actions.add(
        Center(child: FavoriteWidget(widget.file)),
      );
    }
    if (!isFileUploaded) {
      _actions.add(
        UploadIconWidget(
          file: widget.file,
          key: ValueKey(widget.file.tag),
        ),
      );
    }

    final List<PopupMenuItem> items = [];
    if (widget.file.isRemoteFile) {
      items.add(
        PopupMenuItem(
          value: 1,
          child: Row(
            children: [
              Icon(
                Platform.isAndroid
                    ? Icons.download
                    : Icons.cloud_download_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              Text(S.of(context).download),
            ],
          ),
        ),
      );
    }
    // options for files owned by the user
    if (isOwnedByUser && !isFileHidden && isFileUploaded) {
      final bool isArchived =
          widget.file.magicMetadata.visibility == archiveVisibility;
      items.add(
        PopupMenuItem(
          value: 2,
          child: Row(
            children: [
              Icon(
                isArchived ? Icons.unarchive : Icons.archive_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              Text(
                isArchived ? S.of(context).unarchive : S.of(context).archive,
              ),
            ],
          ),
        ),
      );
    }
    if ((widget.file.fileType == FileType.image ||
            widget.file.fileType == FileType.livePhoto) &&
        Platform.isAndroid) {
      items.add(
        PopupMenuItem(
          value: 3,
          child: Row(
            children: [
              Icon(
                Icons.wallpaper_outlined,
                color: Theme.of(context).iconTheme.color,
              ),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              Text(S.of(context).setAs),
            ],
          ),
        ),
      );
    }
    if (isOwnedByUser && widget.file.isUploaded) {
      if (!isFileHidden) {
        items.add(
          PopupMenuItem(
            value: 4,
            child: Row(
              children: [
                Icon(
                  Icons.visibility_off,
                  color: Theme.of(context).iconTheme.color,
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(S.of(context).hide),
              ],
            ),
          ),
        );
      } else {
        items.add(
          PopupMenuItem(
            value: 5,
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: Theme.of(context).iconTheme.color,
                ),
                const Padding(
                  padding: EdgeInsets.all(8),
                ),
                Text(S.of(context).unhide),
              ],
            ),
          ),
        );
      }
    }

    items.add(
      PopupMenuItem(
        value: 6,
        child: Row(
          children: [
            SvgPicture.asset(
              "assets/icons/guest_view_icon.svg",
              colorFilter: ColorFilter.mode(
                getEnteColorScheme(context).textBase,
                BlendMode.srcIn,
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(8),
            ),
            Text(S.of(context).guestView),
          ],
        ),
      ),
    );

    if (widget.file.isVideo) {
      items.add(
        PopupMenuItem(
          value: 7,
          child: Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.loop_rounded,
                    color: Theme.of(context).iconTheme.color,
                  ),
                  shouldLoopVideo
                      ? const SizedBox.shrink()
                      : Transform.rotate(
                          angle: 3.14 / 4,
                          child: Container(
                            width: 2,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).iconTheme.color,
                              borderRadius: BorderRadius.circular(1),
                            ),
                          ),
                        ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.all(8),
              ),
              shouldLoopVideo
                  ? Text(S.of(context).loopVideoOn)
                  : Text(S.of(context).loopVideoOff),
            ],
          ),
        ),
      );
    }

    if (items.isNotEmpty) {
      _actions.add(
        PopupMenuButton(
          itemBuilder: (context) {
            return items;
          },
          onSelected: (dynamic value) async {
            if (value == 1) {
              await _download(widget.file);
            } else if (value == 2) {
              await _toggleFileArchiveStatus(widget.file);
            } else if (value == 3) {
              await _setAs(widget.file);
            } else if (value == 4) {
              await _handleHideRequest(context);
            } else if (value == 5) {
              await _handleUnHideRequest(context);
            } else if (value == 6) {
              await _onTapGuestView();
            } else if (value == 99) {
              try {
                await VideoPreviewService.instance.chunkAndUploadVideo(
                  context,
                  widget.file,
                );
              } catch (e) {
                if (mounted) {
                  await showGenericErrorDialog(context: context, error: e);
                }
              }
            } else if (value == 7) {
              _onToggleLoopVideo();
            }
          },
        ),
      );
    }
    return _actions;
  }

  _onToggleLoopVideo() {
    localSettings.setShouldLoopVideo(!shouldLoopVideo);
    setState(() {
      _reloadActions = true;
      shouldLoopVideo = !shouldLoopVideo;
    });
  }

  Future<void> _handleHideRequest(BuildContext context) async {
    try {
      final hideResult =
          await CollectionsService.instance.hideFiles(context, [widget.file]);
      if (hideResult) {
        widget.onFileRemoved(widget.file);
      }
    } catch (e, s) {
      _logger.severe("failed to update file visibility", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _handleUnHideRequest(BuildContext context) async {
    final selectedFiles = SelectedFiles();
    selectedFiles.files.add(widget.file);
    showCollectionActionSheet(
      context,
      selectedFiles: selectedFiles,
      actionType: CollectionActionType.unHide,
    );
  }

  Future<void> _toggleFileArchiveStatus(EnteFile file) async {
    final bool isArchived =
        widget.file.magicMetadata.visibility == archiveVisibility;
    await changeVisibility(
      context,
      [widget.file],
      isArchived ? visibleVisibility : archiveVisibility,
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _download(EnteFile file) async {
    final dialog = createProgressDialog(
      context,
      context.l10n.downloading,
      isDismissible: true,
    );
    await dialog.show();
    try {
      await downloadToGallery(file);
      showToast(context, S.of(context).fileSavedToGallery);
      await dialog.hide();
    } catch (e) {
      _logger.warning("Failed to save file", e);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _setAs(EnteFile file) async {
    final dialog = createProgressDialog(context, S.of(context).pleaseWait);
    await dialog.show();
    try {
      final File? fileToSave = await (getFile(file));
      if (fileToSave == null) {
        throw Exception("Fail to get file for setAs operation");
      }
      final m = MediaExtension();
      final bool result = await m.setAs("file://${fileToSave.path}", "image/*");
      if (result == false) {
        showShortToast(context, S.of(context).somethingWentWrong);
      }
      await dialog.hide();
    } catch (e) {
      await dialog.hide();
      _logger.severe("Failed to use as", e);
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _onTapGuestView() async {
    if (await LocalAuthentication().isDeviceSupported()) {
      Bus.instance.fire(GuestViewEvent(true, true));
      await localSettings.setOnGuestView(true);
    } else {
      await showErrorDialog(
        context,
        S.of(context).noSystemLockFound,
        S.of(context).guestViewEnablePreSteps,
      );
    }
  }

  Future<void> _requestAuthentication() async {
    final hasAuthenticated =
        await LocalAuthenticationService.instance.requestLocalAuthentication(
      context,
      "Please authenticate to view more photos and videos.",
    );
    if (hasAuthenticated) {
      Bus.instance.fire(GuestViewEvent(false, false));
      await localSettings.setOnGuestView(false);
    }
  }
}
