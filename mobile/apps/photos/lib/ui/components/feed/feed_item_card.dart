import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/ui/components/feed/post_header.dart';

class FeedItemCard extends StatelessWidget {
  final FeedItem item;
  final Widget child;
  final VoidCallback onFavoriteToggle;
  final double? height;

  const FeedItemCard({
    super.key,
    required this.item,
    required this.child,
    required this.onFavoriteToggle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PostHeader(
            userName: item.userName,
            subtitle: item.subtitle,
            title: item.title,
            avatarUrl: item.userAvatarUrl,
            isFavorite: item.isFavorite,
            onFavoriteToggle: onFavoriteToggle,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}