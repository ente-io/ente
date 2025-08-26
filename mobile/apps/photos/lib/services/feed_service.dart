import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';

class FeedService {
  static final FeedService _instance = FeedService._internal();
  static FeedService get instance => _instance;
  FeedService._internal();

  List<FeedItem> _feedItems = [];
  bool _isLoading = false;

  List<FeedItem> get feedItems => List.unmodifiable(_feedItems);
  bool get isLoading => _isLoading;

  void init() {
    _loadMockData();
  }

  void _loadMockData() {
    final now = DateTime.now();
    debugPrint('FeedService: Loading mock data...');
    _feedItems = [
      FeedItem(
        id: "1",
        type: FeedItemType.memory,
        title: "Trip to paris",
        subtitle: "shared a memory",
        userName: "Bob",
        userAvatarUrl: "",
        isFavorite: false,
        mediaUrls: [
          "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=600&fit=crop",
          "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=600&fit=crop",
          "https://images.unsplash.com/photo-1527004013197-933c4bb611b3?w=400&h=600&fit=crop",
        ],
        timestamp: now.subtract(const Duration(hours: 2)),
        metadata: {"memoryType": "trip"},
      ),
      FeedItem(
        id: "2",
        type: FeedItemType.photos,
        title: "Maldives",
        subtitle: "shared 3 photos",
        userName: "Bob",
        userAvatarUrl: "",
        isFavorite: false,
        mediaUrls: [
          "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop",
          "https://images.unsplash.com/photo-1469474968028-56623f02e42e?w=400&h=300&fit=crop",
          "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400&h=300&fit=crop",
        ],
        timestamp: now.subtract(const Duration(hours: 5)),
      ),
      FeedItem(
        id: "3",
        type: FeedItemType.video,
        title: "",
        subtitle: "shared a video",
        userName: "Bob",
        userAvatarUrl: "",
        isFavorite: false,
        mediaUrls: ["https://images.unsplash.com/photo-1486312338219-ce68e2c6b181?w=400&h=600&fit=crop"],
        timestamp: now.subtract(const Duration(hours: 8)),
        metadata: {"videoDuration": 45},
      ),
      FeedItem(
        id: "4",
        type: FeedItemType.album,
        title: "Pets",
        subtitle: "shared an Album",
        userName: "Bob",
        userAvatarUrl: "",
        isFavorite: false,
        mediaUrls: [
          "https://images.unsplash.com/photo-1415369629372-26f2fe60c467?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1425082661705-1834bfd09dca?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1518717758536-85ae29035b6d?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1511044568932-338cba0ad803?w=400&h=400&fit=crop",
        ],
        timestamp: now.subtract(const Duration(days: 1)),
        metadata: {"albumVariant": "pets1"},
      ),
      FeedItem(
        id: "5",
        type: FeedItemType.album,
        title: "Pets",
        subtitle: "shared an Album",
        userName: "Bob",
        userAvatarUrl: "",
        isFavorite: false,
        mediaUrls: [
          "https://images.unsplash.com/photo-1444212477490-ca407925329e?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1543852786-1cf6624b9987?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1517423440428-a5a00ad493e8?w=400&h=400&fit=crop",
          "https://images.unsplash.com/photo-1583337130417-3346a1be7dee?w=400&h=400&fit=crop",
        ],
        timestamp: now.subtract(const Duration(days: 2)),
        metadata: {"albumVariant": "pets2"},
      ),
    ];
    debugPrint('FeedService: Loaded ${_feedItems.length} mock items');
  }

  Future<void> toggleFavorite(String itemId) async {
    final itemIndex = _feedItems.indexWhere((item) => item.id == itemId);
    if (itemIndex != -1) {
      _feedItems[itemIndex] = _feedItems[itemIndex].copyWith(
        isFavorite: !_feedItems[itemIndex].isFavorite,
      );
    }
  }

  Future<void> refreshFeed() async {
    _isLoading = true;
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // In a real implementation, this would fetch from API
    _loadMockData();
    
    _isLoading = false;
  }

  List<FeedItem> getFeedItems() {
    return _feedItems;
  }
}