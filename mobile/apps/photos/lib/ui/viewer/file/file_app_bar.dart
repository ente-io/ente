import "dart:async";
import 'dart:io';

import "package:ente_icons/ente_icons.dart";
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import "package:flutter_svg/flutter_svg.dart";
import "package:local_auth/local_auth.dart";
import 'package:logging/logging.dart';
import 'package:media_extension/media_extension.dart';
import "package:photos/core/configuration.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/l10n/l10n.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/extensions/file_props.dart";
import 'package:photos/models/file/file.dart';
import 'package:photos/models/file/file_type.dart';
import "package:photos/models/file/trash_file.dart";
import "package:photos/models/metadata/common_keys.dart";
import 'package:photos/models/selected_files.dart';
import "package:photos/service_locator.dart";
import 'package:photos/services/collections_service.dart';
import 'package:photos/services/hidden_service.dart';
import "package:photos/services/local_authentication_service.dart";
import "package:photos/services/video_preview_service.dart";
import "package:photos/states/detail_page_state.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import 'package:photos/ui/collections/collection_action_sheet.dart';
import "package:photos/ui/common/popup_item.dart";
import 'package:photos/ui/notification/toast.dart';
import 'package:photos/ui/viewer/actions/suggest_delete_sheet.dart';
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file_details/favorite_widget.dart";
import "package:photos/ui/viewer/file_details/upload_icon_widget.dart";
import 'package:photos/utils/dialog_util.dart';
import "package:photos/utils/file_download_util.dart";
import 'package:photos/utils/file_util.dart';
import "package:photos/utils/magic_util.dart";

class FileAppBar extends StatefulWidget {
  final EnteFile file;
  final Function(EnteFile) onFileRemoved;
  final Function(EnteFile) onEditRequested;
  final ValueNotifier<bool> enableFullScreenNotifier;
  final DetailPageMode mode;

  const FileAppBar(
    this.file,
    this.onFileRemoved,
    this.onEditRequested, {
    required this.enableFullScreenNotifier,
    this.mode = DetailPageMode.full,
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

    // Listen to shared collection and thumbnail fallback changes to rebuild actions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sharedNotifier = InheritedDetailPageState.maybeOf(context)
          ?.isInSharedCollectionNotifier;
      sharedNotifier?.addListener(_onSharedCollectionChanged);

      final fallbackNotifier = InheritedDetailPageState.maybeOf(context)
          ?.showingThumbnailFallbackNotifier;
      fallbackNotifier?.addListener(_onThumbnailFallbackChanged);
    });
  }

  void _onSharedCollectionChanged() {
    if (mounted) {
      setState(() {
        _reloadActions = true;
      });
    }
  }

  void _onThumbnailFallbackChanged() {
    if (mounted) {
      setState(() {
        _reloadActions = true;
      });
    }
  }

  @override
  void dispose() {
    InheritedDetailPageState.maybeOf(context)
        ?.isInSharedCollectionNotifier
        .removeListener(_onSharedCollectionChanged);
    InheritedDetailPageState.maybeOf(context)
        ?.showingThumbnailFallbackNotifier
        .removeListener(_onThumbnailFallbackChanged);
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
    final shouldShowActions = !isGuestView;
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
                actions: shouldShowActions ? _actions : [],
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

    // Show info icon when thumbnail fallback is active for THIS file
    final fallbackFileId = InheritedDetailPageState.maybeOf(context)
        ?.showingThumbnailFallbackNotifier
        .value;
    final showingFallback = fallbackFileId == widget.file.generatedID;
    if (showingFallback) {
      _actions.add(
        Tooltip(
          message:
              "Your device doesn't support this image format. Showing a preview instead.",
          triggerMode: TooltipTriggerMode.tap,
          showDuration: const Duration(seconds: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: backgroundElevated2Dark,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontSize: 14,
          ),
          preferBelow: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(12.0),
              child: Icon(Icons.info_outline),
            ),
          ),
        ),
      );
    }

    final bool isOwnedByUser = widget.file.isOwner;
    final bool isFileUploaded = widget.file.isUploaded;
    final int? collectionID = widget.file.collectionID;
    final Collection? collection = collectionID != null
        ? CollectionsService.instance.getCollectionByID(collectionID)
        : null;
    final isInSharedCollection = InheritedDetailPageState.maybeOf(context)
            ?.isInSharedCollectionNotifier
            .value ??
        false;
    bool isFileHidden = false;
    if (isOwnedByUser && isFileUploaded) {
      isFileHidden = collection?.isHidden() ?? false;
    }
    final bool canSuggestDeleteAction = canSuggestDeleteForFile(
      file: widget.file,
      collection: collection,
    );
    if (widget.file.isLiveOrMotionPhoto) {
      _actions.add(
        IconButton(
          icon: const Icon(Icons.album_outlined),
          onPressed: () {
            showShortToast(
              context,
              AppLocalizations.of(context).pressAndHoldToPlayVideoDetailed,
            );
          },
        ),
      );
    }
    if (!isFileHidden && isFileUploaded && widget.file is! TrashFile) {
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
    final bool restrictFileActions =
        widget.mode == DetailPageMode.minimalistic || widget.file is TrashFile;

    if (restrictFileActions) {
      items.add(
        EntePopupMenuItem(
          AppLocalizations.of(context).info,
          value: 12,
          icon: Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
          iconColor: Theme.of(context).iconTheme.color,
        ),
      );
    } else {
      if (widget.file.isRemoteFile) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).download,
            value: 1,
            icon: Platform.isAndroid
                ? Icons.download
                : Icons.cloud_download_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }
      // Edit option for images, live photos, and videos
      if (widget.file.fileType == FileType.image ||
          widget.file.fileType == FileType.livePhoto ||
          widget.file.fileType == FileType.video) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).edit,
            value: 11,
            icon: Icons.tune_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }
      // Add to Album option - shown when file is in shared collection
      // (moved from bottom bar to make room for social icons)
      if (isInSharedCollection && isFileUploaded && !isFileHidden) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).addToAlbum,
            value: 10,
            icon: EnteIcons.addToAlbum,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }
      // options for files owned by the user
      if (isOwnedByUser && !isFileHidden && isFileUploaded) {
        final bool isArchived =
            widget.file.magicMetadata.visibility == archiveVisibility;
        items.add(
          EntePopupMenuItem(
            isArchived
                ? AppLocalizations.of(context).unarchive
                : AppLocalizations.of(context).archive,
            value: 2,
            icon: isArchived ? Icons.unarchive : Icons.archive_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }

      if ((widget.file.fileType == FileType.image ||
              widget.file.fileType == FileType.livePhoto) &&
          Platform.isAndroid) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).setAs,
            value: 3,
            icon: Icons.wallpaper_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }
      if (isOwnedByUser && widget.file.isUploaded) {
        if (!isFileHidden) {
          items.add(
            EntePopupMenuItem(
              AppLocalizations.of(context).hide,
              value: 4,
              icon: Icons.visibility_off,
              iconColor: Theme.of(context).iconTheme.color,
            ),
          );
        } else {
          items.add(
            EntePopupMenuItem(
              AppLocalizations.of(context).unhide,
              value: 5,
              icon: Icons.visibility,
              iconColor: Theme.of(context).iconTheme.color,
            ),
          );
        }
      }

      items.add(
        EntePopupMenuItem(
          AppLocalizations.of(context).guestView,
          value: 6,
          iconWidget: SvgPicture.asset(
            "assets/icons/guest_view_icon.svg",
            colorFilter: ColorFilter.mode(
              getEnteColorScheme(context).textBase,
              BlendMode.srcIn,
            ),
          ),
        ),
      );

      if (canSuggestDeleteAction) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).suggestDeletion,
            value: 13,
            icon: Icons.flag_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }

      items.add(
        EntePopupMenuItem(
          AppLocalizations.of(context).info,
          value: 12,
          icon: Platform.isAndroid ? Icons.info_outline : CupertinoIcons.info,
          iconColor: Theme.of(context).iconTheme.color,
        ),
      );
    }

    if (widget.file.isVideo && !restrictFileActions) {
      // Video streaming options
      if (_shouldShowCreateStreamOption()) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).createStream,
            value: 8,
            icon: Icons.video_settings_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }

      if (_shouldShowRecreateStreamOption()) {
        items.add(
          EntePopupMenuItem(
            AppLocalizations.of(context).recreateStream,
            value: 9,
            icon: Icons.refresh_outlined,
            iconColor: Theme.of(context).iconTheme.color,
          ),
        );
      }

      items.add(
        EntePopupMenuItem(
          shouldLoopVideo
              ? AppLocalizations.of(context).loopVideoOn
              : AppLocalizations.of(context).loopVideoOff,
          value: 7,
          iconWidget: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                Icons.loop_rounded,
                color: Theme.of(context).iconTheme.color,
              ),
              shouldLoopVideo
                  ? Transform.rotate(
                      angle: 3.14 / 4,
                      child: Container(
                        width: 2,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Theme.of(context).iconTheme.color,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ),
      );
    }

    if (items.isNotEmpty) {
      _actions.add(
        PopupMenuButton(
          tooltip: MaterialLocalizations.of(context).moreButtonTooltip,
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
            } else if (value == 8) {
              await _handleVideoStream('create');
            } else if (value == 9) {
              await _handleVideoStream('recreate');
            } else if (value == 11) {
              widget.onEditRequested(widget.file);
            } else if (value == 12) {
              await showDetailsSheet(context, widget.file);
            } else if (value == 13) {
              if (collection != null) {
                await _handleSuggestDelete(collection);
              }
            } else if (value == 10) {
              final selectedFiles = SelectedFiles();
              selectedFiles.files.add(widget.file);
              showCollectionActionSheet(
                context,
                selectedFiles: selectedFiles,
                actionType: CollectionActionType.addFiles,
              );
            }
          },
        ),
      );
    }

    return _actions;
  }

  Future<void> _handleSuggestDelete(Collection collection) async {
    if (widget.file.uploadedFileID == null) {
      return;
    }
    await showSuggestDeleteSheet(
      context: context,
      onConfirm: () async {
        await CollectionsService.instance.suggestDeleteFromCollection(
          collection.id,
          [widget.file],
        );
        widget.onFileRemoved(widget.file);
      },
    );
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
      setState(() {
        _reloadActions = true;
      });
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
      showToast(context, AppLocalizations.of(context).fileSavedToGallery);
      await dialog.hide();
    } catch (e) {
      _logger.warning("Failed to save file", e);
      await dialog.hide();
      await showGenericErrorDialog(context: context, error: e);
    }
  }

  Future<void> _setAs(EnteFile file) async {
    final dialog =
        createProgressDialog(context, AppLocalizations.of(context).pleaseWait);
    await dialog.show();
    try {
      final File? fileToSave = await (getFile(file));
      if (fileToSave == null) {
        throw Exception("Fail to get file for setAs operation");
      }
      final m = MediaExtension();
      final bool result = await m.setAs("file://${fileToSave.path}", "image/*");
      if (result == false) {
        showShortToast(
          context,
          AppLocalizations.of(context).somethingWentWrong,
        );
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
        AppLocalizations.of(context).noSystemLockFound,
        AppLocalizations.of(context).guestViewEnablePreSteps,
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

  bool _shouldShowCreateStreamOption() {
    // Show "Create Stream" option for uploaded video files without streams
    return _ensureBasicRequirements() &&
        !fileDataService.previewIds.containsKey(widget.file.uploadedFileID!);
  }

  bool _shouldShowRecreateStreamOption() {
    // Show "Recreate Stream" option for uploaded video files with existing streams
    return _ensureBasicRequirements() &&
        fileDataService.previewIds.containsKey(widget.file.uploadedFileID!);
  }

  bool _ensureBasicRequirements() {
    // Skip if sv=1 (server indicates streaming not needed)
    final userId = Configuration.instance.getUserID();
    return widget.file.fileType == FileType.video &&
        widget.file.isUploaded &&
        widget.file.fileSize != null &&
        (widget.file.pubMagicMetadata?.sv ?? 0) != 1 &&
        widget.file.ownerID == userId &&
        VideoPreviewService.instance.isVideoStreamingEnabled;
  }

  Future<void> _handleVideoStream(String streamType) async {
    try {
      final bool wasAdded = await VideoPreviewService.instance
          .addToManualQueue(widget.file, streamType);

      if (!wasAdded) {
        // File was already in queue
        showToast(
          context,
          AppLocalizations.of(context).videoAlreadyInQueue,
        );
        return;
      }

      showToast(context, AppLocalizations.of(context).addedToQueue);

      if (mounted) {
        setState(() {
          _reloadActions = true;
        });
      }
    } catch (e, s) {
      _logger.severe("Failed to $streamType video stream", e, s);
      await showGenericErrorDialog(context: context, error: e);
    }
  }
}
