import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/ui/components/feed/feed_item_card.dart';

class VideoPost extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onFavoriteToggle;

  const VideoPost({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
  });

  @override
  State<VideoPost> createState() => _VideoPostState();
}

class _VideoPostState extends State<VideoPost> {
  bool isPlaying = false;

  @override
  Widget build(BuildContext context) {
    return FeedItemCard(
      item: widget.item,
      onFavoriteToggle: widget.onFavoriteToggle,
      child: Container(
        height: 322,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.grey[100],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildVideoContent(),
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    final urls = widget.item.mediaUrls;
    if (urls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.videocam, color: Colors.grey, size: 48),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          isPlaying = !isPlaying;
        });
      },
      child: Stack(
        children: [
          // Video thumbnail
          Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.network(
              urls[0],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, color: Colors.grey),
                  ),
                );
              },
            ),
          ),
          // Play overlay
          if (!isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
          // Playing overlay
          if (isPlaying)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pause,
                        color: Colors.white,
                        size: 48,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Playing video...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}