import 'package:photos/models/feed/feed_models.dart';

class FeedDataService {
  static const List<FeedUser> _mockUsers = [
    FeedUser(
      id: "1",
      name: "Bob",
      avatarUrl: "https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150&h=150&fit=crop&crop=face",
    ),
    FeedUser(
      id: "2",
      name: "Alice",
      avatarUrl: "https://images.unsplash.com/photo-1494790108755-2616b09c7bec?w=150&h=150&fit=crop&crop=face",
    ),
    FeedUser(
      id: "3",
      name: "Charlie",
      avatarUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
    ),
    FeedUser(
      id: "4",
      name: "Diana",
      avatarUrl: "https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150&h=150&fit=crop&crop=face",
    ),
  ];

  static List<FeedItem> getMockFeedItems() {
    return [
      FeedItem(
        id: "1",
        user: _mockUsers[0],
        type: FeedItemType.memory,
        title: "Trip to paris",
        subtitle: "shared a memory",
        timeAgo: "2h ago",
        photos: [
          const FeedPhoto(
            id: "1",
            url: "https://images.unsplash.com/photo-1499856871958-5b9627545d1a?w=400&h=600&fit=crop&crop=center",
            description: "Beautiful archway in Paris with a silhouette of a person",
          ),
          const FeedPhoto(
            id: "1a",
            url: "https://images.unsplash.com/photo-1502602898536-47ad22581b52?w=400&h=600&fit=crop",
            description: "Eiffel Tower at sunset",
          ),
          const FeedPhoto(
            id: "1b",
            url: "https://images.unsplash.com/photo-1471623643120-e6ccc3452a4e?w=400&h=600&fit=crop",
            description: "Paris street with classic architecture",
          ),
          const FeedPhoto(
            id: "1c", 
            url: "https://images.unsplash.com/photo-1549144511-f099e773c147?w=400&h=600&fit=crop",
            description: "Seine river with Notre Dame",
          ),
        ],
      ),
      FeedItem(
        id: "2",
        user: _mockUsers[0],
        type: FeedItemType.photos,
        title: "Maldives",
        subtitle: "shared 3 photos",
        timeAgo: "4h ago",
        likeCount: 12,
        photos: [
          const FeedPhoto(
            id: "2",
            url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=600&fit=crop",
            description: "Woman sitting on wooden walkway overlooking tropical landscape",
          ),
          const FeedPhoto(
            id: "3",
            url: "https://images.unsplash.com/photo-1544551763-46a013bb70d5?w=400&h=600&fit=crop",
            description: "Tropical beach with crystal clear water",
          ),
          const FeedPhoto(
            id: "4",
            url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=600&fit=crop",
            description: "Overwater bungalows in Maldives",
          ),
        ],
      ),
      FeedItem(
        id: "3",
        user: _mockUsers[0],
        type: FeedItemType.photos,
        title: "Maldives",
        subtitle: "shared 3 photos",
        timeAgo: "6h ago",
        isLiked: true,
        likeCount: 8,
        photos: [
          const FeedPhoto(
            id: "5",
            url: "https://images.unsplash.com/photo-1544198365-f5d60b6d8190?w=400&h=300&fit=crop",
            description: "Woman with drink on beach",
          ),
          const FeedPhoto(
            id: "6",
            url: "https://images.unsplash.com/photo-1544551763-77ef2d0cfc6c?w=400&h=300&fit=crop",
            description: "Couple enjoying tropical vacation",
          ),
          const FeedPhoto(
            id: "7",
            url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=300&fit=crop",
            description: "Beautiful lagoon view",
          ),
        ],
      ),
      FeedItem(
        id: "4",
        user: _mockUsers[0],
        type: FeedItemType.video,
        title: "Maldives",
        subtitle: "shared a video",
        timeAgo: "1d ago",
        likeCount: 25,
        isVideo: true,
        photos: [
          const FeedPhoto(
            id: "8",
            url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=600&fit=crop",
            description: "Video thumbnail of tropical scenery",
          ),
        ],
      ),
      FeedItem(
        id: "5",
        user: _mockUsers[0],
        type: FeedItemType.album,
        title: "Pets",
        subtitle: "liked an Album",
        timeAgo: "2d ago",
        likeCount: 15,
        photos: [
          const FeedPhoto(
            id: "9",
            url: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=400&h=600&fit=crop",
            description: "Happy dog in a grassy field",
          ),
        ],
      ),
      FeedItem(
        id: "6",
        user: _mockUsers[1],
        type: FeedItemType.memory,
        title: "Mountain Adventure",
        subtitle: "shared a memory",
        timeAgo: "3d ago",
        likeCount: 32,
        photos: [
          const FeedPhoto(
            id: "10",
            url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=600&fit=crop",
            description: "Breathtaking mountain landscape view",
          ),
        ],
      ),
      FeedItem(
        id: "7",
        user: _mockUsers[2],
        type: FeedItemType.photos,
        title: "City Lights",
        subtitle: "shared 5 photos",
        timeAgo: "1w ago",
        isLiked: true,
        likeCount: 45,
        photos: [
          const FeedPhoto(
            id: "11",
            url: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=400&h=600&fit=crop",
            description: "Urban cityscape at night",
          ),
          const FeedPhoto(
            id: "12",
            url: "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400&h=600&fit=crop",
            description: "City lights reflecting on water",
          ),
          const FeedPhoto(
            id: "13",
            url: "https://images.unsplash.com/photo-1514565131-fce0801e5785?w=400&h=600&fit=crop",
            description: "Busy street with neon lights",
          ),
          const FeedPhoto(
            id: "14",
            url: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=400&h=600&fit=crop",
            description: "Skyscraper view from below",
          ),
          const FeedPhoto(
            id: "15",
            url: "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=400&h=600&fit=crop",
            description: "City panorama at sunset",
          ),
        ],
      ),
    ];
  }

  static List<NotificationItem> getMockNotifications() {
    return [
      NotificationItem(
        id: "1",
        user: _mockUsers[0],
        action: "Liked your photo",
        timeAgo: "40m ago",
        photo: const FeedPhoto(
          id: "n1",
          url: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "2",
        user: _mockUsers[1],
        action: "Liked your photo",
        timeAgo: "2hrs ago",
        photo: const FeedPhoto(
          id: "n2",
          url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "3",
        user: _mockUsers[2],
        action: "Liked your photo",
        timeAgo: "1 day ago",
        photo: const FeedPhoto(
          id: "n3",
          url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "4",
        user: _mockUsers[0],
        action: "Liked your album",
        timeAgo: "14 days ago",
        photo: const FeedPhoto(
          id: "n4",
          url: "https://images.unsplash.com/photo-1519501025264-65ba15a82390?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "5",
        user: _mockUsers[3],
        action: "Liked your photo",
        timeAgo: "2 mnths ago",
        photo: const FeedPhoto(
          id: "n5",
          url: "https://images.unsplash.com/photo-1477959858617-67f85cf4f1df?w=100&h=100&fit=crop",
        ),
      ),
      // Read notifications
      NotificationItem(
        id: "6",
        user: _mockUsers[0],
        action: "Liked your photo",
        timeAgo: "40m ago",
        isRead: true,
        photo: const FeedPhoto(
          id: "n6",
          url: "https://images.unsplash.com/photo-1552053831-71594a27632d?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "7",
        user: _mockUsers[1],
        action: "Liked your photo",
        timeAgo: "2hrs ago",
        isRead: true,
        photo: const FeedPhoto(
          id: "n7",
          url: "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=100&h=100&fit=crop",
        ),
      ),
      NotificationItem(
        id: "8",
        user: _mockUsers[2],
        action: "Liked your photo",
        timeAgo: "1 day ago",
        isRead: true,
        photo: const FeedPhoto(
          id: "n8",
          url: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=100&h=100&fit=crop",
        ),
      ),
    ];
  }
}