import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/db/files_db.dart";
import "package:photos/models/collection/collection.dart";
import "package:photos/models/file/extensions/file_props.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/services/collections_service.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";

const _greenHeartColor = Color(0xFF08C225);

/// Holds collection info with mutable like state for the selector
class _CollectionLikeState {
  final Collection collection;
  final EnteFile? thumbnail;
  bool isLiked;

  _CollectionLikeState({
    required this.collection,
    this.thumbnail,
    required this.isLiked,
  });
}

/// Shows the like collection selector bottom sheet
///
/// Parameters:
/// - [fileID]: The uploaded file ID to like
/// - [currentUserID]: Current user's ID for checking existing likes
/// - [file]: The EnteFile for displaying thumbnail (optional, will fetch if null)
Future<void> showLikeCollectionSelectorSheet(
  BuildContext context, {
  required int fileID,
  required int currentUserID,
  EnteFile? file,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => LikeCollectionSelectorSheet(
      fileID: fileID,
      currentUserID: currentUserID,
      file: file,
    ),
  );
}

class LikeCollectionSelectorSheet extends StatefulWidget {
  final int fileID;
  final int currentUserID;
  final EnteFile? file;

  const LikeCollectionSelectorSheet({
    required this.fileID,
    required this.currentUserID,
    this.file,
    super.key,
  });

  @override
  State<LikeCollectionSelectorSheet> createState() =>
      _LikeCollectionSelectorSheetState();
}

class _LikeCollectionSelectorSheetState
    extends State<LikeCollectionSelectorSheet> {
  static const _maxHeightFraction = 0.7;

  List<_CollectionLikeState> _collections = [];
  EnteFile? _file;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _file = widget.file;
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Load file if not provided (for thumbnail)
      _file ??= await FilesDB.instance.getAnyUploadedFile(widget.fileID);

      // Get all collections containing this file
      final collectionIDs = await FilesDB.instance.getAllCollectionIDsOfFile(
        widget.fileID,
      );

      // Filter to shared collections only
      final sharedCollections = collectionIDs
          .map((id) => CollectionsService.instance.getCollectionByID(id))
          .whereType<Collection>()
          .where(
            (c) =>
                c.hasSharees || c.hasLink || !c.isOwner(widget.currentUserID),
          )
          .toList();

      // If no shared collections, close the sheet
      if (sharedCollections.isEmpty) {
        if (mounted) Navigator.of(context).pop();
        return;
      }

      // Fetch thumbnails and like states in parallel
      final collectionStates = await Future.wait(
        sharedCollections.map((collection) async {
          final thumbnail =
              await CollectionsService.instance.getCover(collection);
          final reactions = await SocialDataProvider.instance
              .getReactionsForFileInCollection(widget.fileID, collection.id);
          final isLiked = reactions.any(
            (r) => r.userID == widget.currentUserID && !r.isDeleted,
          );
          return _CollectionLikeState(
            collection: collection,
            thumbnail: thumbnail,
            isLiked: isLiked,
          );
        }),
      );

      if (!mounted) return;

      setState(() {
        _collections = collectionStates;
        _isLoading = false;
      });
    } catch (e, s) {
      debugPrint("Error loading like selector data: $e\n$s");
      if (mounted) {
        setState(() {
          _hasError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleLike(_CollectionLikeState state) async {
    final previousState = state.isLiked;
    // Optimistic UI update
    setState(() => state.isLiked = !state.isLiked);

    try {
      await SocialDataProvider.instance.toggleReaction(
        userID: widget.currentUserID,
        collectionID: state.collection.id,
        fileID: widget.fileID,
      );
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() => state.isLiked = previousState);
      }
      debugPrint("Failed to toggle like: $e");
    }
  }

  Future<void> _likeAll() async {
    // Get collections that aren't already liked
    final toLike = _collections.where((c) => !c.isLiked).toList();

    if (toLike.isEmpty) {
      // All already liked, just close
      Navigator.of(context).pop();
      return;
    }

    // Optimistic UI update
    setState(() {
      for (final c in toLike) {
        c.isLiked = true;
      }
    });

    // Track failures for rollback
    final failed = <_CollectionLikeState>[];

    // Perform all likes in parallel
    await Future.wait(
      toLike.map((c) async {
        try {
          await SocialDataProvider.instance.toggleReaction(
            userID: widget.currentUserID,
            collectionID: c.collection.id,
            fileID: widget.fileID,
          );
        } catch (e) {
          failed.add(c);
          debugPrint("Failed to like ${c.collection.displayName}: $e");
        }
      }),
    );

    if (!mounted) return;

    // Rollback failed items and show toast
    if (failed.isNotEmpty) {
      setState(() {
        for (final c in failed) {
          c.isLiked = false;
        }
      });
      final msg = failed.length == 1
          ? "Failed to like 1 album"
          : "Failed to like ${failed.length} albums";
      showShortToast(context, msg);
      // Don't close sheet - let user retry
      return;
    }

    // Close sheet after successful "Like all"
    Navigator.of(context).pop();
  }

  bool get _isVideo => _file?.isVideo ?? false;

  String get _subtitle => _isVideo
      ? "Select the album to like this video"
      : "Select the album to like this photo";

  bool get _allLiked => _collections.every((c) => c.isLiked);

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * _maxHeightFraction,
      ),
      decoration: BoxDecoration(
        color: colorScheme.backgroundBase,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDragHandle(colorScheme),
            _buildHeader(),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: CircularProgressIndicator(),
              )
            else if (_hasError)
              _buildErrorState()
            else ...[
              _buildFileThumbnail(colorScheme),
              _buildTitleSection(),
              _buildAlbumsHeader(),
              Flexible(child: _buildAlbumsList()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDragHandle(EnteColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: colorScheme.strokeMuted,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButtonWidget(
            iconButtonType: IconButtonType.rounded,
            icon: Icons.close_rounded,
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildFileThumbnail(EnteColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _file != null
                    ? ThumbnailWidget(
                        _file!,
                        thumbnailSize: thumbnailLargeSize,
                        rawThumbnail: true,
                      )
                    : Container(color: colorScheme.fillMuted),
              ),
              const Positioned(
                bottom: -8,
                right: -8,
                child: Icon(
                  Icons.favorite,
                  color: _greenHeartColor,
                  size: 36,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        children: [
          Text(
            "Like",
            style: textTheme.largeBold,
          ),
          const SizedBox(height: 4),
          Text(
            _subtitle,
            style: textTheme.small.copyWith(color: colorScheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsHeader() {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_collections.length} ${_collections.length == 1 ? 'Album' : 'Albums'}",
            style: textTheme.bodyBold,
          ),
          GestureDetector(
            onTap: _likeAll,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colorScheme.fillFaint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Like all",
                    style: textTheme.smallBold,
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _allLiked ? Icons.favorite : Icons.favorite_border,
                    color: _allLiked ? _greenHeartColor : colorScheme.textBase,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumsList() {
    return ListView.builder(
      shrinkWrap: _collections.length <= 10,
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        final state = _collections[index];
        return _AlbumListItem(
          key: ValueKey(state.collection.id),
          state: state,
          onTap: () => _toggleLike(state),
        );
      },
    );
  }

  Widget _buildErrorState() {
    final textTheme = getEnteTextTheme(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Text(
        "Could not load albums",
        style: textTheme.smallMuted,
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _AlbumListItem extends StatelessWidget {
  final _CollectionLikeState state;
  final VoidCallback onTap;

  const _AlbumListItem({
    required this.state,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: state.thumbnail != null
                    ? ThumbnailWidget(state.thumbnail!)
                    : Container(color: colorScheme.fillMuted),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                state.collection.displayName,
                style: textTheme.body,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              state.isLiked ? Icons.favorite : Icons.favorite_border,
              color: state.isLiked ? _greenHeartColor : colorScheme.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
