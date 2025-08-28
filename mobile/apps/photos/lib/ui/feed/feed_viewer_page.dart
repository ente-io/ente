import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photos/models/feed/feed_models.dart';
import 'package:photos/ui/feed/notifications_page.dart';
import 'package:photos/ui/feed/widgets/feed_user_avatar.dart';
import 'package:photos/utils/navigation_util.dart';

class FeedViewerPage extends StatefulWidget {
  final FeedItem feedItem;
  final VoidCallback? onLike;

  const FeedViewerPage({
    required this.feedItem,
    this.onLike,
    super.key,
  });

  @override
  State<FeedViewerPage> createState() => _FeedViewerPageState();
}

class _FeedViewerPageState extends State<FeedViewerPage> {
  late PageController _pageController;
  int _currentPhotoIndex = 0;
  late bool _isLiked;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _isLiked = widget.feedItem.isLiked;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onLike() {
    setState(() {
      _isLiked = !_isLiked;
    });
    widget.onLike?.call();
  }

  void _onNotificationsTap() {
    routeToPage(context, const NotificationsPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main content
          _buildMainContent(),
          // Top bar
          _buildTopBar(),
          // Bottom overlay
          _buildBottomOverlay(),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    if (widget.feedItem.photos.length == 1) {
      return _buildSinglePhoto();
    } else {
      return _buildMultiplePhotos();
    }
  }

  Widget _buildSinglePhoto() {
    final photo = widget.feedItem.photos.first;
    return Center(
      child: CachedNetworkImage(
        imageUrl: photo.url,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
          ),
        ),
        errorWidget: (context, url, error) => const Center(
          child: Icon(
            Icons.error,
            color: Colors.white,
            size: 50,
          ),
        ),
      ),
    );
  }

  Widget _buildMultiplePhotos() {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() {
          _currentPhotoIndex = index;
        });
      },
      itemCount: widget.feedItem.photos.length,
      itemBuilder: (context, index) {
        final photo = widget.feedItem.photos[index];
        return Center(
          child: CachedNetworkImage(
            imageUrl: photo.url,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.error,
                color: Colors.white,
                size: 50,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _onNotificationsTap,
              child: Container(
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black54,
              Colors.black87,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo indicators for multiple photos
                if (widget.feedItem.photos.length > 1) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.feedItem.photos.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentPhotoIndex
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // User info and description
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              FeedUserAvatar(
                                avatarUrl: widget.feedItem.user.avatarUrl,
                                name: widget.feedItem.user.name,
                                size: 40,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                widget.feedItem.user.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (widget.feedItem.photos.first.description != null)
                            Text(
                              widget.feedItem.photos.first.description!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Action buttons
                    Column(
                      children: [
                        GestureDetector(
                          onTap: _onLike,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            child: Icon(
                              _isLiked ? Icons.favorite : Icons.favorite_border,
                              color: _isLiked ? Colors.red : Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          child: const Icon(
                            Icons.share_outlined,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Progress bar (placeholder)
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}