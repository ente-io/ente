import 'package:flutter/material.dart';
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
    Key? key,
    required this.file,
    this.showBestPictureBadge = false,
    this.swipeProgress = 0.0,
    this.isSwipingLeft = false,
    this.isSwipingRight = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate overlay opacity based on swipe progress
    final overlayOpacity = (swipeProgress.abs() * 2).clamp(0.0, 0.6);
    
    // Determine overlay color and icon
    Color? overlayColor;
    IconData? overlayIcon;
    
    if (isSwipingLeft) {
      overlayColor = theme.warning700.withOpacity(overlayOpacity);
      overlayIcon = Icons.delete_outline;
    } else if (isSwipingRight) {
      overlayColor = theme.primary700.withOpacity(overlayOpacity);
      overlayIcon = Icons.thumb_up_outlined;
    }

    return Container(
      width: screenSize.width * 0.85,
      height: screenSize.height * 0.6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Main photo
            ThumbnailWidget(
              file,
              fit: BoxFit.cover,
              shouldShowLivePhotoOverlay: false,
              shouldShowOwnerAvatar: false,
            ),
            
            // Overlay for swipe feedback
            if (overlayColor != null)
              Container(
                decoration: BoxDecoration(
                  color: overlayColor,
                  border: Border.all(
                    color: isSwipingLeft 
                        ? theme.warning700 
                        : theme.primary700,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Icon(
                    overlayIcon,
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
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
    );
  }
}