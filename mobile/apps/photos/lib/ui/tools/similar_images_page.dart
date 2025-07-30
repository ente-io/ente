import "dart:async";

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import "package:photos/models/file/file.dart";
import "package:photos/models/similar_files.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/machine_learning/similar_images_service.dart";
import 'package:photos/theme/ente_theme.dart';
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/components/buttons/button_widget.dart';
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/ui/viewer/file/detail_page.dart";
import "package:photos/ui/viewer/file/file_widget.dart";
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
  distance,
  count,
}

class SimilarImagesPage extends StatefulWidget {
  const SimilarImagesPage({super.key});

  @override
  State<SimilarImagesPage> createState() => _SimilarImagesPageState();
}

class _SimilarImagesPageState extends State<SimilarImagesPage> {
  final _logger = Logger("SimilarImagesPage");

  SimilarImagesPageState _pageState = SimilarImagesPageState.setup;
  double _distanceThreshold = 0.04; // Default value
  List<SimilarFiles> _similarFilesList = [];
  SortKey _sortKey = SortKey.size;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: const Text("Similar Images"), // TODO: lau: extract string
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
                setState(() {
                  _pageState = SimilarImagesPageState.setup;
                });
              },
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
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
        ),
        Expanded(
          child: _getGridView(),
        ),
      ],
    );
  }

  Future<void> _findSimilarImages() async {
    setState(() {
      _pageState = SimilarImagesPageState.loading;
    });

    try {
      final similarFiles = await SimilarImagesService.instance
          .getSimilarFiles(_distanceThreshold);
      _logger.info(
        "Found ${similarFiles.length} groups of similar images",
      );
      _sortSimilarFiles();
      _logger.fine(
        "Sorted similar files by $_sortKey",
      );

      setState(() {
        _similarFilesList = similarFiles;
        _pageState = SimilarImagesPageState.results;
      });

      return;
    } catch (e, s) {
      _logger.severe("Failed to get similar files", e, s);
      if (flagService.internalUser) {
        await showGenericErrorDialog(context: context, error: e);
      }
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
      case SortKey.distance:
        _similarFilesList
            .sort((a, b) => a.furthestDistance.compareTo(b.furthestDistance));
        break;
      case SortKey.count:
        _similarFilesList
            .sort((a, b) => b.files.length.compareTo(a.files.length));
        break;
    }
    setState(() {});
  }

  Widget _getGridView() {
    return ListView.builder(
      itemCount: _similarFilesList.length,
      itemBuilder: (context, index) {
        final similarFiles = _similarFilesList[index];
        return _buildSimilarFilesGroup(similarFiles, index);
      },
    );
  }

  Widget _buildSimilarFilesGroup(SimilarFiles similarFiles, int index) {
    final colorScheme = getEnteColorScheme(context);

    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.strokeFaint),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.fillFaint,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${similarFiles.files.length} similar images", // TODO: lau: extract string
                        style: getEnteTextTheme(context).bodyBold,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Total size: ${formatBytes(similarFiles.totalSize)}", // TODO: lau: extract string
                        style: getEnteTextTheme(context).mini,
                      ),
                      Text(
                        "Distance: ${similarFiles.furthestDistance.toStringAsFixed(3)}", // TODO: lau: extract string
                        style: getEnteTextTheme(context).mini.copyWith(
                              color: colorScheme.textMuted,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: similarFiles.files.length,
            itemBuilder: (context, fileIndex) {
              return _buildFile(
                context,
                similarFiles.files[fileIndex],
                similarFiles.files,
                fileIndex,
              );
            },
          ),
        ],
      ),
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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: getEnteColorScheme(context).strokeFaint,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: FileWidget(
            file,
            tagPrefix: "similar_images",
          ),
        ),
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
        case SortKey.distance:
          text = "Similarity"; // TODO: lau: extract string
          break;
        case SortKey.count:
          text = "Count"; // TODO: lau: extract string
          break;
      }
      return Text(
        text,
        style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontSize: 14,
              color: Theme.of(context).iconTheme.color!.withOpacity(0.7),
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
