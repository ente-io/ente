import "dart:async";

import "package:flutter/material.dart";
import "package:photos/core/configuration.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/social/feed_data_provider.dart";
import "package:photos/models/social/feed_item.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/social/widgets/feed_item_widget.dart";

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

    if (mounted) {
      setState(() {
        _feedItems = items;
        _isLoading = false;
      });
    }

    // Sync in background and refresh
    unawaited(_syncAndRefresh());
  }

  Future<void> _syncAndRefresh() async {
    try {
      await FeedDataProvider.instance.syncAllSharedCollections();

      if (!mounted) return;

      // Reload feed items after sync
      final freshItems =
          await FeedDataProvider.instance.getFeedItems(limit: 50);

      if (mounted) {
        setState(() {
          _feedItems = freshItems;
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
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: _feedItems.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: colorScheme.strokeFaint,
                    ),
                    itemBuilder: (context, index) {
                      final item = _feedItems[index];
                      return FeedItemWidget(
                        key: ValueKey(
                          '${item.type}_${item.fileID}_${item.commentID}_${item.createdAt}',
                        ),
                        feedItem: item,
                        currentUserID: _currentUserID,
                        onTap: () => _onFeedItemTap(item),
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

  void _onFeedItemTap(FeedItem item) {
    // TODO: Navigate to the photo or comment
    // For now, we'll leave this as a placeholder for future implementation
  }
}
