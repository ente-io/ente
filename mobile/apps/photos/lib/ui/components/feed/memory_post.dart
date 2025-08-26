import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/ui/components/feed/feed_item_card.dart';

class MemoryPost extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onFavoriteToggle;

  const MemoryPost({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
  });

  @override
  State<MemoryPost> createState() => _MemoryPostState();
}

class _MemoryPostState extends State<MemoryPost>
    with SingleTickerProviderStateMixin {
  bool isImageClicked = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ),);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onImageTapped() {
    setState(() {
      isImageClicked = !isImageClicked;
    });
    if (isImageClicked) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FeedItemCard(
      item: widget.item,
      height: 498,
      onFavoriteToggle: widget.onFavoriteToggle,
      child: GestureDetector(
        onTap: _onImageTapped,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: double.infinity,
                height: 322,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _buildMemoryLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMemoryLayout() {
    final urls = widget.item.mediaUrls;
    if (urls.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.photo, color: Colors.grey, size: 48),
        ),
      );
    }

    return Stack(
      children: [
        // Background images in a layered style
        if (urls.length > 2)
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(urls[2]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        // Main center image
        if (urls.isNotEmpty)
          Positioned(
            left: 50,
            top: 0,
            child: Container(
              width: 240,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(urls[0]),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.center,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      widget.item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Right side image
        if (urls.length > 1)
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              width: 200,
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: NetworkImage(urls[1]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}