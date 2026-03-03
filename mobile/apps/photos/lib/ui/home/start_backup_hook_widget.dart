import 'package:flutter/material.dart';
import 'package:photos/generated/l10n.dart';
import 'package:photos/service_locator.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/ui/common/backup_flow_helper.dart';
import 'package:photos/ui/common/gradient_button.dart';
import 'package:photos/ui/components/shimmer_loading.dart';

class StartBackupHookWidget extends StatelessWidget {
  final Widget headerWidget;
  final bool showShimmer;

  const StartBackupHookWidget({
    super.key,
    required this.headerWidget,
    required this.showShimmer,
  });

  @override
  Widget build(BuildContext context) {
    if (showShimmer) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headerWidget,
          const Expanded(child: StartBackupHookShimmer()),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headerWidget,
        const Expanded(child: StartBackupHookBody()),
      ],
    );
  }
}

class StartBackupHookBody extends StatelessWidget {
  const StartBackupHookBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: Image.asset(
                    "assets/onboarding_safe.png",
                    height: 206,
                  ),
                ),
                Text(
                  AppLocalizations.of(context).noPhotosAreBeingBackedUpRightNow,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall!
                      .copyWith(fontFamily: 'Inter-Medium', fontSize: 16),
                ),
                Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Container(
                      width: double.infinity,
                      height: 64,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: GradientButton(
                        onTap: () async {
                          await handleLimitedOrFolderBackupFlow(
                            context,
                            isFirstBackup: true,
                          );
                        },
                        text: AppLocalizations.of(context).startBackup,
                      ),
                    ),
                  ),
                ),
                const Padding(padding: EdgeInsets.all(50)),
              ],
            ),
          ),
        );
      },
    );
  }
}

class StartBackupHookShimmer extends StatelessWidget {
  const StartBackupHookShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShimmerGallerySkeleton();
  }
}

class _ShimmerGallerySkeleton extends StatelessWidget {
  static const _headerSkeletonWidth = 86.0;

  const _ShimmerGallerySkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final skeletonColor = isDark ? fillDarkestDark : fillDarkLight;
    final shimmerBaseColor = isDark ? fillDarkerDark : fillDarkLight;
    final highlightColor = isDark
        ? fillDarkestDark
        : contentLighterLight.withValues(
            alpha: 0.5,
          );
    const glowIntensity = 0.9;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = _SkeletonMetrics.fromConstraints(constraints);

        return ShimmerLoading(
          baseColor: shimmerBaseColor,
          highlightColor: highlightColor,
          duration: const Duration(milliseconds: 2000),
          glowIntensity: glowIntensity,
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: _SkeletonMetrics.topPadding),
                  if (metrics.firstSectionRows > 0) ...[
                    _SectionHeaderSkeleton(
                      color: skeletonColor,
                      width: _headerSkeletonWidth,
                    ),
                    _PhotoGridSkeleton(
                      rows: metrics.firstSectionRows,
                      crossAxisCount: metrics.crossAxisCount,
                      tileSize: metrics.tileSize,
                      spacing: _SkeletonMetrics.spacing,
                      color: skeletonColor,
                    ),
                  ],
                  if (metrics.secondSectionRows > 0) ...[
                    _SectionHeaderSkeleton(
                      color: skeletonColor,
                      width: _headerSkeletonWidth,
                    ),
                    _PhotoGridSkeleton(
                      rows: metrics.secondSectionRows,
                      crossAxisCount: metrics.crossAxisCount,
                      tileSize: metrics.tileSize,
                      spacing: _SkeletonMetrics.spacing,
                      color: skeletonColor,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonMetrics {
  static const topPadding = 8.0;
  static const spacing = 2.0;
  static const _sectionHeaderTextHeight = 14.0;
  static const _firstSectionTargetRows = 4;
  static const _secondSectionTargetRows = 3;

  final int crossAxisCount;
  final double tileSize;
  final int firstSectionRows;
  final int secondSectionRows;

  const _SkeletonMetrics({
    required this.crossAxisCount,
    required this.tileSize,
    required this.firstSectionRows,
    required this.secondSectionRows,
  });

  factory _SkeletonMetrics.fromConstraints(BoxConstraints constraints) {
    final crossAxisCount = localSettings.getPhotoGridSize();
    final tileSize = (constraints.maxWidth - (crossAxisCount - 1) * spacing) /
        crossAxisCount;

    final sectionHeaderVerticalPadding = crossAxisCount < 5 ? 12.0 : 14.0;
    final sectionHeaderHeight =
        (sectionHeaderVerticalPadding * 2) + _sectionHeaderTextHeight;

    final availableGridHeight =
        constraints.maxHeight - topPadding - (sectionHeaderHeight * 2);
    final gridAreaHeight =
        availableGridHeight.isNegative ? 0.0 : availableGridHeight;
    final computedRows =
        ((gridAreaHeight + spacing) / (tileSize + spacing)).floor();
    const targetTotalRows = _firstSectionTargetRows + _secondSectionTargetRows;
    final totalRows = computedRows.clamp(0, targetTotalRows).toInt();

    final int firstSectionRows;
    final int secondSectionRows;
    if (totalRows <= 0) {
      firstSectionRows = 0;
      secondSectionRows = 0;
    } else {
      firstSectionRows = totalRows.clamp(0, _firstSectionTargetRows).toInt();
      secondSectionRows = (totalRows - firstSectionRows)
          .clamp(0, _secondSectionTargetRows)
          .toInt();
    }

    return _SkeletonMetrics(
      crossAxisCount: crossAxisCount,
      tileSize: tileSize,
      firstSectionRows: firstSectionRows,
      secondSectionRows: secondSectionRows,
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  final Color color;
  final double width;

  const _SectionHeaderSkeleton({
    required this.color,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final gridSize = localSettings.getPhotoGridSize();
    final horizontalPadding = gridSize < 5 ? 12.0 : 8.0;
    final verticalPadding = gridSize < 5 ? 12.0 : 14.0;
    final headerHeight = (verticalPadding * 2) + 14;

    return SizedBox(
      height: headerHeight,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Container(
            width: width,
            height: 14,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}

class _PhotoGridSkeleton extends StatelessWidget {
  final int rows;
  final int crossAxisCount;
  final double tileSize;
  final double spacing;
  final Color color;

  const _PhotoGridSkeleton({
    required this.rows,
    required this.crossAxisCount,
    required this.tileSize,
    required this.spacing,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (rowIndex) {
        return Padding(
          padding: EdgeInsets.only(bottom: rowIndex == rows - 1 ? 0 : spacing),
          child: Row(
            children: List.generate(crossAxisCount, (colIndex) {
              return Padding(
                padding: EdgeInsets.only(
                  right: colIndex == crossAxisCount - 1 ? 0 : spacing,
                ),
                child: SizedBox(
                  width: tileSize,
                  height: tileSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}
