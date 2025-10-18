import 'package:ente_ui/components/loading_widget.dart';
import 'package:ente_ui/models/execution_states.dart';
import 'package:ente_ui/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class TrailingWidget extends StatefulWidget {
  final ValueNotifier executionStateNotifier;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final Widget? trailingWidget;
  final bool trailingIconIsMuted;
  final double trailingExtraMargin;
  final bool showExecutionStates;
  const TrailingWidget({
    super.key,
    required this.executionStateNotifier,
    this.trailingIcon,
    this.trailingIconColor,
    this.trailingWidget,
    required this.trailingIconIsMuted,
    required this.trailingExtraMargin,
    required this.showExecutionStates,
  });
  @override
  State<TrailingWidget> createState() => _TrailingWidgetState();
}

class _TrailingWidgetState extends State<TrailingWidget> {
  Widget? trailingWidget;
  @override
  void initState() {
    widget.showExecutionStates
        ? widget.executionStateNotifier.addListener(_executionStateListener)
        : null;
    super.initState();
  }

  @override
  void dispose() {
    widget.executionStateNotifier.removeListener(_executionStateListener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (trailingWidget == null || !widget.showExecutionStates) {
      _setTrailingIcon();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 175),
      switchInCurve: Curves.easeInExpo,
      switchOutCurve: Curves.easeOutExpo,
      child: trailingWidget,
    );
  }

  void _executionStateListener() {
    final colorScheme = getEnteColorScheme(context);
    setState(() {
      if (widget.executionStateNotifier.value == ExecutionState.idle) {
        _setTrailingIcon();
      } else if (widget.executionStateNotifier.value ==
          ExecutionState.inProgress) {
        trailingWidget = EnteLoadingWidget(
          color: colorScheme.strokeMuted,
        );
      } else if (widget.executionStateNotifier.value ==
          ExecutionState.successful) {
        trailingWidget = Icon(
          Icons.check_outlined,
          size: 22,
          color: colorScheme.primary500,
        );
      } else {
        trailingWidget = const SizedBox.shrink();
      }
    });
  }

  void _setTrailingIcon() {
    if (widget.trailingIcon != null) {
      trailingWidget = Padding(
        padding: EdgeInsets.only(
          right: widget.trailingExtraMargin,
        ),
        child: Icon(
          widget.trailingIcon,
          color: widget.trailingIconIsMuted
              ? getEnteColorScheme(context).strokeMuted
              : widget.trailingIconColor,
        ),
      );
    } else {
      trailingWidget = widget.trailingWidget ?? const SizedBox.shrink();
    }
  }
}

class ExpansionTrailingIcon extends StatelessWidget {
  final bool isExpanded;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  const ExpansionTrailingIcon({
    super.key,
    required this.isExpanded,
    this.trailingIcon,
    this.trailingIconColor,
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
    super.key,
    required this.leadingIconSize,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (leadingIcon == null && leadingIconWidget == null) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: getEnteColorScheme(context).backgroundElevated,
      ),
      padding: const EdgeInsets.all(8.0),
      child: leadingIcon == null
          ? FittedBox(
              fit: BoxFit.contain,
              child: leadingIconWidget,
            )
          : FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                leadingIcon,
                color: leadingIconColor ?? getEnteColorScheme(context).fillBase,
              ),
            ),
    );
  }
}
