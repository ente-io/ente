class FeedUser {
  final String id;
  final String name;
  final String avatarUrl;

  const FeedUser({
    required this.id,
    required this.name,
    required this.avatarUrl,
  });
}

class FeedPhoto {
  final String id;
  final String url;
  final String? description;

  const FeedPhoto({
    required this.id,
    required this.url,
    this.description,
  });
}

enum FeedItemType {
  memory,
  album,
  photos,
  video,
}

class FeedItem {
  final String id;
  final FeedUser user;
  final FeedItemType type;
  final String title;
  final String subtitle;
  final List<FeedPhoto> photos;
  final bool isLiked;
  final int likeCount;
  final String timeAgo;
  final bool isVideo;

  const FeedItem({
    required this.id,
    required this.user,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.photos,
    this.isLiked = false,
    this.likeCount = 0,
    required this.timeAgo,
    this.isVideo = false,
  });

  FeedItem copyWith({
    bool? isLiked,
    int? likeCount,
  }) {
    return FeedItem(
      id: id,
      user: user,
      type: type,
      title: title,
      subtitle: subtitle,
      photos: photos,
      isLiked: isLiked ?? this.isLiked,
      likeCount: likeCount ?? this.likeCount,
      timeAgo: timeAgo,
      isVideo: isVideo,
    );
  }
}

class NotificationItem {
  final String id;
  final FeedUser user;
  final String action;
  final String timeAgo;
  final FeedPhoto? photo;
  final bool isRead;

  const NotificationItem({
    required this.id,
    required this.user,
    required this.action,
    required this.timeAgo,
    this.photo,
    this.isRead = false,
  });

  NotificationItem copyWith({bool? isRead}) {
    return NotificationItem(
      id: id,
      user: user,
      action: action,
      timeAgo: timeAgo,
      photo: photo,
      isRead: isRead ?? this.isRead,
    );
  }
}