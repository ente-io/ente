import "dart:async";

import "package:ente_pure_utils/ente_pure_utils.dart";
import "package:flutter/material.dart";
import "package:logging/logging.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/social/feed_data_provider.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/social/comments_screen.dart";
import "package:photos/ui/social/widgets/feed_item_widget.dart";
import "package:photos/ui/viewer/file/detail_page.dart";

final _logger = Logger("FeedScreen");

class FeedNavigationTarget {
  final FeedItemType type;
  final int collectionID;
  final int? fileID;
  final String? commentID;

  const FeedNavigationTarget({
    required this.type,
    required this.collectionID,
    this.fileID,
    this.commentID,
  });

  static FeedNavigationTarget? fromUri(Uri uri) {
    final typeRaw = uri.queryParameters['type'];
    final collectionRaw = uri.queryParameters['collectionID'];
    if (typeRaw == null || collectionRaw == null) {
      _logger.warning("Invalid feed URI: missing type or collectionID in $uri");
      return null;
    }
    final collectionID = int.tryParse(collectionRaw);
    if (collectionID == null) {
      _logger
          .warning("Invalid feed URI: invalid collectionID '$collectionRaw'");
      return null;
    }
    FeedItemType type;
    try {
      type = FeedItemType.values.byName(typeRaw);
    } catch (_) {
      _logger.warning("Invalid feed URI: unknown type '$typeRaw'");
      return null;
    }
    final fileIDRaw = uri.queryParameters['fileID'];
    final fileID = fileIDRaw != null && fileIDRaw.isNotEmpty
        ? int.tryParse(fileIDRaw)
        : null;
    final commentIDRaw = uri.queryParameters['commentID'];
    final commentID =
        commentIDRaw != null && commentIDRaw.isNotEmpty ? commentIDRaw : null;
    return FeedNavigationTarget(
      type: type,
      collectionID: collectionID,
      fileID: fileID,
      commentID: commentID,
    );
  }
}

/// Screen that displays the user's activity feed.
///
/// Shows likes, comments, and replies on the user's photos and comments.
class FeedScreen extends StatefulWidget {
  final FeedNavigationTarget? initialTarget;

  const FeedScreen({
    super.key,
    this.initialTarget,
  });

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  late final int _currentUserID;
  FeedNavigationTarget? _pendingNavigationTarget;
  bool _didHandleNavigationTarget = false;
  bool _isOpeningNavigationTarget = false;

  /// Map of collectionID -> (anonUserID -> displayName)
  Map<int, Map<String, String>> _anonDisplayNamesByCollection = {};

  @override
  void initState() {
    super.initState();
    _currentUserID = Configuration.instance.getUserID() ?? 0;
    _pendingNavigationTarget = widget.initialTarget;
    _loadFeedItems();
  }

  Future<void> _loadFeedItems() async {
    setState(() => _isLoading = true);

    // Load local data first
    final items = await FeedDataProvider.instance.getFeedItems(limit: 50);

    // Load anon display names for all collections in feed
    final anonNames = await _loadAnonDisplayNames(items);

    if (mounted) {
      setState(() {
        _feedItems = items;
        _anonDisplayNamesByCollection = anonNames;
        _isLoading = false;
      });
    }
    _tryOpenNavigationTarget();

    // Sync in background and refresh
    unawaited(_syncAndRefresh());
  }

  Future<Map<int, Map<String, String>>> _loadAnonDisplayNames(
    List<FeedItem> items,
  ) async {
    final collectionIDs = items.map((e) => e.collectionID).toSet();
    final results = <int, Map<String, String>>{};

    await Future.wait(
      collectionIDs.map((collectionID) async {
        final names = await SocialDataProvider.instance
            .getAnonDisplayNamesForCollection(collectionID);
        results[collectionID] = names;
      }),
    );

    return results;
  }

  Future<void> _syncAndRefresh() async {
    try {
      await FeedDataProvider.instance.syncAllSharedCollections();

      if (!mounted) return;

      // Reload feed items after sync
      final freshItems =
          await FeedDataProvider.instance.getFeedItems(limit: 50);

      // Reload anon display names for new items
      final freshAnonNames = await _loadAnonDisplayNames(freshItems);

      if (mounted) {
        setState(() {
          _feedItems = freshItems;
          _anonDisplayNamesByCollection = freshAnonNames;
        });
      }
      _tryOpenNavigationTarget();
    } catch (_) {
      // Ignore sync errors, local data is already displayed
    }
  }

  Future<void> _onRefresh() async {
    await _syncAndRefresh();
  }

  void _tryOpenNavigationTarget() {
    if (_didHandleNavigationTarget || _isOpeningNavigationTarget) {
      return;
    }
    final target = _pendingNavigationTarget;
    if (target == null) return;
    _isOpeningNavigationTarget = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _isOpeningNavigationTarget = false;
        return;
      }
      final opened = await _openNavigationTarget(target);
      if (opened && mounted) {
        _didHandleNavigationTarget = true;
      }
      _isOpeningNavigationTarget = false;
    });
  }

  Future<bool> _openNavigationTarget(FeedNavigationTarget target) async {
    if (!mounted) return false;
    if (target.type == FeedItemType.photoLike) {
      final fileID = target.fileID;
      if (fileID == null) return false;
      final file = await FilesDB.instance.getUploadedFile(
        fileID,
        target.collectionID,
      );
      if (file == null || !mounted) return false;
      unawaited(
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              [file],
              0,
              "feed_item",
            ),
          ),
          forceCustomPageRoute: true,
        ),
      );
      return true;
    }

    var fileID = target.fileID;
    if (fileID == null && target.commentID != null) {
      final comment =
          await SocialDataProvider.instance.getCommentById(target.commentID!);
      fileID = comment?.fileID;
    }
    if (fileID == null) return false;
    final file = await FilesDB.instance.getUploadedFile(
      fileID,
      target.collectionID,
    );
    if (file == null || !mounted) return false;
    final capturedFileID = fileID;
    final highlightID = target.commentID;
    unawaited(
      routeToPage(
        context,
        DetailPage(
          DetailPageConfiguration(
            [file],
            0,
            "feed_comment",
            onPageReady: (detailContext) {
              showFileCommentsBottomSheet(
                detailContext,
                collectionID: target.collectionID,
                fileID: capturedFileID,
                highlightCommentID: highlightID,
              );
            },
          ),
        ),
        forceCustomPageRoute: true,
      ),
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? null : const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: isDark ? null : const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: false,
        leading: IconButtonWidget(
          iconButtonType: IconButtonType.primary,
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).feed,
          style: textTheme.bodyBold,
        ),
      ),
      body: _isLoading
          ? const Center(child: EnteLoadingWidget(size: 24))
          : _feedItems.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: EdgeInsets.only(
                      left: 15,
                      right: 15,
                      bottom: MediaQuery.paddingOf(context).bottom,
                    ),
                    itemCount: _feedItems.length,
                    itemBuilder: (context, index) {
                      final item = _feedItems[index];
                      final isLastItem = index == _feedItems.length - 1;
                      return FeedItemWidget(
                        key: ValueKey(
                          '${item.type}_${item.fileID}_${item.commentID}_${item.createdAt}',
                        ),
                        feedItem: item,
                        currentUserID: _currentUserID,
                        anonDisplayNames:
                            _anonDisplayNamesByCollection[item.collectionID] ??
                                const {},
                        isLastItem: isLastItem,
                        onTap: () => item.type == FeedItemType.photoLike
                            ? _openPhoto(item)
                            : _openComments(item),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              size: 48,
              color: colorScheme.strokeMuted,
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.of(context).noActivityYet,
              style: textTheme.body.copyWith(
                color: colorScheme.textMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the photo viewer for the feed item, then shows the comments sheet.
  Future<void> _openComments(FeedItem item) async {
    var fileID = item.fileID;

    if (fileID == null && item.commentID != null) {
      final comment =
          await SocialDataProvider.instance.getCommentById(item.commentID!);
      fileID = comment?.fileID;
    }

    if (fileID == null) return;

    final file = await FilesDB.instance.getUploadedFile(
      fileID,
      item.collectionID,
    );
    if (file == null || !mounted) return;

    final capturedFileID = fileID;

    // Navigate to the photo first, then show comments sheet after first frame
    unawaited(
      routeToPage(
        context,
        DetailPage(
          DetailPageConfiguration(
            [file],
            0,
            "feed_comment",
            onPageReady: (detailContext) {
              showFileCommentsBottomSheet(
                detailContext,
                collectionID: item.collectionID,
                fileID: capturedFileID,
                highlightCommentID: item.commentID,
              );
            },
          ),
        ),
        forceCustomPageRoute: true,
      ),
    );
  }

  /// Opens the photo viewer for the feed item.
  Future<void> _openPhoto(FeedItem item) async {
    var fileID = item.fileID;

    if (fileID == null && item.commentID != null) {
      final comment =
          await SocialDataProvider.instance.getCommentById(item.commentID!);
      fileID = comment?.fileID;
    }

    if (fileID == null) return;

    final file = await FilesDB.instance.getUploadedFile(
      fileID,
      item.collectionID,
    );
    if (file == null || !mounted) return;

    unawaited(
      routeToPage(
        context,
        DetailPage(
          DetailPageConfiguration(
            [file],
            0,
            "feed_item",
          ),
        ),
        forceCustomPageRoute: true,
      ),
    );
  }
}
