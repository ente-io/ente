import "dart:async";

import "package:ente_components/theme/icon_sizes.dart";
import "package:ente_components/theme/spacing.dart";
import "package:ente_components/theme/text_styles.dart";
import "package:ente_components/theme/theme.dart";
import "package:flutter/widgets.dart";

class GhostButtonComponent extends StatefulWidget {
  const GhostButtonComponent({
    super.key,
    required this.label,
    this.onTap,
    this.isDisabled = false,
    this.trailing,
  });

  final String label;
  final FutureOr<void> Function()? onTap;
  final bool isDisabled;
  final Widget? trailing;

  @override
  State<GhostButtonComponent> createState() => _GhostButtonComponentState();
}

class _GhostButtonComponentState extends State<GhostButtonComponent> {
  static const Duration _minimumPressDuration = Duration(milliseconds: 120);

  bool _isHovered = false;
  bool _isPressed = false;
  int _pressToken = 0;
  DateTime? _tapDownTime;
  Timer? _pressReleaseTimer;

  @override
  void dispose() {
    _pressReleaseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final foreground = _foreground(context);
    final enabled = _canHandleGestures;

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? widget.onTap : null,
        onTapDown: enabled ? (_) => _setPressed(true) : null,
        onTapUp: enabled ? (_) => _releasePressed() : null,
        onTapCancel: enabled ? _releasePressed : null,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyles.body.copyWith(
                    color: foreground,
                    decoration: TextDecoration.none,
                  ),
                ),
                if (widget.trailing != null) ...[
                  const SizedBox(width: Spacing.xs),
                  IconTheme.merge(
                    data: IconThemeData(
                      color: foreground,
                      size: IconSizes.tiny,
                    ),
                    child: widget.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setHovered(bool value) {
    if (!_canHandleGestures || _isHovered == value) return;
    setState(() => _isHovered = value);
  }

  void _setPressed(bool value) {
    if (!_canHandleGestures || _isPressed == value) return;

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

  bool get _canHandleGestures => !widget.isDisabled && widget.onTap != null;

  Color _foreground(BuildContext context) {
    final colors = context.componentColors;
    return colors.textLight;
  }
}
