import 'package:flutter/material.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';

class GroupCarousel extends StatefulWidget {
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
  State<GroupCarousel> createState() => _GroupCarouselState();
}

class _GroupCarouselState extends State<GroupCarousel> {
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  void didUpdateWidget(GroupCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentGroupIndex != oldWidget.currentGroupIndex) {
      _scrollToCurrentGroup();
    }
  }
  
  void _scrollToCurrentGroup() {
    if (!_scrollController.hasClients) return;
    
    // Calculate the position to scroll to (72 width + 16 padding per item)
    const itemWidth = 72.0 + 16.0;
    final targetPosition = widget.currentGroupIndex * itemWidth;
    
    // Center the current group in the viewport if possible
    final viewportWidth = _scrollController.position.viewportDimension;
    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final centeredPosition = targetPosition - (viewportWidth / 2) + (itemWidth / 2);
    final scrollPosition = centeredPosition.clamp(0.0, maxScrollExtent);
    
    _scrollController.animateTo(
      scrollPosition,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);

    // Scroll to current group after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.currentGroupIndex > 0) {
        _scrollToCurrentGroup();
      }
    });

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        clipBehavior: Clip.none,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        itemCount: widget.groups.length,
        itemBuilder: (context, index) {
          final group = widget.groups[index];
          final progress = widget.progressMap[index] ??
              GroupProgress(
                totalImages: group.files.length,
                reviewedImages: 0,
                deletionCount: 0,
              );
          final isCurrentGroup = index == widget.currentGroupIndex;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () => isCurrentGroup
                  ? widget.onGroupLongPress(
                      index,
                    ) // Show summary if tapping current group
                  : widget.onGroupSelected(index),
              onLongPress: () => widget.onGroupLongPress(index),
              child: SizedBox(
                width: 72, // 72x90 rectangular
                height: 90,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isCurrentGroup ? 1.0 : 0.6,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Build stacked thumbnails for current group, single for others
                      if (isCurrentGroup)
                        _buildStackedThumbnails(group, theme)
                      else
                        _buildSingleThumbnail(group),

                      // Progress/status badges
                      if (progress.isComplete && progress.deletionCount > 0)
                        Positioned(
                          top: -8,
                          right: -8,
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                      if (progress.isComplete && progress.deletionCount == 0)
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: theme.primary500,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
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
              angle: -0.15, // More rotation for better separation
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.strokeMuted,
                    width: 1.0,
                  ),
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
                    group.files[0],
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
            angle: 0.10, // More rotation opposite direction
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.strokeMuted,
                  width: 1.0,
                ),
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
