import 'dart:async';

import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

enum IconButtonComponentVariant {
  primary,
  critical,
  unfilled,
  secondary,
  green,
  circular,
}

enum IconButtonComponentState { normal, hover, pressed }

enum _ResolvedIconButtonState {
  normal,
  hover,
  pressed,
  disabled,
  loading,
  success,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2207-42075&m=dev
/// Section: Buttons / Icon Button
/// Specs: 36px square, compact icon affordance with default, hover, pressed,
/// disabled, loading, and success states.
class IconButtonComponent extends StatefulWidget {
  const IconButtonComponent({
    super.key,
    required this.icon,
    required this.onTap,
    this.variant = IconButtonComponentVariant.secondary,
    this.state,
    this.isLoading = false,
    this.isSuccess = false,
    this.shouldSurfaceExecutionStates = true,
    this.shouldShowSuccessConfirmation = false,
    this.tooltip,
  });

  final Widget icon;
  final FutureOr<void> Function()? onTap;
  final IconButtonComponentVariant variant;
  final IconButtonComponentState? state;
  final bool isLoading;
  final bool isSuccess;
  final bool shouldSurfaceExecutionStates;
  final bool shouldShowSuccessConfirmation;
  final String? tooltip;

  @override
  State<IconButtonComponent> createState() => _IconButtonComponentState();
}

class _IconButtonComponentState extends State<IconButtonComponent>
    with SingleTickerProviderStateMixin {
  static const Duration _loadingDelay = Duration(milliseconds: 300);
  static const Duration _successDisplayDuration = Duration(seconds: 2);

  late final AnimationController _loadingController;
  bool _isHovered = false;
  bool _isPressed = false;
  int _executionToken = 0;
  Timer? _loadingTimer;
  Timer? _successResetTimer;
  bool _isExecuting = false;
  bool _isSuccessful = false;
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
  void didUpdateWidget(covariant IconButtonComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_parentControlsExecutionState) {
      _resetInternalExecutionState();
    }
    _syncLoadingController();
  }

  @override
  void dispose() {
    _loadingTimer?.cancel();
    _successResetTimer?.cancel();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = _canHandleGestures;
    final visualState = _visualState;
    final foreground = _foreground(context, visualState);
    final background = _background(context, visualState);
    final radius = widget.variant == IconButtonComponentVariant.circular
        ? BorderRadius.circular(35)
        : BorderRadius.circular(Radii.md);

    Widget button = SizedBox(
      width: _buttonSize,
      height: _buttonSize,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => _setHovered(true),
        onExit: (_) => _setHovered(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? _handleTap : null,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedScale(
            scale: enabled && _isPressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              key: const ValueKey('icon-button-surface'),
              duration: Motion.quick,
              curve: Curves.easeInOutCubic,
              width: _buttonSize,
              height: _buttonSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: background,
                borderRadius: radius,
              ),
              child: Padding(
                padding: const EdgeInsets.all(Spacing.sm),
                child: AnimatedSwitcher(
                  duration: Motion.quick,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: _content(foreground),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.tooltip,
      child: button,
    );
  }

  _ResolvedIconButtonState get _visualState {
    if (_showLoading) {
      return _ResolvedIconButtonState.loading;
    }
    if (_showSuccess) {
      return _ResolvedIconButtonState.success;
    }
    if (widget.onTap == null) {
      return _ResolvedIconButtonState.disabled;
    }

    final forcedState = widget.state;
    if (forcedState != null) {
      return switch (forcedState) {
        IconButtonComponentState.normal => _ResolvedIconButtonState.normal,
        IconButtonComponentState.hover => _ResolvedIconButtonState.hover,
        IconButtonComponentState.pressed => _ResolvedIconButtonState.pressed,
      };
    }

    if (_isPressed) {
      return _ResolvedIconButtonState.pressed;
    }
    if (_isHovered) {
      return _ResolvedIconButtonState.hover;
    }
    return _ResolvedIconButtonState.normal;
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
    setState(() => _isPressed = value);
  }

  Widget _content(Color foreground) {
    if (_showLoading) {
      return RotationTransition(
        key: const ValueKey('loading'),
        turns: _loadingController,
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedLoading03,
          size: _iconSize,
          color: foreground,
        ),
      );
    }
    if (_showSuccess) {
      return HugeIcon(
        key: const ValueKey('success'),
        icon: HugeIcons.strokeRoundedTick02,
        size: _iconSize,
        color: foreground,
      );
    }
    return IconTheme.merge(
      key: const ValueKey('icon'),
      data: IconThemeData(size: _iconSize, color: foreground),
      child: widget.icon,
    );
  }

  bool get _canHandleGestures {
    return widget.onTap != null &&
        !widget.isLoading &&
        !widget.isSuccess &&
        !_isExecuting &&
        !_isSuccessful;
  }

  bool get _showLoading {
    return widget.isLoading ||
        (widget.shouldSurfaceExecutionStates &&
            _isExecuting &&
            _loadingVisible);
  }

  bool get _showSuccess {
    return widget.isSuccess ||
        (widget.shouldSurfaceExecutionStates && _isSuccessful);
  }

  bool get _parentControlsExecutionState {
    return widget.onTap == null || widget.isLoading || widget.isSuccess;
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

  void _resetInternalExecutionState() {
    _executionToken++;
    _cancelLoadingTimer();
    _successResetTimer?.cancel();
    _successResetTimer = null;
    _isExecuting = false;
    _isSuccessful = false;
    _loadingVisible = false;
    _isPressed = false;
  }

  Future<void> _handleTap() async {
    final callback = widget.onTap;
    if (callback == null) return;

    final executionToken = _beginExecution();

    try {
      await Future.sync(callback);
      if (!mounted || !_isCurrentExecution(executionToken)) {
        return;
      }

      final loadingPending = _loadingTimer?.isActive ?? false;
      final shouldShowSuccess =
          widget.shouldSurfaceExecutionStates &&
          (_loadingVisible ||
              (loadingPending && widget.shouldShowSuccessConfirmation));

      _cancelLoadingTimer();

      if (shouldShowSuccess) {
        _showSuccessForDuration();
      } else {
        _clearExecutionState();
      }
    } catch (_) {
      if (!mounted || !_isCurrentExecution(executionToken)) {
        return;
      }
      _cancelLoadingTimer();
      _clearExecutionState();
    }
  }

  int _beginExecution() {
    _successResetTimer?.cancel();
    _successResetTimer = null;
    _cancelLoadingTimer();
    final executionToken = ++_executionToken;
    setState(() {
      _isExecuting = true;
      _isSuccessful = false;
      _loadingVisible = false;
      _isPressed = false;
    });
    _loadingTimer = Timer(_loadingDelay, () {
      if (!mounted || executionToken != _executionToken) return;
      setState(() {
        _loadingVisible = true;
        _isPressed = false;
      });
      _syncLoadingController();
    });
    return executionToken;
  }

  bool _isCurrentExecution(int executionToken) {
    return executionToken == _executionToken && !_parentControlsExecutionState;
  }

  void _cancelLoadingTimer() {
    _loadingTimer?.cancel();
    _loadingTimer = null;
  }

  void _clearExecutionState() {
    setState(() {
      _isExecuting = false;
      _isSuccessful = false;
      _loadingVisible = false;
      _isPressed = false;
    });
    _syncLoadingController();
  }

  void _showSuccessForDuration() {
    setState(() {
      _isExecuting = false;
      _isSuccessful = true;
      _loadingVisible = false;
      _isPressed = false;
    });
    _syncLoadingController();
    _successResetTimer?.cancel();
    _successResetTimer = Timer(_successDisplayDuration, () {
      if (!mounted) return;
      setState(() {
        _isSuccessful = false;
        _loadingVisible = false;
      });
      _syncLoadingController();
    });
  }

  Color _background(BuildContext context, _ResolvedIconButtonState state) {
    final colors = context.componentColors;
    final transparent = colors.specialScrim.withAlpha(0);

    return switch (widget.variant) {
      IconButtonComponentVariant.unfilled ||
      IconButtonComponentVariant.secondary => transparent,
      IconButtonComponentVariant.primary => switch (state) {
        _ResolvedIconButtonState.normal => colors.fillLight,
        _ResolvedIconButtonState.hover ||
        _ResolvedIconButtonState.disabled ||
        _ResolvedIconButtonState.loading ||
        _ResolvedIconButtonState.success => colors.fillDark,
        _ResolvedIconButtonState.pressed => colors.fillDarker,
      },
      IconButtonComponentVariant.critical => switch (state) {
        _ResolvedIconButtonState.hover => colors.fillDarker,
        _ResolvedIconButtonState.pressed => colors.fillDarkest,
        _ => colors.fillDark,
      },
      IconButtonComponentVariant.green => switch (state) {
        _ResolvedIconButtonState.hover => colors.primaryDark,
        _ResolvedIconButtonState.pressed => colors.primaryDarker,
        _ResolvedIconButtonState.disabled => colors.fillDark,
        _ => colors.primary,
      },
      IconButtonComponentVariant.circular => switch (state) {
        _ResolvedIconButtonState.hover ||
        _ResolvedIconButtonState.disabled => colors.fillDark,
        _ResolvedIconButtonState.pressed => colors.fillDarker,
        _ => colors.fillLight,
      },
    };
  }

  Color _foreground(BuildContext context, _ResolvedIconButtonState state) {
    final colors = context.componentColors;
    if (state == _ResolvedIconButtonState.success &&
        widget.variant != IconButtonComponentVariant.green) {
      return colors.primary;
    }
    if (widget.variant == IconButtonComponentVariant.green &&
        state != _ResolvedIconButtonState.disabled) {
      return colors.specialWhite;
    }
    if (widget.variant == IconButtonComponentVariant.unfilled ||
        widget.variant == IconButtonComponentVariant.secondary) {
      return colors.iconColor;
    }
    return colors.textBase;
  }
}

const double _buttonSize = 36;
const double _iconSize = 18;
