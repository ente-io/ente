import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class FeedUserAvatar extends StatelessWidget {
  final String avatarUrl;
  final double size;
  final String name;

  const FeedUserAvatar({
    required this.avatarUrl,
    this.size = 40.0,
    required this.name,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[300],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: avatarUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[300],
            child: Icon(
              Icons.person,
              color: Colors.grey[600],
              size: size * 0.6,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[300],
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[700],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}