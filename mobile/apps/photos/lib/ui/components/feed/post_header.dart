import 'package:flutter/material.dart';
import 'package:photos/ui/components/feed/favorite_button.dart';
import 'package:photos/ui/components/feed/user_avatar.dart';

class PostHeader extends StatelessWidget {
  final String userName;
  final String subtitle;
  final String title;
  final String avatarUrl;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;

  const PostHeader({
    super.key,
    required this.userName,
    required this.subtitle,
    required this.title,
    required this.avatarUrl,
    required this.isFavorite,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          UserAvatar(
            avatarUrl: avatarUrl,
            size: 48,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                    if (title.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          FavoriteButton(
            isFavorite: isFavorite,
            onToggle: onFavoriteToggle,
          ),
        ],
      ),
    );
  }
}
