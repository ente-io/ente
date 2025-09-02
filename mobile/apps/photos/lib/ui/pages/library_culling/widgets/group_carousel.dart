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
    Key? key,
    required this.groups,
    required this.currentGroupIndex,
    required this.onGroupSelected,
    required this.onGroupLongPress,
    required this.progressMap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    
    return Container(
      height: 80,
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
              onTap: () => onGroupSelected(index),
              onLongPress: () => onGroupLongPress(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isCurrentGroup 
                        ? theme.primary500 
                        : theme.strokeFaint,
                    width: isCurrentGroup ? 2 : 1,
                  ),
                  boxShadow: isCurrentGroup
                      ? [
                          BoxShadow(
                            color: theme.primary500.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Stack(
                  children: [
                    // 2x2 grid of thumbnails
                    ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: _buildThumbnailGrid(group),
                    ),
                    
                    // Progress/status badges
                    if (progress.isComplete)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: progress.deletionCount > 0
                                ? theme.warning700
                                : theme.primary500,
                            shape: BoxShape.circle,
                          ),
                          child: progress.deletionCount > 0
                              ? Text(
                                  '${progress.deletionCount}',
                                  style: TextStyle(
                                    color: theme.backgroundBase,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Icon(
                                  Icons.check,
                                  size: 12,
                                  color: theme.backgroundBase,
                                ),
                        ),
                      ),
                    
                    // Current group indicator
                    if (isCurrentGroup && !progress.isComplete)
                      Positioned(
                        bottom: 4,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color: theme.primary500,
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: progress.progressPercentage,
                            child: Container(
                              decoration: BoxDecoration(
                                color: theme.primary700,
                                borderRadius: BorderRadius.circular(2),
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
        },
      ),
    );
  }

  Widget _buildThumbnailGrid(SimilarFiles group) {
    final files = group.files.take(4).toList();
    
    if (files.isEmpty) {
      return const SizedBox.shrink();
    }
    
    if (files.length == 1) {
      return ThumbnailWidget(
        files[0],
        fit: BoxFit.cover,
        shouldShowLivePhotoOverlay: false,
        shouldShowOwnerAvatar: false,
      );
    }
    
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: files.length.clamp(0, 4),
      itemBuilder: (context, index) {
        return ThumbnailWidget(
          files[index],
          fit: BoxFit.cover,
          shouldShowLivePhotoOverlay: false,
          shouldShowOwnerAvatar: false,
        );
      },
    );
  }
}