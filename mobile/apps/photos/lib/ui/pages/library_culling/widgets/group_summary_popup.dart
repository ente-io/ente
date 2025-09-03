import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/buttons/button_widget.dart';
import 'package:photos/ui/components/models/button_type.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/viewer/file/detail_page.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
import 'package:photos/utils/navigation_util.dart';
import 'package:photos/utils/standalone/data.dart';

class GroupSummaryPopup extends StatelessWidget {
  final SimilarFiles group;
  final Map<EnteFile, SwipeDecision> decisions;
  final VoidCallback onUndoAll;
  final VoidCallback onDeleteThese;

  const GroupSummaryPopup({
    super.key,
    required this.group,
    required this.decisions,
    required this.onUndoAll,
    required this.onDeleteThese,
  });

  @override
  Widget build(BuildContext context) {
    final theme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final files = group.files;
    
    // Calculate stats
    int deletionCount = 0;
    int decisionCount = 0;
    int totalSize = 0;
    for (final file in files) {
      final decision = decisions[file] ?? SwipeDecision.undecided;
      if (decision != SwipeDecision.undecided) {
        decisionCount++;
      }
      if (decision == SwipeDecision.delete) {
        deletionCount++;
        totalSize += file.fileSize ?? 0;
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 400,
          maxHeight: 600,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with storage info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Decisions',
                  style: textTheme.largeBold,
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            
            if (deletionCount > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context).storageToBeFreed(size: formatBytes(totalSize)),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: theme.warning700,
                  ),
                ),
              ),
            
            // Grid of images with overlay indicators (no divider)
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 16, // More vertical spacing
                  childAspectRatio: 0.75, // Adjusted for square thumbnails with text
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final decision = decisions[file] ?? SwipeDecision.undecided;
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onLongPress: () {
                            routeToPage(
                              context,
                              DetailPage(
                                DetailPageConfiguration(
                                  files,
                                  index,
                                  "group_summary_",
                                  mode: DetailPageMode.minimalistic,
                                ),
                              ),
                            );
                          },
                          child: AspectRatio(
                            aspectRatio: 1, // Square thumbnail
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Hero(
                                    tag: "group_summary_${file.tag}",
                                    child: ThumbnailWidget(
                                      file,
                                      fit: BoxFit.cover,
                                      shouldShowLivePhotoOverlay: false,
                                      shouldShowOwnerAvatar: false,
                                    ),
                                  ),
                                ),
                            
                            // Badge for deleted items (red trash icon)
                            if (decision == SwipeDecision.delete)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.warning700,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            
                            // Checkmark for kept items
                            if (decision == SwipeDecision.keep)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme.primary500,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: theme.backgroundBase,
                                  ),
                                ),
                              ),
                            
                            // Badge for undecided (using icon for consistent size)
                            if (decision == SwipeDecision.undecided)
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.question_mark_outlined,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        file.displayName,
                        style: textTheme.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.left,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatBytes(file.fileSize!),
                        style: textTheme.miniMuted,
                        textAlign: TextAlign.left,
                      ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons using Ente button design
            if (deletionCount > 0) ...[
              ButtonWidget(
                buttonType: ButtonType.critical,
                labelText: 'Confirm',
                onTap: () async {
                  onDeleteThese();
                },
                isInAlert: true,
              ),
              const SizedBox(height: 8),
            ],
            if (decisionCount > 0)
              ButtonWidget(
                buttonType: ButtonType.secondary,
                labelText: 'Undo decisions',
                onTap: () async {
                  onUndoAll();
                },
                isInAlert: true,
              ),
          ],
        ),
      ),
    );
  }
}