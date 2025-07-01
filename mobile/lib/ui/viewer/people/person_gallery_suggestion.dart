import "dart:async";
import "dart:typed_data";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
import "package:photos/theme/colors.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/cluster_page.dart";
import "package:photos/ui/viewer/people/file_face_widget.dart";
import "package:photos/ui/viewer/people/save_or_edit_person.dart";
import "package:photos/utils/face/face_thumbnail_cache.dart";

final _logger = Logger("PersonGallerySuggestion");

class PersonGallerySuggestion extends StatefulWidget {
  final PersonEntity person;

  const PersonGallerySuggestion({
    required this.person,
    super.key,
  });

  @override
  State<PersonGallerySuggestion> createState() =>
      _PersonGallerySuggestionState();
}

class _PersonGallerySuggestionState extends State<PersonGallerySuggestion>
    with TickerProviderStateMixin {
  List<ClusterSuggestion> allSuggestions = [];
  int currentSuggestionIndex = 0;
  Map<int, Uint8List?> faceCrops = {};
  bool isLoading = true;
  bool isProcessing = false;
  bool isPreparingNext = false;
  bool hasCurrentSuggestion = false;
  Map<int, Map<int, Uint8List?>> precomputedFaceCrops = {};

  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialSuggestion();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _slideController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );
  }

  Future<void> _loadInitialSuggestion() async {
    try {
      final suggestions = await ClusterFeedbackService.instance
          .getSuggestionForPerson(widget.person);

      if (suggestions.isNotEmpty && mounted) {
        allSuggestions = suggestions;
        currentSuggestionIndex = 0;

        final crops = await _generateFaceThumbnails(
          allSuggestions[0].filesInCluster.take(4).toList(),
          allSuggestions[0].clusterIDToMerge,
        );

        setState(() {
          faceCrops = crops;
          isLoading = false;
          hasCurrentSuggestion = true;
        });

        unawaited(_fadeController.forward());
        unawaited(_slideController.forward());

        unawaited(_precomputeNextSuggestions());
      } else {
        _logger.info("No suggestions found");
        if (mounted) {
          setState(() {
            isLoading = false;
          });
        }
      }
    } catch (e, s) {
      _logger.severe("Error loading suggestion", e, s);
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _precomputeNextSuggestions() async {
    try {
      // Precompute face crops for next two suggestions
      const maxPrecompute = 2;
      final endIndex = (currentSuggestionIndex + maxPrecompute)
          .clamp(0, allSuggestions.length);

      for (int i = currentSuggestionIndex + 1; i < endIndex; i++) {
        if (!mounted) break;

        final suggestion = allSuggestions[i];
        final crops = await _generateFaceThumbnails(
          suggestion.filesInCluster.take(4).toList(),
          suggestion.clusterIDToMerge,
        );

        if (mounted) {
          precomputedFaceCrops[i] = crops;
        }
      }
    } catch (e, s) {
      _logger.severe("Error precomputing next suggestions", e, s);
    }
  }

  Future<Map<int, Uint8List?>> _generateFaceThumbnails(
    List<EnteFile> files,
    String clusterID,
  ) async {
    final futures = <Future<Uint8List?>>[];
    for (final file in files) {
      futures.add(
        precomputeClusterFaceCrop(
          file,
          clusterID,
          useFullFile: true,
        ),
      );
    }
    final faceCropsList = await Future.wait(futures);
    final faceCrops = <int, Uint8List?>{};
    for (var i = 0; i < faceCropsList.length; i++) {
      faceCrops[files[i].uploadedFileID!] = faceCropsList[i];
    }
    return faceCrops;
  }

  void _navigateToCluster() {
    if (allSuggestions.isEmpty ||
        currentSuggestionIndex >= allSuggestions.length) {
      return;
    }

    final currentSuggestion = allSuggestions[currentSuggestionIndex];
    final List<EnteFile> sortedFiles = List<EnteFile>.from(
      currentSuggestion.filesInCluster,
    );
    sortedFiles.sort(
      (a, b) => b.creationTime!.compareTo(a.creationTime!),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClusterPage(
          sortedFiles,
          personID: widget.person,
          clusterID: currentSuggestion.clusterIDToMerge,
          showNamingBanner: false,
        ),
      ),
    );
  }

  Future<void> _handleUserChoice(bool accepted) async {
    if (isProcessing ||
        allSuggestions.isEmpty ||
        currentSuggestionIndex >= allSuggestions.length) {
      return;
    }

    setState(() {
      isProcessing = true;
    });
    unawaited(_animateOut());

    try {
      final currentSuggestion = allSuggestions[currentSuggestionIndex];

      if (accepted) {
        unawaited(
          ClusterFeedbackService.instance.addClusterToExistingPerson(
            person: widget.person,
            clusterID: currentSuggestion.clusterIDToMerge,
          ),
        );
      } else {
        unawaited(
          MLDataDB.instance.captureNotPersonFeedback(
            personID: widget.person.remoteID,
            clusterID: currentSuggestion.clusterIDToMerge,
          ),
        );
      }
      // Wait for animation to complete before hiding widget
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          hasCurrentSuggestion = false;
        });
      }
      await _prepareNextSuggestion();
    } catch (e, s) {
      _logger.severe("Error handling user choice", e, s);
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _saveAsAnotherPerson() async {
    if (isProcessing ||
        allSuggestions.isEmpty ||
        currentSuggestionIndex >= allSuggestions.length) {
      return;
    }
    setState(() {
      isProcessing = true;
    });
    unawaited(_animateOut());
    try {
      final currentSuggestion = allSuggestions[currentSuggestionIndex];
      final clusterID = currentSuggestion.clusterIDToMerge;
      final someFile = currentSuggestion.filesInCluster.first;

      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SaveOrEditPerson(
            clusterID,
            file: someFile,
            isEditing: false,
          ),
        ),
      );
      if (result == null || result == false) {
        // Animate back in and reset processing state
        unawaited(_animateIn());
        if (mounted) {
          setState(() {
            isProcessing = false;
          });
        }
        return;
      }
      // Wait for animation to complete before hiding widget
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() {
          hasCurrentSuggestion = false;
        });
      }

      await _prepareNextSuggestion();
    } catch (e, s) {
      _logger.severe("Error handling user choice", e, s);
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _prepareNextSuggestion() async {
    if (!mounted) return;

    // Move to next suggestion
    currentSuggestionIndex++;

    // Check if we have more suggestions
    if (currentSuggestionIndex < allSuggestions.length) {
      try {
        // Get face crops for next suggestion (from precomputed or generate new)
        Map<int, Uint8List?> nextCrops;
        if (precomputedFaceCrops.containsKey(currentSuggestionIndex)) {
          nextCrops = precomputedFaceCrops[currentSuggestionIndex]!;
        } else {
          final nextSuggestion = allSuggestions[currentSuggestionIndex];
          nextCrops = await _generateFaceThumbnails(
            nextSuggestion.filesInCluster.take(4).toList(),
            nextSuggestion.clusterIDToMerge,
          );
        }
        if (mounted) {
          setState(() {
            faceCrops = nextCrops;
            isProcessing = false;
            isPreparingNext = false;
            hasCurrentSuggestion = true;
          });
          await _animateIn();
          unawaited(_precomputeNextSuggestions());
        }
      } catch (e, s) {
        _logger.severe("Error preparing next suggestion", e, s);
        if (mounted) {
          setState(() {
            isProcessing = false;
            isPreparingNext = false;
            hasCurrentSuggestion = false;
          });
        }
      }
    } else {
      // No more suggestions available - stay hidden
      if (mounted) {
        setState(() {
          isProcessing = false;
          isPreparingNext = false;
          hasCurrentSuggestion = false;
        });
      }
    }
  }

  Future<void> _animateOut() async {
    await Future.wait([
      _fadeController.reverse(),
      _slideController.reverse(),
    ]);
  }

  Future<void> _animateIn() async {
    _slideController.reset();
    _fadeController.reset();
    await Future.wait([
      _fadeController.forward(),
      _slideController.forward(),
    ]);
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading ||
        allSuggestions.isEmpty ||
        currentSuggestionIndex >= allSuggestions.length ||
        !hasCurrentSuggestion) {
      return const SizedBox.shrink();
    }

    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          key: ValueKey('suggestion_$currentSuggestionIndex'),
          onTap: _navigateToCluster,
          behavior: HitTestBehavior.opaque,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.strokeFainter,
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: textTheme.body,
                    children: [
                      TextSpan(text: S.of(context).areThey),
                      TextSpan(
                        text: widget.person.data.name,
                        style: textTheme.bodyBold,
                      ),
                      TextSpan(text: S.of(context).questionmark),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildFaceThumbnails(),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: isProcessing
                            ? null
                            : () => _handleUserChoice(false),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.warning700,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                color: colorScheme.warning500,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).no,
                                style: textTheme.bodyBold.copyWith(
                                  color: colorScheme.warning500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap:
                            isProcessing ? null : () => _handleUserChoice(true),
                        child: Container(
                          margin: const EdgeInsets.only(left: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary500,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check,
                                color: textBaseDark,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                S.of(context).yes,
                                style: textTheme.bodyBold.copyWith(
                                  color: textBaseDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: isProcessing ? null : () => _saveAsAnotherPerson(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 32,
                    ),
                    child: Text(
                      S.of(context).saveAsAnotherPerson,
                      style: textTheme.mini.copyWith(
                        color: colorScheme.textMuted,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFaceThumbnails() {
    final currentSuggestion = allSuggestions[currentSuggestionIndex];
    final files = currentSuggestion.filesInCluster.take(4).toList();
    final thumbnails = <Widget>[];

    for (int i = 0; i < files.length; i++) {
      final file = files[i];
      final faceCrop = faceCrops[file.uploadedFileID!];

      if (i > 0) {
        thumbnails.add(const SizedBox(width: 8));
      }

      thumbnails.add(
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: getEnteColorScheme(context).strokeFainter,
              width: 1,
            ),
          ),
          child: ClipRRect(
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(52),
                ),
              ),
              child: FileFaceWidget(
                key: ValueKey(
                  'face_${currentSuggestionIndex}_${file.uploadedFileID}',
                ),
                file,
                faceCrop: faceCrop,
                clusterID: currentSuggestion.clusterIDToMerge,
                useFullFile: true,
                thumbnailFallback: true,
              ),
            ),
          ),
        ),
      );
    }

    return thumbnails;
  }
}
