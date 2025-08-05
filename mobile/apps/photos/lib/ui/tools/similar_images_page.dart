import "dart:async";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:photos/core/constants.dart';

import "package:photos/models/file/file.dart";
import "package:photos/models/similar_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/similar_images_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/components/toggle_switch_widget.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/utils/dialog_util.dart";
import "package:photos/utils/navigation_util.dart";
import "package:photos/utils/standalone/data.dart";

enum SimilarImagesPageState {
  setup,
  loading,
  results,
}

enum SortKey {
  size,
  distanceAsc,
  distanceDesc,
  count,
}

class SimilarImagesPage extends StatefulWidget {
  const SimilarImagesPage({super.key});

  @override
  State<SimilarImagesPage> createState() => _SimilarImagesPageState();
}

class _SimilarImagesPageState extends State<SimilarImagesPage> {
  static const crossAxisCount = 3;
  static const crossAxisSpacing = 16.0;

  final _logger = Logger("SimilarImagesPage");
  bool _isDisposed = false;

  SimilarImagesPageState _pageState = SimilarImagesPageState.setup;
  double _distanceThreshold = 0.04; // Default value
  List<SimilarFiles> _similarFilesList = [];
  SortKey _sortKey = SortKey.size;
  bool _exactSearch = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Similar images"), // TODO: lau: extract string
        actions: _pageState == SimilarImagesPageState.results
            ? [
                _getSortMenu(),
              ]
            : null,
      ),
      body: _getBody(),
    );
  }

  Widget _getBody() {
    switch (_pageState) {
      case SimilarImagesPageState.setup:
        return _getSetupView();
      case SimilarImagesPageState.loading:
        return _getLoadingView();
      case SimilarImagesPageState.results:
        return _getResultsView();
    }
  }

  Widget _getSetupView() {
    final colorScheme = getEnteColorScheme(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.auto_awesome_outlined,
            size: 72,
            color: colorScheme.primary500,
          ),
          const SizedBox(height: 32),
          Text(
            "Find similar images", // TODO: lau: extract string
            style: getEnteTextTheme(context).h3Bold,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            "Use AI to find images that look similar to each other. Adjust the distance threshold below.", // TODO: lau: extract string
            style: getEnteTextTheme(context).body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            "Similarity threshold", // TODO: lau: extract string
            style: getEnteTextTheme(context).bodyBold,
          ),
          const SizedBox(height: 8),
          Text(
            "Lower values mean a closer match.", // TODO: lau: extract string
            style: getEnteTextTheme(context).mini.copyWith(
                  color: colorScheme.textMuted,
                ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                "0.01",
                style: getEnteTextTheme(context).mini,
              ),
              Expanded(
                child: Slider(
                  value: _distanceThreshold,
                  min: 0.01,
                  max: 0.15,
                  divisions: 14,
                  onChanged: (value) {
                    if (_isDisposed) return;
                    setState(() {
                      _distanceThreshold = (value * 100).round() / 100;
                    });
                  },
                ),
              ),
              Text(
                "0.15",
                style: getEnteTextTheme(context).mini,
              ),
            ],
          ),
          Text(
            "Current: ${_distanceThreshold.toStringAsFixed(2)}", // TODO: lau: extract string
            style: getEnteTextTheme(context).body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Exact search", // TODO: lau: extract string
                style: getEnteTextTheme(context).bodyBold,
              ),
              ToggleSwitchWidget(
                value: () => _exactSearch,
                onChanged: () async {
                  if (_isDisposed) return;
                  setState(() {
                    _exactSearch = !_exactSearch;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          ButtonWidget(
            labelText: "Find similar images", // TODO: lau: extract string
            buttonType: ButtonType.primary,
            onTap: () async {
              await _findSimilarImages();
            },
          ),
        ],
      ),
    );
  }

  Widget _getLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          EnteLoadingWidget(),
          SizedBox(height: 16),
          Text("Analyzing images..."), // TODO: lau: extract string
        ],
      ),
    );
  }

  Widget _getResultsView() {
    if (_similarFilesList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: getEnteColorScheme(context).primary500,
            ),
            const SizedBox(height: 16),
            Text(
              "No Similar Images Found", // TODO: lau: extract string
              style: getEnteTextTheme(context).h3Bold,
            ),
            const SizedBox(height: 8),
            Text(
              "Try adjusting the similarity threshold", // TODO: lau: extract string
              style: getEnteTextTheme(context).body,
            ),
            const SizedBox(height: 32),
            ButtonWidget(
              labelText: "Try Again", // TODO: lau: extract string
              buttonType: ButtonType.secondary,
              onTap: () async {
                if (_isDisposed) return;
                setState(() {
                  _pageState = SimilarImagesPageState.setup;
                });
              },
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _similarFilesList.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          // Header item
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getEnteColorScheme(context).fillFaint,
              border: Border(
                bottom: BorderSide(
                  color: getEnteColorScheme(context).strokeFaint,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              children: [
                Text(
                  "Found ${_similarFilesList.length} groups of similar images", // TODO: lau: extract string
                  style: getEnteTextTheme(context).bodyBold,
                ),
                const SizedBox(height: 4),
                Text(
                  "Threshold: ${_distanceThreshold.toStringAsFixed(2)}", // TODO: lau: extract string
                  style: getEnteTextTheme(context).mini.copyWith(
                        color: getEnteColorScheme(context).textMuted,
                      ),
                ),
              ],
            ),
          );
        }

        // Similar files groups (index - 1 because first item is header)
        final similarFiles = _similarFilesList[index - 1];
        return _buildSimilarFilesGroup(similarFiles);
      },
    );
  }

  Future<void> _findSimilarImages() async {
    if (_isDisposed) return;
    setState(() {
      _pageState = SimilarImagesPageState.loading;
    });

    try {
      // You can use _toggleValue here for advanced mode features
      _logger.info("exact mode: $_exactSearch");

      final similarFiles = await SimilarImagesService.instance
          .getSimilarFiles(_distanceThreshold, exact: _exactSearch);
      _logger.info(
        "Found ${similarFiles.length} groups of similar images",
      );

      if (_isDisposed) return;
      _sortSimilarFiles();
      _logger.fine(
        "Sorted similar files by $_sortKey",
      );

      if (_isDisposed) return;
      setState(() {
        _similarFilesList = similarFiles;
        _pageState = SimilarImagesPageState.results;
      });

      return;
    } catch (e, s) {
      _logger.severe("Failed to get similar files", e, s);
      if (_isDisposed) return;
      if (flagService.internalUser) {
        await showGenericErrorDialog(context: context, error: e);
      }
      if (_isDisposed) return;
      setState(() {
        _pageState = SimilarImagesPageState.setup;
      });
      return;
    }
  }

  void _sortSimilarFiles() {
    switch (_sortKey) {
      case SortKey.size:
        _similarFilesList.sort((a, b) => b.totalSize.compareTo(a.totalSize));
        break;
      case SortKey.distanceAsc:
        _similarFilesList
            .sort((a, b) => a.furthestDistance.compareTo(b.furthestDistance));
        break;
      case SortKey.distanceDesc:
        _similarFilesList
            .sort((a, b) => b.furthestDistance.compareTo(a.furthestDistance));
        break;
      case SortKey.count:
        _similarFilesList
            .sort((a, b) => b.files.length.compareTo(a.files.length));
        break;
    }
    if (_isDisposed) return;
    setState(() {});
  }

  Widget _buildSimilarFilesGroup(SimilarFiles similarFiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${similarFiles.files.length} similar images • ${formatBytes(similarFiles.totalSize)}", // TODO: lau: extract string
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Distance: ${similarFiles.furthestDistance.toStringAsFixed(3)}", // TODO: lau: extract string
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: getEnteColorScheme(context).textMuted,
                            fontSize: 12,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: crossAxisSpacing / 2),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return _buildFile(
                context,
                similarFiles.files[index],
                similarFiles.files,
                index,
              );
            },
            itemCount: similarFiles.files.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: 0.75,
            ),
            padding: const EdgeInsets.all(0),
          ),
        ),
        const SizedBox(height: 16), // Add spacing between groups
      ],
    );
  }

  Widget _buildFile(
    BuildContext context,
    EnteFile file,
    List<EnteFile> allFiles,
    int index,
  ) {
    return GestureDetector(
      onTap: () {
        routeToPage(
          context,
          DetailPage(
            DetailPageConfiguration(
              allFiles,
              index,
              "similar_images_",
              mode: DetailPageMode.minimalistic,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: (MediaQuery.of(context).size.width -
                    (crossAxisSpacing * crossAxisCount)) /
                crossAxisCount,
            child: Hero(
              tag: "similar_images_" + file.tag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: ThumbnailWidget(
                  file,
                  diskLoadDeferDuration: galleryThumbnailDiskLoadDeferDuration,
                  serverLoadDeferDuration:
                      galleryThumbnailServerLoadDeferDuration,
                  shouldShowLivePhotoOverlay: true,
                  key: Key("similar_images_" + file.tag),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSortMenu() {
    Text sortOptionText(SortKey key) {
      String text = key.toString();
      switch (key) {
        case SortKey.size:
          text = "Size"; // TODO: lau: extract string
          break;
        case SortKey.distanceAsc:
          text = "Distance ascending"; // TODO: lau: extract string
          break;
        case SortKey.distanceDesc:
          text = "Distance descending"; // TODO: lau: extract string
          break;
        case SortKey.count:
          text = "Count"; // TODO: lau: extract string
          break;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withValues(alpha: 0.7),
            ),
      );
    }

    return PopupMenuButton(
      initialValue: _sortKey.index,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            sortOptionText(_sortKey),
            const Padding(padding: EdgeInsets.only(left: 4)),
            Icon(
              Icons.sort,
              color: getEnteColorScheme(context).strokeBase,
              size: 20,
            ),
          ],
        ),
      ),
      onSelected: (int index) {
        if (_isDisposed) return;
        setState(() {
          _sortKey = SortKey.values[index];
        });
        _sortSimilarFiles();
      },
      itemBuilder: (context) {
        return List.generate(SortKey.values.length, (index) {
          return PopupMenuItem(
            value: index,
            child: Text(
              sortOptionText(SortKey.values[index]).data!,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    fontSize: 14,
                  ),
            ),
          );
        });
      },
    );
  }
}
