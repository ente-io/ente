import 'dart:ui';

import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=11439-5036&m=dev
/// Section: Appbar/header / Header v2
/// Specs: Pinned sliver app bar that animates between expanded and collapsed
/// states as the surrounding scroll view collapses it.
class HeaderAppBarComponent extends StatelessWidget {
  const HeaderAppBarComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.backButton,
    this.onBack,
    this.actions = const [],
    this.expandedHeight = 116,
    this.collapsedHeight = 56,
    this.horizontalPadding = Spacing.lg,
    this.backgroundColor,
    this.showExpandedBackButton = true,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? backButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double expandedHeight;
  final double collapsedHeight;
  final double horizontalPadding;
  final Color? backgroundColor;
  final bool showExpandedBackButton;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final expandedTitleLineHeight = _scaledLineHeight(
      textScaler,
      TextStyles.h1Bold,
    );
    final collapsedTitleLineHeight = _scaledLineHeight(
      textScaler,
      TextStyles.h2,
    );
    final subtitleLineHeight = _scaledLineHeight(textScaler, TextStyles.mini);
    final effectiveCollapsedHeight = _maxDouble(
      collapsedHeight,
      _maxDouble(_headerControlSize, collapsedTitleLineHeight),
    );
    final effectiveExpandedHeight = _maxDouble(
      expandedHeight,
      _expandedContentTop +
          expandedTitleLineHeight +
          (subtitle == null ? 0 : _subtitleGap + subtitleLineHeight),
    );

    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderAppBarDelegate(
        title: title,
        subtitle: subtitle,
        leading: leading,
        backButton: backButton,
        onBack: onBack,
        actions: actions,
        expandedHeight: effectiveExpandedHeight,
        collapsedHeight: effectiveCollapsedHeight,
        horizontalPadding: horizontalPadding,
        topPadding: MediaQuery.paddingOf(context).top,
        backgroundColor: backgroundColor,
        showExpandedBackButton: showExpandedBackButton,
        expandedTitleLineHeight: expandedTitleLineHeight,
        collapsedTitleLineHeight: collapsedTitleLineHeight,
        subtitleLineHeight: subtitleLineHeight,
      ),
    );
  }
}

class _HeaderAppBarDelegate extends SliverPersistentHeaderDelegate {
  const _HeaderAppBarDelegate({
    required this.title,
    required this.subtitle,
    required this.leading,
    required this.backButton,
    required this.onBack,
    required this.actions,
    required this.expandedHeight,
    required this.collapsedHeight,
    required this.horizontalPadding,
    required this.topPadding,
    required this.backgroundColor,
    required this.showExpandedBackButton,
    required this.expandedTitleLineHeight,
    required this.collapsedTitleLineHeight,
    required this.subtitleLineHeight,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? backButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double expandedHeight;
  final double collapsedHeight;
  final double horizontalPadding;
  final double topPadding;
  final Color? backgroundColor;
  final bool showExpandedBackButton;
  final double expandedTitleLineHeight;
  final double collapsedTitleLineHeight;
  final double subtitleLineHeight;

  @override
  double get maxExtent => topPadding + expandedHeight;

  @override
  double get minExtent => topPadding + collapsedHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = context.componentColors;
    final scrollRange = maxExtent - minExtent;
    final progress = scrollRange == 0
        ? 1.0
        : (shrinkOffset / scrollRange).clamp(0.0, 1.0);
    final titleProgress = Curves.easeInOut.transform(
      (progress / 0.85).clamp(0.0, 1.0),
    );
    final collapsedControlTop = _centeredTop(
      collapsedHeight,
      _headerControlSize,
    );
    final collapsedTitleTop = _centeredTop(
      collapsedHeight,
      collapsedTitleLineHeight,
    );
    final expandedTextBlockHeight =
        expandedTitleLineHeight +
        (subtitle == null ? 0 : _subtitleGap + subtitleLineHeight);
    final leadingTop =
        _expandedContentTop +
        _centerOffset(expandedTextBlockHeight, _headerControlSize);
    final actionsTop = lerpDouble(
      _expandedContentTop,
      collapsedControlTop,
      titleProgress,
    )!;
    final collapsedTitleLeft = _collapsedLeadingWidth(backButton) + Spacing.md;
    final titleLeft = lerpDouble(
      leading == null ? 0 : _headerControlSize + Spacing.md,
      showExpandedBackButton ? collapsedTitleLeft : 0,
      titleProgress,
    )!;
    final titleTop = lerpDouble(
      _expandedContentTop,
      collapsedTitleTop,
      titleProgress,
    )!;
    final titleRight = actions.isEmpty
        ? 0.0
        : _actionsWidth(actions.length) + Spacing.md;
    final leadingOpacity = 1 - titleProgress;
    final isLeadingHidden = leadingOpacity <= 0.01;

    return ColoredBox(
      color: backgroundColor ?? colors.backgroundBase,
      child: Padding(
        padding: EdgeInsets.only(
          top: topPadding,
          left: horizontalPadding,
          right: horizontalPadding,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (leading != null)
              Positioned(
                left: 0,
                top: leadingTop,
                child: IgnorePointer(
                  ignoring: isLeadingHidden,
                  child: ExcludeSemantics(
                    excluding: isLeadingHidden,
                    child: Opacity(
                      opacity: leadingOpacity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox.square(
                          dimension: _headerControlSize,
                          child: leading,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            _MovingHeaderTitle(
              title: title,
              top: titleTop,
              left: titleLeft,
              right: titleRight,
              progress: titleProgress,
            ),
            if (subtitle != null)
              Positioned(
                left: titleLeft,
                right: titleRight,
                top:
                    _expandedContentTop +
                    expandedTitleLineHeight +
                    _subtitleGap,
                child: IgnorePointer(
                  child: ExcludeSemantics(
                    child: Opacity(
                      opacity: 1 - titleProgress,
                      child: Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyles.mini.copyWith(
                          color: colors.textLight,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: _PinnedHeaderChrome(
                backButton: backButton,
                onBack: onBack,
                actions: actions,
                actionsTop: actionsTop,
                chromeHeight: collapsedHeight,
                showBackButton: showExpandedBackButton,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderAppBarDelegate oldDelegate) {
    return oldDelegate.title != title ||
        oldDelegate.subtitle != subtitle ||
        oldDelegate.leading != leading ||
        oldDelegate.backButton != backButton ||
        oldDelegate.onBack != onBack ||
        oldDelegate.actions != actions ||
        oldDelegate.expandedHeight != expandedHeight ||
        oldDelegate.collapsedHeight != collapsedHeight ||
        oldDelegate.horizontalPadding != horizontalPadding ||
        oldDelegate.topPadding != topPadding ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.showExpandedBackButton != showExpandedBackButton ||
        oldDelegate.expandedTitleLineHeight != expandedTitleLineHeight ||
        oldDelegate.collapsedTitleLineHeight != collapsedTitleLineHeight ||
        oldDelegate.subtitleLineHeight != subtitleLineHeight;
  }
}

class _PinnedHeaderChrome extends StatelessWidget {
  const _PinnedHeaderChrome({
    required this.backButton,
    required this.onBack,
    required this.actions,
    required this.actionsTop,
    required this.chromeHeight,
    required this.showBackButton,
  });

  final Widget? backButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double actionsTop;
  final double chromeHeight;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (showBackButton)
          Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeaderAppBarBackButton(
                  backButton: backButton,
                  onBack: onBack,
                  height: chromeHeight,
                ),
                const SizedBox(width: Spacing.md),
              ],
            ),
          ),
        if (actions.isNotEmpty)
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: EdgeInsets.only(top: actionsTop),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minHeight: _headerControlSize,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var index = 0; index < actions.length; index++) ...[
                      actions[index],
                      if (index != actions.length - 1)
                        const SizedBox(width: _headerControlGap),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderAppBarBackButton extends StatelessWidget {
  const _HeaderAppBarBackButton({
    required this.backButton,
    required this.onBack,
    required this.height,
  });

  final Widget? backButton;
  final VoidCallback? onBack;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    if (backButton != null) {
      return backButton!;
    }

    return SizedBox(
      width: _defaultBackIconSize,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: SizedBox.square(
              dimension: _defaultBackIconSize,
              child: Icon(
                Icons.arrow_back,
                color: colors.textBase,
                size: _defaultBackIconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _headerControlSize = 38.0;
const _headerControlGap = Spacing.sm;
const _defaultBackIconSize = 24.0;
const _expandedContentTop = 48.0;
const _subtitleGap = 2.0;

double _collapsedLeadingWidth(Widget? backButton) {
  return backButton == null ? _defaultBackIconSize : _headerControlSize;
}

double _centeredTop(double containerHeight, double childHeight) {
  return ((containerHeight - childHeight) / 2)
      .clamp(0.0, double.infinity)
      .toDouble();
}

double _centerOffset(double containerHeight, double childHeight) {
  return (containerHeight - childHeight) / 2;
}

double _maxDouble(double first, double second) {
  return first > second ? first : second;
}

double _scaledLineHeight(TextScaler textScaler, TextStyle style) {
  final fontSize = style.fontSize ?? 14;
  final height = style.height ?? 1;
  return textScaler.scale(fontSize) * height;
}

double _actionsWidth(int actionCount) {
  return (actionCount * _headerControlSize) +
      ((actionCount - 1) * _headerControlGap).clamp(0, double.infinity);
}

class _MovingHeaderTitle extends StatelessWidget {
  const _MovingHeaderTitle({
    required this.title,
    required this.top,
    required this.left,
    required this.right,
    required this.progress,
  });

  final String title;
  final double top;
  final double left;
  final double right;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;

    return Positioned(
      left: left,
      right: right,
      top: top,
      child: IgnorePointer(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle.lerp(
            TextStyles.h1Bold,
            TextStyles.h2,
            progress,
          )!.copyWith(color: colors.textBase),
        ),
      ),
    );
  }
}
