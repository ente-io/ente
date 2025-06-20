import "dart:async";
import "dart:typed_data";

import 'package:flutter/material.dart';
import "package:logging/logging.dart";
import "package:photos/db/ml/db.dart";
import "package:photos/models/file/file.dart";
import "package:photos/models/ml/face/person.dart";
import "package:photos/services/machine_learning/face_ml/feedback/cluster_feedback.dart";
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
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
          .getFastSuggestionForPerson(widget.person);

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
        });

        // Start animations
        unawaited(_fadeController.forward());
        unawaited(_slideController.forward());

        unawaited(_precomputeNextSuggestions());
      } else {
        _logger.info("No suggestions found");
        setState(() {
          isLoading = false;
        });
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
      // Precompute face crops for next few suggestions
      const maxPrecompute = 3;
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
        currentSuggestionIndex >= allSuggestions.length) return;

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
        currentSuggestionIndex >= allSuggestions.length) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final currentSuggestion = allSuggestions[currentSuggestionIndex];

      if (accepted) {
        await ClusterFeedbackService.instance.addClusterToExistingPerson(
          person: widget.person,
          clusterID: currentSuggestion.clusterIDToMerge,
        );
      } else {
        await MLDataDB.instance.captureNotPersonFeedback(
          personID: widget.person.remoteID,
          clusterID: currentSuggestion.clusterIDToMerge,
        );
      }
      await _animateToNextSuggestion();
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
        currentSuggestionIndex >= allSuggestions.length) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final currentSuggestion = allSuggestions[currentSuggestionIndex];
      final clusterID = currentSuggestion.clusterIDToMerge;
      final someFile = currentSuggestion.filesInCluster.first;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => SaveOrEditPerson(
            clusterID,
            file: someFile,
            isEditing: false,
          ),
        ),
      );
      await _animateToNextSuggestion();
    } catch (e, s) {
      _logger.severe("Error handling user choice", e, s);
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  Future<void> _animateToNextSuggestion() async {
    // Animate out current suggestion first
    await _animateOut();
    // Move to next suggestion
    currentSuggestionIndex++;
    // Check if we have more suggestions
    if (currentSuggestionIndex < allSuggestions.length) {
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
      setState(() {
        faceCrops = nextCrops;
        isProcessing = false;
      });
      await Future.delayed(const Duration(milliseconds: 50));
      unawaited(_animateIn());
      // Continue precomputing future suggestions
      await Future.delayed(const Duration(milliseconds: 50));
      unawaited(_precomputeNextSuggestions());
    } else {
      setState(() {
        isProcessing = false;
      });
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
        currentSuggestionIndex >= allSuggestions.length) {
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
                      const TextSpan(text: "Are they "),
                      TextSpan(
                        text: widget.person.data.name,
                        style: textTheme.bodyBold,
                      ),
                      const TextSpan(text: "?"),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildFaceThumbnails(),
                ),
                const SizedBox(height: 16),
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
                            color: colorScheme.fillFaint,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colorScheme.strokeMuted,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close,
                                color: colorScheme.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "No",
                                style: textTheme.body,
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
                              Icon(
                                Icons.check,
                                color: colorScheme.textBase,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Yes",
                                style: textTheme.body.copyWith(
                                  color: colorScheme.textBase,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: isProcessing ? null : () => _saveAsAnotherPerson(),
                  child: Text(
                    "Save as another person",
                    style: textTheme.mini.copyWith(
                      color: colorScheme.textMuted,
                      decoration: TextDecoration.underline,
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
          width: 64,
          height: 64,
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
