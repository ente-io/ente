import "package:flutter/material.dart";
import "package:photos/core/constants.dart";
import "package:photos/theme/ente_theme.dart";

class GenericFilterChip extends StatefulWidget {
  final String label;
  final IconData? leadingIcon;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;
  final bool isInAllFiltersView;

  const GenericFilterChip({
    required this.label,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.leadingIcon,
    this.isInAllFiltersView = false,
    super.key,
  });

  @override
  State<GenericFilterChip> createState() => _GenericFilterChipState();
}

class _GenericFilterChipState extends State<GenericFilterChip> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.isApplied) {
          widget.remove();
        } else {
          widget.apply();
        }
      },
      child: SizedBox(
        // +1 to account for the filter's outer stroke width
        height: kFilterChipHeight + 1,
        child: Container(
          decoration: BoxDecoration(
            color: getEnteColorScheme(context).fillFaint,
            borderRadius: const BorderRadius.all(
              Radius.circular(kFilterChipHeight / 2),
            ),
            border: Border.all(
              color: getEnteColorScheme(context).strokeFaint,
              width: 0.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                widget.leadingIcon != null
                    ? Icon(
                        widget.leadingIcon,
                        size: 16,
                      )
                    : const SizedBox.shrink(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    widget.label,
                    style: getEnteTextTheme(context).miniBold,
                  ),
                ),
                widget.isApplied
                    ? const SizedBox(width: 2)
                    : const SizedBox.shrink(),
                widget.isApplied
                    ? Icon(
                        Icons.close_rounded,
                        size: 16,
                        color: getEnteColorScheme(context).textMuted,
                      )
                    : const SizedBox.shrink(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
