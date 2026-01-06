import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/db/files_db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/social/feed_data_provider.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/models/social/social_data_provider.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/social/comments_screen.dart";
import "package:photos/ui/social/widgets/feed_item_widget.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/utils/navigation_util.dart";

/// Screen that displays the user's activity feed.
///
/// Shows likes, comments, and replies on the user's photos and comments.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  List<FeedItem> _feedItems = [];
  bool _isLoading = true;
  late final int _currentUserID;

  /// Map of collectionID -> (anonUserID -> displayName)
  Map<int, Map<String, String>> _anonDisplayNamesByCollection = {};

  @override
  void initState() {
    super.initState();
    _currentUserID = Configuration.instance.getUserID() ?? 0;
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
    } catch (_) {
      // Ignore sync errors, local data is already displayed
    }
  }

  Future<void> _onRefresh() async {
    await _syncAndRefresh();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: colorScheme.backgroundBase,
        elevation: 0,
        leading: IconButtonWidget(
          iconButtonType: IconButtonType.secondary,
          icon: Icons.arrow_back,
          onTap: () => Navigator.of(context).pop(),
        ),
        title: Text(
          AppLocalizations.of(context).feed,
          style: textTheme.bodyBold,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _feedItems.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
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
                        onTap: () => _openComments(item),
                        onThumbnailTap: () => _openPhoto(item),
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

  /// Opens the comments screen for the feed item.
  Future<void> _openComments(FeedItem item) async {
    var fileID = item.fileID;

    if (fileID == null && item.commentID != null) {
      final comment =
          await SocialDataProvider.instance.getCommentById(item.commentID!);
      fileID = comment?.fileID;
    }

    if (fileID == null || !mounted) return;

    unawaited(
      routeToPage(
        context,
        FileCommentsScreen(
          collectionID: item.collectionID,
          fileID: fileID,
          highlightCommentID: item.commentID,
        ),
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
