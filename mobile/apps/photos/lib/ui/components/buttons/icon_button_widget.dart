import 'package:flutter/material.dart';
import 'package:photos/theme/colors.dart';
import 'package:photos/theme/ente_theme.dart';

enum IconButtonType {
  primary,
  secondary,
  rounded,
}

class IconButtonWidget extends StatefulWidget {
  final IconButtonType iconButtonType;
  final IconData icon;
  final bool disableGestureDetector;
  final VoidCallback? onTap;
  final Color? defaultColor;
  final Color? pressedColor;
  final Color? iconColor;
  final double size;
  final bool roundedIcon;
  const IconButtonWidget({
    required this.icon,
    required this.iconButtonType,
    this.disableGestureDetector = false,
    this.onTap,
    this.defaultColor,
    this.pressedColor,
    this.iconColor,
    this.size = 24,
    this.roundedIcon = true,
    super.key,
  });

  @override
  State<IconButtonWidget> createState() => _IconButtonWidgetState();
}

class _IconButtonWidgetState extends State<IconButtonWidget> {
  Color? iconStateColor;
  @override
  void didUpdateWidget(IconButtonWidget oldWidget) {
    if (oldWidget.icon != widget.icon && mounted) {
      setState(() {
        iconStateColor = null;
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPressedState = widget.onTap != null;
    final colorTheme = getEnteColorScheme(context);
    iconStateColor ??
        (iconStateColor = widget.defaultColor ??
            (widget.iconButtonType == IconButtonType.rounded
                ? colorTheme.fillFaint
                : null));
    return widget.disableGestureDetector
        ? _iconButton(colorTheme)
        : GestureDetector(
            onTapDown: hasPressedState ? _onTapDown : null,
            onTapUp: hasPressedState ? _onTapUp : null,
            onTapCancel: hasPressedState ? _onTapCancel : null,
            onTap: widget.onTap,
            child: _iconButton(colorTheme),
          );
  }

  Widget _iconButton(EnteColorScheme colorTheme) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: widget.roundedIcon
          ? AnimatedContainer(
              duration: const Duration(milliseconds: 20),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(widget.size),
                color: iconStateColor,
              ),
              child: Icon(
                widget.icon,
                color: widget.iconColor ??
                    (widget.iconButtonType == IconButtonType.secondary
                        ? colorTheme.strokeMuted
                        : colorTheme.strokeBase),
                size: widget.size,
              ),
            )
          : Icon(
              widget.icon,
              color: widget.iconColor ??
                  (widget.iconButtonType == IconButtonType.secondary
                      ? colorTheme.strokeMuted
                      : colorTheme.strokeBase),
              size: widget.size,
            ),
    );
  }

  _onTapDown(details) {
    final colorTheme = getEnteColorScheme(context);
    setState(() {
      iconStateColor = widget.pressedColor ??
          (widget.iconButtonType == IconButtonType.rounded
              ? colorTheme.fillMuted
              : colorTheme.fillFaint);
    });
  }

  _onTapUp(details) {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          iconStateColor = null;
        });
      }
    });
  }

  _onTapCancel() {
    setState(() {
      iconStateColor = null;
    });
  }
}
