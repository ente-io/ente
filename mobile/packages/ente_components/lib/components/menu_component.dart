import 'dart:async';

import 'package:ente_components/theme/colors.dart';
import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

const double _menuItemVerticalPadding = 9;
const double _leadingSlotSize = 36;
const double _trailingSlotSize = 36;

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=4055-18734&m=dev
/// Section: List items / Menu Item
/// Specs: 336px by typography-derived menu item, optional leading icon, subtitle, trailing item, hover and selected states.
class MenuComponent extends StatefulWidget {
  const MenuComponent({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.selected = false,
    this.onTap,
    this.gesturesEnabled = true,
    this.showOnlyLoadingState = false,
    this.surfaceExecutionStates = true,
    this.alwaysShowSuccessState = false,
    this.titleMaxLines = 2,
    this.subtitleMaxLines = 1,
    this.titleColor,
    this.iconColor,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final bool selected;
  final FutureOr<void> Function()? onTap;
  final bool gesturesEnabled;
  final bool showOnlyLoadingState;
  final bool surfaceExecutionStates;
  final bool alwaysShowSuccessState;
  final int titleMaxLines;
  final int subtitleMaxLines;
  final Color? titleColor;
  final Color? iconColor;

  @override
  State<MenuComponent> createState() => _MenuComponentState();
}

class _MenuComponentState extends State<MenuComponent> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isBusy = false;
  bool _showsLoading = false;
  bool _showsSuccess = false;
  Timer? _loadingTimer;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final enabled = _canHandleGestures;
    final trailing = _trailing(colors);
    return UnconstrainedBox(
      alignment: Alignment.topLeft,
      constrainedAxis: Axis.horizontal,
      child: Material(
        color: Colors.transparent,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: enabled ? (_) => _setHovered(true) : null,
          onExit: enabled ? (_) => _setHovered(false) : null,
          child: InkWell(
            onTap: enabled ? _handleTap : null,
            onHighlightChanged: enabled ? _setPressed : null,
            borderRadius: BorderRadius.circular(Radii.button),
            child: AnimatedContainer(
              key: const ValueKey('menu-item-surface'),
              duration: Motion.quick,
              decoration: BoxDecoration(
                color: _backgroundColor(colors, enabled),
                border: Border.all(
                  color: widget.selected
                      ? colors.primaryStroke
                      : Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(Radii.button),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: _minimumHeight(context)),
                child: Padding(
                  padding: EdgeInsets.only(
                    left: widget.leading == null ? Spacing.lg : Spacing.md,
                    right: Spacing.md,
                    top: _menuItemVerticalPadding,
                    bottom: _menuItemVerticalPadding,
                  ),
                  child: Row(
                    children: [
                      if (widget.leading != null) ...[
                        SizedBox.square(
                          dimension: _leadingSlotSize,
                          child: Center(
                            child: IconTheme.merge(
                              data: IconThemeData(
                                color: widget.iconColor ?? colors.textLight,
                                size: 18,
                              ),
                              child: widget.leading!,
                            ),
                          ),
                        ),
                        const SizedBox(width: Spacing.md),
                      ],
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              maxLines: widget.titleMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyles.body.copyWith(
                                color: widget.titleColor ?? colors.textBase,
                              ),
                            ),
                            if (widget.subtitle != null) ...[
                              const SizedBox(height: Spacing.xs),
                              Text(
                                widget.subtitle!,
                                maxLines: widget.subtitleMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyles.mini.copyWith(
                                  color: colors.textLight,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (trailing != null) ...[
                        const SizedBox(width: Spacing.md),
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            minWidth: _trailingSlotSize,
                            minHeight: _trailingSlotSize,
                          ),
                          child: Center(child: trailing),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  bool get _canHandleGestures {
    return widget.gesturesEnabled && widget.onTap != null && !_isBusy;
  }

  bool get _shouldSurfaceExecutionState {
    return widget.surfaceExecutionStates ||
        widget.showOnlyLoadingState ||
        widget.alwaysShowSuccessState;
  }

  Color _backgroundColor(ColorTokens colors, bool enabled) {
    if (_isPressed) {
      return colors.fillDarker;
    }
    if (_isHovered && enabled) {
      return colors.fillDark;
    }
    return colors.fillLight;
  }

  Widget? _trailing(ColorTokens colors) {
    if (_showsLoading && _shouldSurfaceExecutionState) {
      return SizedBox.square(
        key: const ValueKey('menu-item-loading'),
        dimension: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(colors.textLight),
        ),
      );
    }
    if (_showsSuccess &&
        _shouldSurfaceExecutionState &&
        !widget.showOnlyLoadingState) {
      return Icon(
        key: const ValueKey('menu-item-success'),
        Icons.check_rounded,
        color: colors.primary,
        size: 18,
      );
    }
    return widget.trailing;
  }

  double _minimumHeight(BuildContext context) {
    final textHeight = _scaledLineHeight(context, TextStyles.body) +
        Spacing.xs +
        _scaledLineHeight(context, TextStyles.mini);
    final contentHeight =
        textHeight > _leadingSlotSize ? textHeight : _leadingSlotSize;
    return contentHeight + (_menuItemVerticalPadding * 2);
  }

  double _scaledLineHeight(BuildContext context, TextStyle style) {
    final fontSize =
        style.fontSize ?? DefaultTextStyle.of(context).style.fontSize ?? 14;
    final height = style.height ?? 1;
    return MediaQuery.textScalerOf(context).scale(fontSize) * height;
  }

  void _setHovered(bool value) {
    if (_isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (_isPressed == value) {
      return;
    }
    setState(() => _isPressed = value);
  }

  Future<void> _handleTap() async {
    if (!_canHandleGestures) {
      return;
    }

    _isBusy = true;
    var loadingWasShown = false;
    _loadingTimer = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || !_isBusy) {
        return;
      }
      loadingWasShown = true;
      setState(() => _showsLoading = true);
    });

    try {
      await widget.onTap?.call();
      _loadingTimer?.cancel();
      if (!mounted) {
        return;
      }

      if (widget.alwaysShowSuccessState) {
        await _showSuccessThenReset();
        return;
      }

      if (widget.showOnlyLoadingState) {
        _resetExecutionState();
        return;
      }

      if (widget.surfaceExecutionStates && loadingWasShown) {
        await _showSuccessThenReset();
        return;
      }

      _resetExecutionState();
    } catch (_) {
      _loadingTimer?.cancel();
      if (mounted) {
        _resetExecutionState();
      }
    }
  }

  Future<void> _showSuccessThenReset() async {
    if (!mounted) {
      return;
    }
    setState(() {
      _showsLoading = false;
      _showsSuccess = true;
    });
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      _resetExecutionState();
    }
  }

  void _resetExecutionState() {
    _loadingTimer?.cancel();
    setState(() {
      _isBusy = false;
      _isPressed = false;
      _showsLoading = false;
      _showsSuccess = false;
    });
  }
}
