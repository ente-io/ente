import 'package:flutter/material.dart';
import 'package:photos/core/constants.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class SwipeablePhotoCard extends StatelessWidget {
  final EnteFile file;
  final bool showBestPictureBadge;
  final double swipeProgress;
  final bool isSwipingLeft;
  final bool isSwipingRight;

  const SwipeablePhotoCard({
    super.key,
    required this.file,
    this.showBestPictureBadge = false,
    this.swipeProgress = 0.0,
    this.isSwipingLeft = false,
    this.isSwipingRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate border intensity based on swipe progress
    final borderIntensity = (swipeProgress.abs() * 3).clamp(0.0, 1.0);
    final borderWidth = (borderIntensity * 8).clamp(0.0, 8.0);
    
    // Determine border color based on swipe direction
    Color? borderColor;
    
    if (isSwipingLeft) {
      borderColor = theme.warning700.withValues(alpha: borderIntensity);
    } else if (isSwipingRight) {
      borderColor = theme.primary700.withValues(alpha: borderIntensity);
    }

    // Calculate card dimensions to preserve aspect ratio
    final maxWidth = screenSize.width * 0.85;
    final maxHeight = screenSize.height * 0.65;
    
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Main photo - use contain to show full image
              ThumbnailWidget(
                file,
                fit: BoxFit.contain,
                thumbnailSize: thumbnailLargeSize,
                shouldShowLivePhotoOverlay: false,
                shouldShowOwnerAvatar: false,
              ),
            
            // Border overlay for swipe feedback
            if (borderColor != null && borderWidth > 0)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: borderColor,
                      width: borderWidth,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            
            // Best picture badge
            if (showBestPictureBadge)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.primary500,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.star,
                        size: 16,
                        color: theme.backgroundBase,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Best',
                        style: TextStyle(
                          color: theme.backgroundBase,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}