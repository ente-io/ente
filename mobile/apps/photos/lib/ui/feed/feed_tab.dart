import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_models.dart';
import 'package:photos/services/feed/feed_data_service.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/feed/feed_viewer_page.dart';
import 'package:photos/ui/feed/notifications_page.dart';
import 'package:photos/ui/feed/widgets/feed_item_widget.dart';
import 'package:photos/utils/navigation_util.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  List<FeedItem> _feedItems = [];

  @override
  void initState() {
    super.initState();
    _loadFeedItems();
  }

  void _loadFeedItems() {
    setState(() {
      _feedItems = FeedDataService.getMockFeedItems();
    });
  }

  void _onLike(int index) {
    setState(() {
      final item = _feedItems[index];
      _feedItems[index] = item.copyWith(
        isLiked: !item.isLiked,
        likeCount: item.isLiked ? item.likeCount - 1 : item.likeCount + 1,
      );
    });
  }

  void _onFeedItemTap(FeedItem item) {
    routeToPage(
      context,
      FeedViewerPage(
        feedItem: item,
        onLike: () {
          final index = _feedItems.indexWhere((f) => f.id == item.id);
          if (index != -1) {
            _onLike(index);
          }
        },
      ),
    );
  }

  void _onNotificationsTap() {
    routeToPage(context, const NotificationsPage());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    
    return Scaffold(
      backgroundColor: colorScheme.backgroundBase,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Feed',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  GestureDetector(
                    onTap: _onNotificationsTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.notifications_outlined,
                        size: 28,
                        color: colorScheme.textBase,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Feed content
            Expanded(
              child: _feedItems.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                      itemCount: _feedItems.length,
                      itemBuilder: (context, index) {
                        final item = _feedItems[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: FeedItemWidget(
                            item: item,
                            onTap: () => _onFeedItemTap(item),
                            onLike: () => _onLike(index),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}