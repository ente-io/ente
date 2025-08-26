import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_item.dart';
import 'package:photos/ui/components/feed/feed_item_card.dart';

class AlbumPost extends StatefulWidget {
  final FeedItem item;
  final VoidCallback onFavoriteToggle;

  const AlbumPost({
    super.key,
    required this.item,
    required this.onFavoriteToggle,
  });

  @override
  State<AlbumPost> createState() => _AlbumPostState();
}

class _AlbumPostState extends State<AlbumPost> {
  int? selectedSection;

  @override
  Widget build(BuildContext context) {
    final variant = widget.item.metadata?["albumVariant"] ?? "pets2";

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
          child: variant == "pets1" ? _buildPets1Layout() : _buildPets2Layout(),
        ),
      ),
    );
  }

  Widget _buildPets1Layout() {
    final urls = widget.item.mediaUrls;
    if (urls.length < 3) return _buildEmptyState();

    return Stack(
      children: [
        // Back layer
        Positioned(
          left: 24,
          top: 0,
          child: _buildSelectableImage(
            urls[0],
            0,
            width: 270,
            height: 278,
            hasOverlay: true,
          ),
        ),
        // Middle layer
        Positioned(
          left: 11,
          top: 10,
          child: _buildSelectableImage(
            urls[1],
            1,
            width: 296,
            height: 306,
          ),
        ),
        // Front layer with title
        Positioned(
          left: 0,
          bottom: 0,
          right: 0,
          child: Container(
            height: 304,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: NetworkImage(urls[2]),
                fit: BoxFit.cover,
              ),
            ),
            child: GestureDetector(
              onTap: () => _selectSection(2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: selectedSection == 2
                      ? Border.all(color: Colors.blue, width: 2)
                      : null,
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
          ),
        ),
      ],
    );
  }

  Widget _buildPets2Layout() {
    final urls = widget.item.mediaUrls;
    if (urls.length < 4) return _buildEmptyState();

    return Stack(
      children: [
        // Top left
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
        // Bottom left
        Positioned(
          left: 0,
          top: 165,
          child: _buildSelectableImage(
            urls[1],
            1,
            width: 159,
            height: 157,
          ),
        ),
        // Top right
        Positioned(
          right: 0,
          top: 0,
          child: _buildSelectableImage(
            urls[2],
            2,
            width: 156,
            height: 161,
          ),
        ),
        // Bottom right with +5 overlay
        Positioned(
          right: 0,
          top: 165,
          child: _buildSelectableImageWithOverlay(
            urls[3],
            3,
            width: 156,
            height: 157,
            extraCount: urls.length > 4 ? urls.length - 4 : 0,
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
    bool hasOverlay = false,
  }) {
    final isSelected = selectedSection == index;

    return GestureDetector(
      onTap: () => _selectSection(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
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
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.grey),
                    ),
                  );
                },
              ),
              if (hasOverlay)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.2),
                        Colors.black.withOpacity(0.2),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectableImageWithOverlay(
    String imageUrl,
    int index, {
    required double width,
    required double height,
    required int extraCount,
  }) {
    final isSelected = selectedSection == index;

    return GestureDetector(
      onTap: () => _selectSection(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: Matrix4.identity()..scale(isSelected ? 1.05 : 1.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: isSelected ? Border.all(color: Colors.blue, width: 2) : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              Image.network(
                imageUrl,
                width: width,
                height: height,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[300],
                    child: const Center(
                      child: Icon(Icons.error, color: Colors.grey),
                    ),
                  );
                },
              ),
              if (extraCount > 0)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    child: Center(
                      child: Text(
                        '+$extraCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.photo_album, color: Colors.grey, size: 48),
      ),
    );
  }

  void _selectSection(int index) {
    setState(() {
      selectedSection = selectedSection == index ? null : index;
    });
  }
}
