import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";
import "package:photos/generated/intl/app_localizations.dart";

class MoreOptionsButton extends StatefulWidget {
  const MoreOptionsButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  State<MoreOptionsButton> createState() => _MoreOptionsButtonState();
}

// TODO: Replace this component once ente_components has a ghost button variant.
class _MoreOptionsButtonState extends State<MoreOptionsButton> {
  var _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final foreground = context.componentColors.textLight;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              l10n.moreOptions,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyles.body.copyWith(color: foreground),
            ),
            const SizedBox(width: Spacing.xs),
            Icon(
              Icons.keyboard_arrow_up,
              color: foreground,
              size: IconSizes.small,
            ),
          ],
        ),
      ),
    );
  }
}
