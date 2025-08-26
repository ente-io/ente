import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/services/feed_service.dart';
import 'package:photos/ui/components/feed/feed_header.dart';

class FeedTab extends StatefulWidget {
  const FeedTab({super.key});

  @override
  State<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends State<FeedTab> {
  final FeedService _feedService = FeedService.instance;
  List<FeedItem> _feedItems = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _feedService.init();
    _loadFeedItems();
  }

  void _loadFeedItems() {
    setState(() {
      _feedItems = _feedService.getFeedItems();
      debugPrint('_loadFeedItems: loaded ${_feedItems.length} items');
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isLoading = true;
    });

    await _feedService.refreshFeed();
    _loadFeedItems();

    setState(() {
      _isLoading = false;
    });
  }

  void _onFavoriteToggle(String itemId) async {
    await _feedService.toggleFavorite(itemId);
    _loadFeedItems();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('FeedTab build: _feedItems length = ${_feedItems.length}');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            const FeedHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _onRefresh,
                child: _feedItems.isEmpty
                    ? _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: _feedItems.length,
                        itemBuilder: (context, index) {
                          debugPrint(
                            'Building item $index: ${_feedItems[index].type}',
                          );
                          return _buildFeedItem(_feedItems[index]);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedItem(FeedItem item) {
    // Simplified version for debugging
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blue,
                child: Text(item.userName[0]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.userName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('${item.subtitle} ${item.title}'),
                  ],
                ),
              ),
              Icon(
                item.isFavorite ? Icons.favorite : Icons.favorite_border,
                color: item.isFavorite ? Colors.red : Colors.grey,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getIconForType(item.type),
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.type.name.toUpperCase(),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(FeedItemType type) {
    switch (type) {
      case FeedItemType.memory:
        return Icons.photo_library;
      case FeedItemType.photos:
        return Icons.photo;
      case FeedItemType.video:
        return Icons.play_circle;
      case FeedItemType.album:
        return Icons.photo_album;
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No posts in your feed yet',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Check back later for updates',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
