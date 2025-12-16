import "dart:async";
import "dart:io";

import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:logging/logging.dart";
import "package:photos/core/event_bus.dart";
import "package:photos/events/guest_view_event.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/file/trash_file.dart";
import "package:photos/models/selected_files.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/ui/actions/file/file_actions.dart";
import "package:photos/ui/collections/collection_action_sheet.dart";
import "package:photos/ui/social/comments_screen.dart";
import "package:photos/utils/delete_file_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/panorama_util.dart";
import "package:photos/utils/share_util.dart";

class FileBottomBar extends StatefulWidget {
  final EnteFile file;
  final Function(EnteFile) onFileRemoved;
  final int? userID;
  final ValueNotifier<bool> enableFullScreenNotifier;
  final bool isLocalOnlyContext;

  const FileBottomBar(
    this.file, {
    required this.onFileRemoved,
    required this.enableFullScreenNotifier,
    this.userID,
    this.isLocalOnlyContext = false,
    super.key,
  });

  @override
  FileBottomBarState createState() => FileBottomBarState();
}

class FileBottomBarState extends State<FileBottomBar> {
  final GlobalKey shareButtonKey = GlobalKey();
  bool isGuestView = false;
  late final StreamSubscription<GuestViewEvent> _guestViewEventSubscription;
  int? lastFileGenID;
  Future<bool>? _isFileInSharedCollectionFuture;
  bool _hasLiked = false;
  int _commentCount = 0;

  @override
  void initState() {
    super.initState();
    _updateSharedCollectionFuture();
    _updateSocialState();
    _guestViewEventSubscription =
        Bus.instance.on<GuestViewEvent>().listen((event) {
      setState(() {
        isGuestView = event.isGuestView;
      });
    });
  }

  @override
  void didUpdateWidget(FileBottomBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.file.uploadedFileID != widget.file.uploadedFileID) {
      _updateSharedCollectionFuture();
      _updateSocialState();
    }
  }

  void _updateSharedCollectionFuture() {
    if (widget.file.uploadedFileID != null) {
      _isFileInSharedCollectionFuture =
          CollectionsService.instance.isFileInSharedCollection(
        widget.file.uploadedFileID!,
      );
    } else {
      _isFileInSharedCollectionFuture = null;
    }
  }

  Future<void> _updateSocialState() async {
    if (widget.file.uploadedFileID == null) {
      _hasLiked = false;
      _commentCount = 0;
      return;
    }

    final fileID = widget.file.uploadedFileID!;
    final provider = SocialDataProvider.instance;

    // Check if user has liked
    final reactions = await provider.getReactionsForFile(fileID);
    _hasLiked = reactions.any(
      (r) => r.userID == widget.userID && !r.isDeleted,
    );

    // Get comment count
    _commentCount = await provider.getCommentCountForFile(fileID);

    safeRefresh();
  }

  @override
  void dispose() {
    _guestViewEventSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.canBePanorama()) {
      lastFileGenID = widget.file.generatedID;
      if (lastFileGenID != widget.file.generatedID) {
        guardedCheckPanorama(widget.file).ignore();
      }
    }

    return _getBottomBar();
  }

  void safeRefresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _getBottomBar() {
    Logger("FileBottomBar")
        .fine("building bottom bar ${widget.file.generatedID}");

    final List<Widget> children = [];
    final bool isOwnedByUser =
        widget.file.ownerID == null || widget.file.ownerID == widget.userID;
    if (widget.file is TrashFile) {
      _addTrashOptions(children);
    }

    if (widget.file is! TrashFile) {
      if (isOwnedByUser) {
        children.add(
          Tooltip(
            message: AppLocalizations.of(context).delete,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: IconButton(
                icon: Icon(
                  Platform.isAndroid
                      ? Icons.delete_outline
                      : CupertinoIcons.delete,
                  color: Colors.white,
                ),
                onPressed: () async {
                  await _showSingleFileDeleteSheet(widget.file);
                },
              ),
            ),
          ),
        );
      }

      children.add(
        Tooltip(
          message: AppLocalizations.of(context).share,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: IconButton(
              key: shareButtonKey,
              icon: Icon(
                Platform.isAndroid
                    ? Icons.share_outlined
                    : CupertinoIcons.share,
                color: Colors.white,
              ),
              onPressed: () {
                share(context, [widget.file], shareButtonKey: shareButtonKey);
              },
            ),
          ),
        ),
      );

      // Add social icons (heart, comment) if file is in a shared collection
      if (widget.file.uploadedFileID != null) {
        children.add(_buildHeartIcon());
        children.add(_buildCommentIcon());
      }
    }
    return ValueListenableBuilder(
      valueListenable: widget.enableFullScreenNotifier,
      builder: (BuildContext context, bool isFullScreen, _) {
        return IgnorePointer(
          ignoring: isFullScreen || isGuestView,
          child: AnimatedOpacity(
            opacity: isFullScreen || isGuestView ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.72),
                    ],
                    stops: const [0, 0.8, 1],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  left: false,
                  right: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: children,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showSingleFileDeleteSheet(EnteFile file) async {
    await showSingleFileDeleteSheet(
      context,
      file,
      onFileRemoved: widget.onFileRemoved,
      isLocalOnlyContext: widget.isLocalOnlyContext,
    );
  }

  void _addTrashOptions(List<Widget> children) {
    children.add(
      Tooltip(
        message: AppLocalizations.of(context).restore,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            icon: const Icon(
              Icons.restore_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              final selectedFiles = SelectedFiles();
              selectedFiles.toggleSelection(widget.file);
              showCollectionActionSheet(
                context,
                selectedFiles: selectedFiles,
                actionType: CollectionActionType.restoreFiles,
              );
            },
          ),
        ),
      ),
    );

    children.add(
      Tooltip(
        message: AppLocalizations.of(context).delete,
        child: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: IconButton(
            icon: const Icon(
              Icons.delete_forever_outlined,
              color: Colors.white,
            ),
            onPressed: () async {
              final trashedFile = <TrashFile>[];
              trashedFile.add(widget.file as TrashFile);
              if (await deleteFromTrash(context, trashedFile) == true) {
                Navigator.pop(context);
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeartIcon() {
    if (_isFileInSharedCollectionFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _isFileInSharedCollectionFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: GestureDetector(
            onTap: _toggleReaction,
            child: Icon(
              _hasLiked
                  ? (Platform.isAndroid
                      ? Icons.favorite
                      : Icons.favorite_rounded)
                  : (Platform.isAndroid
                      ? Icons.favorite_border
                      : Icons.favorite_border_rounded),
              color: _hasLiked ? const Color(0xFF08C225) : Colors.white,
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleReaction() async {
    final file = widget.file;
    if (file.uploadedFileID == null ||
        file.collectionID == null ||
        widget.userID == null) {
      return;
    }

    await SocialDataProvider.instance.toggleReaction(
      userID: widget.userID!,
      collectionID: file.collectionID!,
      fileID: file.uploadedFileID,
    );

    _hasLiked = !_hasLiked;
    safeRefresh();
  }

  Widget _buildCommentIcon() {
    if (_isFileInSharedCollectionFuture == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<bool>(
      future: _isFileInSharedCollectionFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: _openCommentsScreen,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedBubbleChat,
                  color: Colors.white,
                ),
                if (_commentCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                          strokeAlign: BorderSide.strokeAlignOutside,
                        ),
                      ),
                      child: Text(
                        _commentCount > 99 ? '99+' : _commentCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openCommentsScreen() {
    final file = widget.file;
    if (file.collectionID == null) return;

    routeToPage(
      context,
      CommentsScreen(
        collectionID: file.collectionID!,
        fileID: file.uploadedFileID,
      ),
    ).then((_) {
      // Refresh comment count when returning from comments screen
      _updateSocialState();
    });
  }
}
