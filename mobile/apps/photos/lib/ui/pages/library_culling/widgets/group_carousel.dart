import 'package:flutter/material.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class GroupCarousel extends StatelessWidget {
  final List<SimilarFiles> groups;
  final int currentGroupIndex;
  final Function(int) onGroupSelected;
  final Function(int) onGroupLongPress;
  final Map<int, GroupProgress> progressMap;

  const GroupCarousel({
    super.key,
    required this.groups,
    required this.currentGroupIndex,
    required this.onGroupSelected,
    required this.onGroupLongPress,
    required this.progressMap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final progress = progressMap[index] ?? 
              GroupProgress(
                totalImages: group.files.length, 
                reviewedImages: 0, 
                deletionCount: 0,
              );
          final isCurrentGroup = index == currentGroupIndex;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => isCurrentGroup 
                  ? onGroupLongPress(index)  // Show summary if tapping current group
                  : onGroupSelected(index),
              onLongPress: () => onGroupLongPress(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isCurrentGroup ? 72 : 64,
                height: isCurrentGroup ? 72 : 64,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isCurrentGroup ? 1.0 : 0.6,
                  child: Stack(
                    children: [
                      // Build stacked thumbnails for current group, single for others
                      if (isCurrentGroup)
                        _buildStackedThumbnails(group, theme)
                      else
                        _buildSingleThumbnail(group),
                      
                      // Progress/status badges
                      if (progress.isComplete && progress.deletionCount > 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.warning700,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${progress.deletionCount}',
                              style: TextStyle(
                                color: theme.backgroundBase,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      
                      if (progress.isComplete && progress.deletionCount == 0)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.primary500,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              size: 12,
                              color: theme.backgroundBase,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStackedThumbnails(SimilarFiles group, theme) {
    if (group.files.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Stack(
      children: [
        // Back card (rotated slightly)
        if (group.files.length > 1)
          Positioned(
            top: 4,
            left: 4,
            right: 4,
            bottom: 4,
            child: Transform.rotate(
              angle: -0.05, // Slight rotation
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ThumbnailWidget(
                    group.files[1],
                    fit: BoxFit.cover,
                    shouldShowLivePhotoOverlay: false,
                    shouldShowOwnerAvatar: false,
                  ),
                ),
              ),
            ),
          ),
        // Front card
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Transform.rotate(
            angle: 0.05, // Slight rotation opposite direction
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ThumbnailWidget(
                  group.files[0],
                  fit: BoxFit.cover,
                  shouldShowLivePhotoOverlay: false,
                  shouldShowOwnerAvatar: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSingleThumbnail(SimilarFiles group) {
    if (group.files.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ThumbnailWidget(
          group.files[0],
          fit: BoxFit.cover,
          shouldShowLivePhotoOverlay: false,
          shouldShowOwnerAvatar: false,
        ),
      ),
    );
  }
}