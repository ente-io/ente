import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

class TrailingWidget extends StatefulWidget {
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final Widget? trailingWidget;
  final bool trailingIconIsMuted;
  final double trailingExtraMargin;
  const TrailingWidget({
    this.trailingIcon,
    this.trailingIconColor,
    this.trailingWidget,
    required this.trailingIconIsMuted,
    required this.trailingExtraMargin,
    super.key,
  });
  @override
  State<TrailingWidget> createState() => _TrailingWidgetState();
}

class _TrailingWidgetState extends State<TrailingWidget> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    if (widget.trailingIcon != null) {
      return Padding(
        padding: EdgeInsets.only(
          right: widget.trailingExtraMargin,
        ),
        child: Icon(
          widget.trailingIcon,
          color: widget.trailingIconIsMuted
              ? colorScheme.strokeMuted
              : widget.trailingIconColor,
        ),
      );
    } else {
      return widget.trailingWidget ?? const SizedBox.shrink();
    }
  }
}

class ExpansionTrailingIcon extends StatelessWidget {
  final bool isExpanded;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  const ExpansionTrailingIcon({
    required this.isExpanded,
    this.trailingIcon,
    this.trailingIconColor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      opacity: isExpanded ? 0 : 1,
      child: AnimatedSwitcher(
        transitionBuilder: (child, animation) {
          return ScaleTransition(scale: animation, child: child);
        },
        duration: const Duration(milliseconds: 200),
        switchInCurve: Curves.easeOut,
        child: isExpanded
            ? const SizedBox.shrink()
            : Icon(
                trailingIcon,
                color: trailingIconColor,
              ),
      ),
    );
  }
}

class LeadingWidget extends StatelessWidget {
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  final Widget? leadingIconWidget;
  // leadIconSize deafult value is 20.
  final double leadingIconSize;
  const LeadingWidget({
    required this.leadingIconSize,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconWidget,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: SizedBox(
        height: leadingIconSize,
        width: leadingIconSize,
        child: leadingIcon == null
            ? (leadingIconWidget != null
                ? FittedBox(
                    fit: BoxFit.contain,
                    child: leadingIconWidget,
                  )
                : const SizedBox.shrink())
            : FittedBox(
                fit: BoxFit.contain,
                child: Icon(
                  leadingIcon,
                  color: leadingIconColor ??
                      getEnteColorScheme(context).strokeBase,
                ),
              ),
      ),
    );
  }
}
