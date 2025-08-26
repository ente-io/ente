enum FeedItemType { memory, photos, video, album }

class FeedItem {
  final String id;
  final FeedItemType type;
  final String title;
  final String subtitle;
  final String userName;
  final String userAvatarUrl;
  final bool isFavorite;
  final List<String> mediaUrls;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const FeedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.userName,
    required this.userAvatarUrl,
    required this.isFavorite,
    required this.mediaUrls,
    required this.timestamp,
    this.metadata,
  });

  FeedItem copyWith({
    String? id,
    FeedItemType? type,
    String? title,
    String? subtitle,
    String? userName,
    String? userAvatarUrl,
    bool? isFavorite,
    List<String>? mediaUrls,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return FeedItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      userName: userName ?? this.userName,
      userAvatarUrl: userAvatarUrl ?? this.userAvatarUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }
}