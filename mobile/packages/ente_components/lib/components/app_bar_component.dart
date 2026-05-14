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
            child: Center(
              child: _centerContent(colors),
            ),
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
      TitleBarComponentVariant.videoProcessing =>
        true,
      _ => false,
    };
  }

  bool get _usesHeadingStyle {
    return switch (variant) {
      TitleBarComponentVariant.titleTopbar ||
      TitleBarComponentVariant.titleTopbarNoIcon ||
      TitleBarComponentVariant.onboardingTitle =>
        true,
      _ => false,
    };
  }

  bool get _titleVisible {
    return switch (variant) {
      TitleBarComponentVariant.back ||
      TitleBarComponentVariant.settings =>
        false,
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
      TitleBarComponentVariant.titleTopbarNoIcon =>
        true,
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

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2513-47854&m=dev
/// Section: Appbar/header / Title Bar
/// Specs: Compact mobile title bar with leading slot, centered title, and trailing actions.
class AppBarComponent extends StatelessWidget implements PreferredSizeWidget {
  const AppBarComponent({
    super.key,
    required this.title,
    this.leading,
    this.actions = const [],
    this.height = 56,
  });

  final String title;
  final Widget? leading;
  final List<Widget> actions;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: TitleBarComponent(
        variant: TitleBarComponentVariant.titleTopbar,
        title: title,
        height: height,
        leading: leading,
        trailingWidth: actions.isEmpty ? 44 : actions.length * 44,
        trailing: actions.isEmpty
            ? null
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (final action in actions) action,
                ],
              ),
      ),
    );
  }
}
