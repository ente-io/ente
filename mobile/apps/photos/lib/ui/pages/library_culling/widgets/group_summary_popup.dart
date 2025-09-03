import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/models/file/file.dart';
import 'package:photos/models/similar_files.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/pages/library_culling/models/swipe_culling_state.dart';
import 'package:photos/ui/viewer/file/thumbnail_widget.dart';
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
    final files = group.files;
    
    // Calculate stats
    int deletionCount = 0;
    int totalSize = 0;
    for (final file in files) {
      final decision = decisions[file] ?? SwipeDecision.undecided;
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
                  'Group Summary',
                  style: Theme.of(context).textTheme.titleLarge,
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
                  mainAxisSpacing: 8,
                ),
                itemCount: files.length,
                itemBuilder: (context, index) {
                  final file = files[index];
                  final decision = decisions[file] ?? SwipeDecision.undecided;
                  
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: ThumbnailWidget(
                          file,
                          fit: BoxFit.cover,
                          shouldShowLivePhotoOverlay: false,
                          shouldShowOwnerAvatar: false,
                        ),
                      ),
                      
                      // Overlay for deleted items
                      if (decision == SwipeDecision.delete)
                        Container(
                          decoration: BoxDecoration(
                            color: theme.warning700.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      
                      // Checkmark for kept items
                      if (decision == SwipeDecision.keep)
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
                              size: 16,
                              color: theme.backgroundBase,
                            ),
                          ),
                        ),
                      
                      // Badge for undecided
                      if (decision == SwipeDecision.undecided)
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.strokeFaint,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '?',
                              style: TextStyle(
                                color: theme.textFaint,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons (vertical layout)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (deletionCount > 0)
                  ElevatedButton(
                    onPressed: onDeleteThese,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.warning700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(AppLocalizations.of(context).deleteThese),
                  ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: onUndoAll,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(AppLocalizations.of(context).undoAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}