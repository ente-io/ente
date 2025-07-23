import "dart:async";
import "dart:math";

import "package:figma_squircle/figma_squircle.dart";
import "package:flutter/material.dart";
import "package:photos/models/search/generic_search_result.dart";
import "package:photos/models/search/recent_searches.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/file/no_thumbnail_widget.dart";
import "package:photos/ui/viewer/file/thumbnail_widget.dart";
import "package:photos/ui/viewer/search/result/search_result_page.dart";
import "package:photos/utils/navigation_util.dart";

class MemoriesDebugSection extends StatefulWidget {
  final List<GenericSearchResult> momentsSearchResults;
  final VoidCallback onTapCallback;
  const MemoriesDebugSection(
    this.momentsSearchResults,
    this.onTapCallback, {
    super.key,
  });

  @override
  State<MemoriesDebugSection> createState() => _MemoriesDebugSectionState();
}

class _MemoriesDebugSectionState extends State<MemoriesDebugSection> {
  late List<GenericSearchResult> _momentsSearchResults;
  final streamSubscriptions = <StreamSubscription>[];

  @override
  void initState() {
    super.initState();
    _momentsSearchResults = widget.momentsSearchResults;
  }

  @override
  void dispose() {
    for (var subscriptions in streamSubscriptions) {
      subscriptions.cancel();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MemoriesDebugSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    _momentsSearchResults = widget.momentsSearchResults;
  }

  @override
  Widget build(BuildContext context) {
    if (_momentsSearchResults.isEmpty) {
      final textTheme = getEnteTextTheme(context);
      return Padding(
        padding: const EdgeInsets.only(left: 12, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Smart memories debug (I)",
                    style: textTheme.largeBold,
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      "Test memories",
                      style: textTheme.smallMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(widget.onTapCallback),
            const SizedBox(height: 2),
            SizedBox(
              child: SingleChildScrollView(
                clipBehavior: Clip.none,
                padding: const EdgeInsets.symmetric(horizontal: 4.5),
                physics: const BouncingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _momentsSearchResults
                      .map(
                        (momentSearchResult) =>
                            MomentRecommendation(momentSearchResult),
                      )
                      .toList(),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final VoidCallback onTapCallback;
  const _SectionHeader(this.onTapCallback);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCallback,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "Smart memories debug (I)",
              style: getEnteTextTheme(context).largeBold,
            ),
          ),
          Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 12, 12),
              child: Icon(
                Icons.chevron_right_outlined,
                color: getEnteColorScheme(context).blurStrokePressed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MomentRecommendation extends StatelessWidget {
  static const _width = 100.0;
  static const _height = 145.0;
  static const _borderWidth = 1.0;
  static const _cornerRadius = 5.0;
  static const _cornerSmoothing = 1.0;
  final GenericSearchResult momentSearchResult;
  const MomentRecommendation(this.momentSearchResult, {super.key});

  @override
  Widget build(BuildContext context) {
    final heroTag = momentSearchResult.heroTag() +
        (momentSearchResult.previewThumbnail()?.tag ?? "");
    final enteTextTheme = getEnteTextTheme(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: max(2.5 - _borderWidth, 0)),
      child: GestureDetector(
        onTap: () {
          RecentSearches().add(momentSearchResult.name());
          if (momentSearchResult.onResultTap != null) {
            momentSearchResult.onResultTap!(context);
          } else {
            routeToPage(
              context,
              SearchResultPage(momentSearchResult),
            );
          }
        },
        child: SizedBox(
          width: _width + _borderWidth * 2,
          height: _height + _borderWidth * 2,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              ClipSmoothRect(
                radius: SmoothBorderRadius(
                  cornerRadius: _cornerRadius + _borderWidth,
                  cornerSmoothing: _cornerSmoothing,
                ),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.16),
                  width: _width + _borderWidth * 2,
                  height: _height + _borderWidth * 2,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6.25,
                      offset: const Offset(-1.25, 2.5),
                    ),
                  ],
                ),
                child: ClipSmoothRect(
                  radius: SmoothBorderRadius(
                    cornerRadius: _cornerRadius,
                    cornerSmoothing: _cornerSmoothing,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    clipBehavior: Clip.none,
                    children: [
                      SizedBox(
                        width: _width,
                        height: _height,
                        child: momentSearchResult.previewThumbnail() != null
                            ? Hero(
                                tag: heroTag,
                                child: ThumbnailWidget(
                                  momentSearchResult.previewThumbnail()!,
                                  shouldShowArchiveStatus: false,
                                  shouldShowSyncStatus: false,
                                ),
                              )
                            : const NoThumbnailWidget(),
                      ),
                      Container(
                        height: 145,
                        width: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0),
                              Colors.black.withValues(alpha: 0.5),
                            ],
                            stops: const [
                              0,
                              0.1,
                              1,
                            ],
                          ),
                        ),
                      ),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: 76,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(
                            bottom: 8,
                          ),
                          child: Text(
                            momentSearchResult.name(),
                            style: enteTextTheme.small.copyWith(
                              color: Colors.white,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
