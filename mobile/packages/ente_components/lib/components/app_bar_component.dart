import 'dart:ui';

import 'package:ente_components/theme/colors.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

enum TitleBarComponentVariant {
  brand,
  home,
  preserving,
  partiallyPreserved,
  preserved,
  syncing,
  videoProcessing,
  back,
  onboarding,
  settings,
  titleTopbar,
  titleTopbarNoIcon,
  onboardingTitle,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2472-5809&m=dev
/// Section: Title Bar
/// Specs: 327px design width, 42px title/status row, centered or leading title layouts.
class TitleBarComponent extends StatelessWidget implements PreferredSizeWidget {
  const TitleBarComponent({
    super.key,
    this.variant = TitleBarComponentVariant.brand,
    this.title,
    this.statusText,
    this.leading,
    this.trailing,
    this.statusIcon,
    this.height = 42,
    this.leadingWidth = 44,
    this.trailingWidth = 44,
  });

  final TitleBarComponentVariant variant;
  final String? title;
  final String? statusText;
  final Widget? leading;
  final Widget? trailing;
  final Widget? statusIcon;
  final double height;
  final double leadingWidth;
  final double trailingWidth;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final child = variant == TitleBarComponentVariant.titleTopbarNoIcon
        ? _buildLeadingTitleBar(colors)
        : _buildCenteredTitleBar(colors);

    return IconTheme(
      data: IconThemeData(color: colors.textBase, size: 24),
      child: SizedBox(height: height, child: child),
    );
  }

  Widget _buildCenteredTitleBar(ColorTokens colors) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _centerContentHorizontalPadding,
          ),
          child: ColoredBox(
            color: colors.specialScrim.withAlpha(0),
            child: Center(child: _centerContent(colors)),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: _TitleBarSlot(
            width: leadingWidth,
            visible: _leadingVisible,
            child: leading,
          ),
        ),
        Positioned(
          right: 0,
          top: 0,
          bottom: 0,
          child: _TitleBarSlot(
            width: trailingWidth,
            visible: _trailingVisible,
            alignment: Alignment.centerRight,
            child: trailing,
          ),
        ),
      ],
    );
  }

  Widget _buildLeadingTitleBar(ColorTokens colors) {
    return Row(
      children: [
        _TitleBarSlot(
          width: leadingWidth,
          visible: _leadingVisible,
          child: leading,
        ),
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Text(
            _effectiveTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.h1Bold.copyWith(color: colors.textBase),
          ),
        ),
        _TitleBarSlot(
          width: trailingWidth,
          visible: _trailingVisible,
          alignment: Alignment.centerRight,
          child: trailing,
        ),
      ],
    );
  }

  Widget _centerContent(ColorTokens colors) {
    if (_usesStatus) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (statusIcon != null) ...[
            IconTheme(
              data: IconThemeData(color: colors.primary, size: 20),
              child: SizedBox.square(dimension: 20, child: statusIcon),
            ),
            const SizedBox(width: Spacing.sm),
          ],
          Flexible(
            child: Text(
              _effectiveStatusText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.body.copyWith(color: colors.textBase),
            ),
          ),
        ],
      );
    }

    if (!_titleVisible) {
      return const SizedBox.shrink();
    }

    return Text(
      _effectiveTitle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: _usesHeadingStyle
          ? TextStyles.h1Bold.copyWith(color: colors.textBase)
          : TextStyles.h1.copyWith(color: colors.textBase),
    );
  }

  bool get _usesStatus {
    return switch (variant) {
      TitleBarComponentVariant.preserving ||
      TitleBarComponentVariant.partiallyPreserved ||
      TitleBarComponentVariant.preserved ||
      TitleBarComponentVariant.syncing ||
      TitleBarComponentVariant.videoProcessing => true,
      _ => false,
    };
  }

  bool get _usesHeadingStyle {
    return switch (variant) {
      TitleBarComponentVariant.titleTopbar ||
      TitleBarComponentVariant.titleTopbarNoIcon ||
      TitleBarComponentVariant.onboardingTitle => true,
      _ => false,
    };
  }

  bool get _titleVisible {
    return switch (variant) {
      TitleBarComponentVariant.back ||
      TitleBarComponentVariant.settings => false,
      _ => true,
    };
  }

  bool get _leadingVisible {
    return switch (variant) {
      TitleBarComponentVariant.onboarding => false,
      _ => true,
    };
  }

  bool get _trailingVisible {
    return switch (variant) {
      TitleBarComponentVariant.home ||
      TitleBarComponentVariant.preserving ||
      TitleBarComponentVariant.partiallyPreserved ||
      TitleBarComponentVariant.preserved ||
      TitleBarComponentVariant.syncing ||
      TitleBarComponentVariant.videoProcessing ||
      TitleBarComponentVariant.settings ||
      TitleBarComponentVariant.titleTopbar ||
      TitleBarComponentVariant.titleTopbarNoIcon => true,
      _ => false,
    };
  }

  String get _effectiveTitle {
    if (title != null) {
      return title!;
    }
    return _usesHeadingStyle ? 'Heading' : 'ente';
  }

  String get _effectiveStatusText {
    if (statusText != null) {
      return statusText!;
    }
    return switch (variant) {
      TitleBarComponentVariant.preserving => 'Preserving 3 memories',
      TitleBarComponentVariant.partiallyPreserved => '1/3 memories preserved',
      TitleBarComponentVariant.preserved => 'All memories preserved',
      TitleBarComponentVariant.syncing => 'Syncing...',
      TitleBarComponentVariant.videoProcessing => 'Video processing',
      _ => '',
    };
  }

  double get _centerContentHorizontalPadding {
    return _trailingVisible
        ? leadingWidth > trailingWidth
              ? leadingWidth
              : trailingWidth
        : leadingWidth;
  }
}

class _TitleBarSlot extends StatelessWidget {
  const _TitleBarSlot({
    required this.width,
    required this.visible,
    required this.child,
    this.alignment = Alignment.center,
  });

  final double width;
  final bool visible;
  final Widget? child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Align(
        alignment: alignment,
        child: Visibility(
          visible: visible && child != null,
          maintainAnimation: true,
          maintainSize: true,
          maintainState: true,
          child: child ?? const SizedBox.square(dimension: 24),
        ),
      ),
    );
  }
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=11439-5036&m=dev
/// Section: Appbar/header / Header v2
/// Specs: Pinned sliver app bar that animates HeaderComponent between expanded
/// and collapsed states as the surrounding scroll view collapses it.
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
    return SliverPersistentHeader(
      pinned: true,
      delegate: _HeaderAppBarDelegate(
        title: title,
        subtitle: subtitle,
        leading: leading,
        backButton: backButton,
        onBack: onBack,
        actions: actions,
        expandedHeight: expandedHeight,
        collapsedHeight: collapsedHeight,
        horizontalPadding: horizontalPadding,
        topPadding: MediaQuery.paddingOf(context).top,
        backgroundColor: backgroundColor,
        showExpandedBackButton: showExpandedBackButton,
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
    final actionsOffsetY = _expandedActionsOffsetY * (1 - titleProgress);
    final titleLeft = lerpDouble(
      leading == null ? 0 : _expandedLeadingSize + Spacing.md,
      showExpandedBackButton ? _collapsedTitleLeft : 0,
      titleProgress,
    )!;
    final titleTop = lerpDouble(
      _expandedTitleTop,
      _collapsedTitleTop,
      titleProgress,
    )!;
    final titleRight = actions.isEmpty
        ? 0.0
        : _estimatedActionsWidth(actions.length) + Spacing.md;

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
                top: _expandedTitleTop,
                child: Opacity(
                  opacity: 1 - titleProgress,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox.square(
                      dimension: _expandedLeadingSize,
                      child: leading,
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
                top: _expandedTitleTop + 28,
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
              height: _pinnedHeaderChromeHeight,
              child: _PinnedHeaderChrome(
                backButton: backButton,
                onBack: onBack,
                actions: actions,
                actionsOffsetY: actionsOffsetY,
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
        oldDelegate.showExpandedBackButton != showExpandedBackButton;
  }
}

class _PinnedHeaderChrome extends StatelessWidget {
  const _PinnedHeaderChrome({
    required this.backButton,
    required this.onBack,
    required this.actions,
    required this.actionsOffsetY,
    required this.showBackButton,
  });

  final Widget? backButton;
  final VoidCallback? onBack;
  final List<Widget> actions;
  final double actionsOffsetY;
  final bool showBackButton;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _pinnedHeaderChromeHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (showBackButton) ...[
            _HeaderAppBarBackButton(backButton: backButton, onBack: onBack),
            const SizedBox(width: Spacing.md),
          ],
          const Expanded(child: SizedBox.shrink()),
          if (actions.isNotEmpty) ...[
            const SizedBox(width: Spacing.md),
            Transform.translate(
              offset: Offset(0, actionsOffsetY),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var index = 0; index < actions.length; index++) ...[
                    actions[index],
                    if (index != actions.length - 1) const SizedBox(width: 6),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeaderAppBarBackButton extends StatelessWidget {
  const _HeaderAppBarBackButton({
    required this.backButton,
    required this.onBack,
  });

  final Widget? backButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final tooltip = MaterialLocalizations.of(context).backButtonTooltip;

    if (backButton != null) {
      return IconTheme.merge(
        data: IconThemeData(color: colors.textBase, size: 24),
        child: backButton!,
      );
    }

    return SizedBox(
      width: _headerAppBarBackIconSize,
      height: _pinnedHeaderChromeHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Semantics(
          button: true,
          label: tooltip,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onBack ?? () => Navigator.maybePop(context),
            child: SizedBox.square(
              dimension: 24,
              child: Icon(Icons.arrow_back, color: colors.textBase, size: 24),
            ),
          ),
        ),
      ),
    );
  }
}

const _pinnedHeaderChromeHeight = 56.0;
const _headerAppBarBackIconSize = 24.0;
const _expandedActionsOffsetY =
    _expandedTitleTop -
    ((_pinnedHeaderChromeHeight - _estimatedActionWidth) / 2);
const _expandedLeadingSize = 36.0;
const _expandedTitleTop = 48.0;
const _collapsedTitleTop = 16.0;
const _collapsedTitleLeft = _headerAppBarBackIconSize + Spacing.md;
const _estimatedActionWidth = 38.0;

double _estimatedActionsWidth(int actionCount) {
  return (actionCount * _estimatedActionWidth) +
      ((actionCount - 1) * 6).clamp(0, double.infinity);
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
