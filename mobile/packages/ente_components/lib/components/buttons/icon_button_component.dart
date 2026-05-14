import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

enum IconButtonComponentVariant {
  primary,
  critical,
  unfilled,
  secondary,
  green,
  circular,
}

enum IconButtonComponentState {
  normal,
  hover,
  pressed,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2207-42075&m=dev
/// Section: Buttons / Icon Button
/// Specs: 38px square, compact icon affordance with default, hover, pressed, disabled, loading, success states.
class IconButtonComponent extends StatefulWidget {
  const IconButtonComponent({
    super.key,
    required this.icon,
    required this.onPressed,
    this.variant = IconButtonComponentVariant.secondary,
    this.state,
    this.isLoading = false,
    this.isSuccess = false,
    this.tooltip,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final IconButtonComponentVariant variant;
  final IconButtonComponentState? state;
  final bool isLoading;
  final bool isSuccess;
  final String? tooltip;

  @override
  State<IconButtonComponent> createState() => _IconButtonComponentState();
}

class _IconButtonComponentState extends State<IconButtonComponent> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled =
        widget.onPressed != null && !widget.isLoading && !widget.isSuccess;
    final visualState = _visualState(enabled);
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
        onEnter: enabled ? (_) => _setHovered(true) : null,
        onExit: enabled ? (_) => _setHovered(false) : null,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? widget.onPressed : null,
          onTapDown: enabled ? (_) => _setPressed(true) : null,
          onTapUp: enabled ? (_) => _setPressed(false) : null,
          onTapCancel: enabled ? () => _setPressed(false) : null,
          child: AnimatedContainer(
            key: const ValueKey('icon-button-surface'),
            duration: Motion.quick,
            curve: Curves.easeInOutCubic,
            width: _buttonSize,
            height: _buttonSize,
            padding: EdgeInsets.all(_outerPadding(visualState)),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: background,
              borderRadius: radius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: AnimatedSwitcher(
                duration: Motion.quick,
                child: _content(context, foreground),
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

  _ResolvedIconButtonState _visualState(bool enabled) {
    if (widget.isLoading) {
      return _ResolvedIconButtonState.loading;
    }
    if (widget.isSuccess) {
      return _ResolvedIconButtonState.success;
    }
    if (!enabled) {
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
    if (widget.onPressed == null || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (widget.onPressed == null || _isPressed == value) return;
    setState(() => _isPressed = value);
  }

  Widget _content(BuildContext context, Color foreground) {
    if (widget.isLoading) {
      return SizedBox(
        key: const ValueKey('loading'),
        width: _iconSize,
        height: _iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(foreground),
        ),
      );
    }
    if (widget.isSuccess) {
      return Icon(
        key: const ValueKey('success'),
        Icons.check_circle_rounded,
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

  double _outerPadding(_ResolvedIconButtonState state) {
    return switch (widget.variant) {
      IconButtonComponentVariant.unfilled ||
      IconButtonComponentVariant.secondary =>
        0,
      _ => Spacing.xxs,
    };
  }

  Color _background(BuildContext context, _ResolvedIconButtonState state) {
    final colors = context.componentColors;
    final transparent = colors.specialScrim.withAlpha(0);

    return switch (widget.variant) {
      IconButtonComponentVariant.unfilled ||
      IconButtonComponentVariant.secondary =>
        transparent,
      IconButtonComponentVariant.primary => switch (state) {
          _ResolvedIconButtonState.normal => colors.fillLight,
          _ResolvedIconButtonState.hover ||
          _ResolvedIconButtonState.disabled ||
          _ResolvedIconButtonState.loading ||
          _ResolvedIconButtonState.success =>
            colors.fillDark,
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
          _ResolvedIconButtonState.disabled =>
            colors.fillDark,
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

const double _buttonSize = 38;
const double _iconSize = 18;

enum _ResolvedIconButtonState {
  normal,
  hover,
  pressed,
  disabled,
  loading,
  success,
}
