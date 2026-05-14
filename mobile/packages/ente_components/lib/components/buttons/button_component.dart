import 'dart:async';

import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hugeicons/hugeicons.dart';

enum ButtonComponentVariant {
  primary,
  secondary,
  neutral,
  critical,
  tertiaryCritical,
  link,
}

enum ButtonComponentSize {
  small,
  large,
}

enum _ButtonVisualState {
  normal,
  hover,
  pressed,
}

enum _ButtonExecutionState {
  idle,
  inProgress,
  successful,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2207-41578&m=dev
/// Section: Buttons / Button Small
/// Specs: 52px height, 20px radius, 24px horizontal padding, 8px icon gap.
/// States: default, hover, pressed, disabled, loading, success.
class ButtonComponent extends StatefulWidget {
  const ButtonComponent({
    super.key,
    required this.label,
    this.onTap,
    this.variant = ButtonComponentVariant.primary,
    this.size = ButtonComponentSize.small,
    this.leading,
    this.trailing,
    this.isDisabled = false,
    this.shouldSurfaceExecutionStates = true,
    this.shouldShowSuccessConfirmation = false,
    this.progressStatus,
    this.iconColor,
    this.width,
  });

  final String label;
  final FutureOr<void> Function()? onTap;
  final ButtonComponentVariant variant;
  final ButtonComponentSize size;
  final Widget? leading;
  final Widget? trailing;
  final bool isDisabled;
  final bool shouldSurfaceExecutionStates;
  final bool shouldShowSuccessConfirmation;
  final ValueListenable<String>? progressStatus;
  final Color? iconColor;
  final double? width;

  @override
  State<ButtonComponent> createState() => _ButtonComponentState();
}

class _ButtonComponentState extends State<ButtonComponent>
    with SingleTickerProviderStateMixin {
  static const double _executionIconSize = 24;
  static const double _contentMinHeight = 24;
  static const double _verticalPadding = 14;
  static const Duration _loadingDelay = Duration(milliseconds: 300);
  static const Duration _successDisplayDuration = Duration(seconds: 2);
  static const Duration _minimumPressDuration = Duration(milliseconds: 120);

  late final AnimationController _loadingController;
  bool _isHovered = false;
  bool _isPressed = false;
  int _pressToken = 0;
  DateTime? _tapDownTime;
  double? _idleWidth;
  Timer? _loadingTimer;
  Timer? _successResetTimer;
  Timer? _pressReleaseTimer;
  _ButtonExecutionState _executionState = _ButtonExecutionState.idle;
  bool _loadingVisible = false;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _syncLoadingController();
  }

  @override
  void didUpdateWidget(covariant ButtonComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    final idleContentChanged = widget.variant != oldWidget.variant ||
        widget.label != oldWidget.label ||
        widget.leading != oldWidget.leading ||
        widget.trailing != oldWidget.trailing;
    if (widget.size != oldWidget.size ||
        (widget.size == ButtonComponentSize.small && idleContentChanged)) {
      _idleWidth = null;
    }
    if (widget.isDisabled && !oldWidget.isDisabled) {
      _isPressed = false;
    }
    _syncLoadingController();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _successResetTimer?.cancel();
    _pressReleaseTimer?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isInlineLink = widget.variant == ButtonComponentVariant.link &&
        widget.size == ButtonComponentSize.small;
    final resolvedColors = _colors(context);
    final enabled = _canHandleGestures;
    final verticalPadding = isInlineLink ? Spacing.xs : _buttonVerticalPadding;
    _captureIdleWidth();

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _handleTap : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _releasePressed() : null,
        onTapCancel: enabled ? _releasePressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: Motion.standard,
            curve: Curves.easeInOutCubic,
            width: widget.width ??
                (widget.size == ButtonComponentSize.large
                    ? double.infinity
                    : _executionWidth),
            decoration: BoxDecoration(
              color: resolvedColors.background,
              borderRadius:
                  BorderRadius.circular(isInlineLink ? 0 : Radii.button),
              border: resolvedColors.border == null
                  ? null
                  : Border.all(color: resolvedColors.border!),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isInlineLink ? 0 : Spacing.xl,
                vertical: verticalPadding,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: isInlineLink ? 0 : _contentMinHeight,
                ),
                child: AnimatedSwitcher(
                  duration: Motion.quick,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                        child: child,
                      ),
                    );
                  },
                  child: _content(context, resolvedColors.foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  _ButtonVisualState get _effectiveVisualState {
    if (_isPressed) return _ButtonVisualState.pressed;
    if (_isHovered) return _ButtonVisualState.hover;
    return _ButtonVisualState.normal;
  }

  void _setHovered(bool value) {
    if (!_canHandleGestures || _isHovered == value) {
      return;
    }
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (!_canHandleGestures || _isPressed == value) {
      return;
    }
    if (value) {
      _pressToken++;
      _tapDownTime = DateTime.now();
      setState(() => _isPressed = true);
      return;
    }
    _releasePressed();
  }

  void _releasePressed() {
    final token = _pressToken;
    final tapDownTime = _tapDownTime;
    if (tapDownTime == null) {
      if (mounted) setState(() => _isPressed = false);
      return;
    }

    final elapsed = DateTime.now().difference(tapDownTime);
    final remaining = _minimumPressDuration - elapsed;

    void release() {
      if (!mounted || token != _pressToken) return;
      setState(() => _isPressed = false);
    }

    if (remaining <= Duration.zero) {
      release();
    } else {
      _pressReleaseTimer?.cancel();
      _pressReleaseTimer = Timer(remaining, release);
    }
    _tapDownTime = null;
  }

  Widget _content(BuildContext context, Color foreground) {
    if (_showLoading) {
      final spinner = SizedBox(
        width: _executionIconSize,
        height: _executionIconSize,
        child: Center(
          child: RotationTransition(
            turns: _loadingController,
            child: HugeIcon(
              icon: HugeIcons.strokeRoundedLoading03,
              color: _iconForeground(foreground),
              size: _executionIconSize,
            ),
          ),
        ),
      );
      if (widget.progressStatus == null) {
        return KeyedSubtree(
          key: const ValueKey('loading'),
          child: spinner,
        );
      }
      return Row(
        key: const ValueKey('loading'),
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<String>(
            valueListenable: widget.progressStatus!,
            builder: (context, value, _) {
              if (value.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: Text(
                  value,
                  style: TextStyles.mini.copyWith(color: foreground),
                ),
              );
            },
          ),
          spinner,
        ],
      );
    }
    if (_showSuccess) {
      return HugeIcon(
        key: const ValueKey('success'),
        icon: HugeIcons.strokeRoundedTick02,
        size: _executionIconSize,
        color: _iconForeground(foreground),
      );
    }

    final underlined = widget.variant == ButtonComponentVariant.link ||
        widget.variant == ButtonComponentVariant.tertiaryCritical;
    final label = Text(
      widget.label,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
      style: TextStyles.bodyBold.copyWith(
        color: foreground,
        decoration: underlined ? TextDecoration.underline : null,
        decorationColor: underlined ? foreground : null,
      ),
    );
    final children = <Widget>[
      if (widget.leading != null) ...[
        IconTheme.merge(
          data: IconThemeData(size: 20, color: _iconForeground(foreground)),
          child: widget.leading!,
        ),
        const SizedBox(width: Spacing.sm),
      ],
      if (widget.size == ButtonComponentSize.large)
        Flexible(child: label)
      else
        label,
      if (widget.trailing != null) ...[
        const SizedBox(width: Spacing.md),
        IconTheme.merge(
          data: IconThemeData(size: 20, color: _iconForeground(foreground)),
          child: widget.trailing!,
        ),
      ],
    ];

    return Row(
      key: const ValueKey('content'),
      mainAxisSize: widget.size == ButtonComponentSize.large
          ? MainAxisSize.max
          : MainAxisSize.min,
      mainAxisAlignment: widget.trailing == null
          ? MainAxisAlignment.center
          : MainAxisAlignment.spaceBetween,
      children: children,
    );
  }

  Color _iconForeground(Color foreground) => widget.iconColor ?? foreground;

  double get _buttonVerticalPadding {
    return _verticalPadding;
  }

  _ResolvedButtonColors _colors(BuildContext context) {
    if (widget.isDisabled || widget.onTap == null) {
      return _ResolvedButtonColors(
        background: _disabledBackground(context),
        foreground: context.componentColors.textLighter,
        border: null,
      );
    }

    final visualState =
        _showLoading ? _ButtonVisualState.pressed : _effectiveVisualState;
    return _ResolvedButtonColors(
      background: switch (visualState) {
        _ButtonVisualState.pressed when !_showSuccess =>
          _pressedBackground(context),
        _ButtonVisualState.hover when !_showSuccess =>
          _hoverBackground(context),
        _ => _background(context),
      },
      foreground: _foreground(context, visualState),
      border: _borderColor(),
    );
  }

  void _syncLoadingController() {
    if (_showLoading) {
      if (!_loadingController.isAnimating) {
        _loadingController.repeat();
      }
      return;
    }

    if (_loadingController.isAnimating || _loadingController.value != 0) {
      _loadingController.stop();
      _loadingController.reset();
    }
  }

  bool get _canHandleGestures =>
      !widget.isDisabled &&
      widget.onTap != null &&
      _executionState == _ButtonExecutionState.idle;

  bool get _showLoading =>
      widget.shouldSurfaceExecutionStates &&
      _executionState == _ButtonExecutionState.inProgress &&
      _loadingVisible;

  bool get _showSuccess =>
      widget.shouldSurfaceExecutionStates &&
      _executionState == _ButtonExecutionState.successful;

  double? get _executionWidth {
    if (widget.size != ButtonComponentSize.small ||
        (!_showLoading && !_showSuccess)) {
      return null;
    }
    return _idleWidth;
  }

  Future<void> _handleTap() async {
    final callback = widget.onTap;
    if (callback == null) return;

    _successResetTimer?.cancel();
    var loadingSurfaced = false;
    _loadingTimer?.cancel();
    setState(() {
      _executionState = _ButtonExecutionState.inProgress;
      _loadingVisible = false;
    });
    _loadingTimer = Timer(_loadingDelay, () {
      if (!mounted) return;
      loadingSurfaced = true;
      setState(() {
        _loadingVisible = true;
        _isPressed = false;
      });
      _syncLoadingController();
    });

    try {
      await Future.sync(callback);
      if (!mounted) return;

      final loadingPending = _loadingTimer?.isActive ?? false;
      _loadingTimer?.cancel();
      _loadingTimer = null;

      final shouldShowSuccess = widget.shouldSurfaceExecutionStates &&
          (loadingSurfaced ||
              (loadingPending && widget.shouldShowSuccessConfirmation));

      if (shouldShowSuccess) {
        _showSuccessForDuration();
      } else {
        setState(() {
          _executionState = _ButtonExecutionState.idle;
          _loadingVisible = false;
          _isPressed = false;
        });
        _syncLoadingController();
      }
    } catch (_) {
      _loadingTimer?.cancel();
      _loadingTimer = null;
      if (!mounted) return;
      setState(() {
        _executionState = _ButtonExecutionState.idle;
        _loadingVisible = false;
        _isPressed = false;
      });
      _syncLoadingController();
    }
  }

  void _showSuccessForDuration() {
    setState(() {
      _executionState = _ButtonExecutionState.successful;
      _loadingVisible = false;
      _isPressed = false;
    });
    _syncLoadingController();
    _successResetTimer?.cancel();
    _successResetTimer = Timer(_successDisplayDuration, () {
      if (!mounted) return;
      setState(() {
        _executionState = _ButtonExecutionState.idle;
        _loadingVisible = false;
      });
      _syncLoadingController();
    });
  }

  void _captureIdleWidth() {
    if (widget.size != ButtonComponentSize.small ||
        _showLoading ||
        _showSuccess) {
      return;
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted || widget.size != ButtonComponentSize.small) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return;
      final width = box.size.width;
      if (_idleWidth != null && (_idleWidth! - width).abs() < 0.5) return;
      setState(() => _idleWidth = width);
    });
  }

  Color _background(BuildContext context) {
    final colors = context.componentColors;
    return switch (widget.variant) {
      ButtonComponentVariant.primary => colors.primary,
      ButtonComponentVariant.secondary
          when widget.size == ButtonComponentSize.large =>
        colors.primaryLight,
      ButtonComponentVariant.secondary => colors.fillDark,
      ButtonComponentVariant.neutral => colors.fillBase,
      ButtonComponentVariant.critical => colors.warning,
      ButtonComponentVariant.tertiaryCritical => Colors.transparent,
      ButtonComponentVariant.link => Colors.transparent,
    };
  }

  Color _hoverBackground(BuildContext context) {
    final colors = context.componentColors;
    return switch (widget.variant) {
      ButtonComponentVariant.primary => colors.primaryDark,
      ButtonComponentVariant.secondary => colors.fillDarker,
      ButtonComponentVariant.neutral => colors.fillBase,
      ButtonComponentVariant.critical => colors.warningDark,
      ButtonComponentVariant.tertiaryCritical => Colors.transparent,
      ButtonComponentVariant.link => Colors.transparent,
    };
  }

  Color _pressedBackground(BuildContext context) {
    final colors = context.componentColors;
    return switch (widget.variant) {
      ButtonComponentVariant.primary => colors.primaryDarker,
      ButtonComponentVariant.secondary => colors.fillDarkest,
      ButtonComponentVariant.neutral => colors.fillBase,
      ButtonComponentVariant.critical => colors.warningDarker,
      ButtonComponentVariant.tertiaryCritical => Colors.transparent,
      ButtonComponentVariant.link => Colors.transparent,
    };
  }

  Color _disabledBackground(BuildContext context) {
    final colors = context.componentColors;
    return switch (widget.variant) {
      ButtonComponentVariant.tertiaryCritical => Colors.transparent,
      ButtonComponentVariant.link => Colors.transparent,
      _ => colors.fillDark,
    };
  }

  Color _foreground(BuildContext context, _ButtonVisualState visualState) {
    final colors = context.componentColors;
    return switch (widget.variant) {
      ButtonComponentVariant.primary => colors.specialWhite,
      ButtonComponentVariant.secondary
          when widget.size == ButtonComponentSize.large =>
        switch (visualState) {
          _ButtonVisualState.normal => colors.primary,
          _ => colors.textBase,
        },
      ButtonComponentVariant.secondary => colors.textBase,
      ButtonComponentVariant.neutral => colors.textReverse,
      ButtonComponentVariant.critical => colors.specialWhite,
      ButtonComponentVariant.tertiaryCritical => switch (visualState) {
          _ButtonVisualState.pressed => colors.warningDarker,
          _ButtonVisualState.hover => colors.warningDark,
          _ButtonVisualState.normal => colors.warning,
        },
      ButtonComponentVariant.link => switch (visualState) {
          _ButtonVisualState.pressed => colors.primaryDarker,
          _ButtonVisualState.hover => colors.primaryDark,
          _ButtonVisualState.normal => colors.primary,
        },
    };
  }

  Color? _borderColor() {
    return null;
  }
}

class _ResolvedButtonColors {
  const _ResolvedButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color? border;
}
