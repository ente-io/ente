import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/ui/components/feed/feed_item_card.dart';

class PhotosPost extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onFavoriteToggle;

  const PhotosPost({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
  });

  @override
  State<PhotosPost> createState() => _PhotosPostState();
}

class _PhotosPostState extends State<PhotosPost> {
  int? selectedImage;

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
          child: _buildPhotosGrid(),
        ),
      ),
    );
  }

  Widget _buildPhotosGrid() {
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
        // Top left image
        if (urls.isNotEmpty)
          Positioned(
            left: 0,
            top: 0,
            child: _buildSelectableImage(
              urls[0],
              0,
              width: 159,
              height: 161,
            ),
          ),
        // Top right image
        if (urls.length > 1)
          Positioned(
            right: 0,
            top: 0,
            child: _buildSelectableImage(
              urls[1],
              1,
              width: 155,
              height: 161,
            ),
          ),
        // Bottom full-width image
        if (urls.length > 2)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildSelectableImage(
              urls[2],
              2,
              width: double.infinity,
              height: 157,
            ),
          ),
      ],
    );
  }

  Widget _buildSelectableImage(
    String imageUrl,
    int index, {
    required double width,
    required double height,
  }) {
    final isSelected = selectedImage == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedImage = selectedImage == index ? null : index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.identity()
          ..scale(isSelected ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected
              ? Border.all(color: Colors.blue, width: 2)
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            imageUrl,
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
      ),
    );
  }
}