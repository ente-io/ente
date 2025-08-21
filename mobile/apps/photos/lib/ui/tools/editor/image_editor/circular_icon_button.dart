import 'package:flutter/material.dart';
import "package:flutter_svg/svg.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/theme/ente_theme.dart";

class CircularIconButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final String? svgPath;
  final double size;
  final bool isSelected;

  const CircularIconButton({
    super.key,
    required this.label,
    required this.onTap,
    this.svgPath,
    this.size = 60,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = EnteTheme.getTextTheme(theme);
    final colorScheme = EnteTheme.getColorScheme(theme);
    return SizedBox(
      width: 90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: size,
              width: size,
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.imageEditorPrimaryColor
                        .withOpacity(0.24)
                    : theme.colorScheme.editorBackgroundColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? theme.colorScheme.imageEditorPrimaryColor
                      : theme.colorScheme.editorBackgroundColor,
                  width: 2,
                ),
              ),
              child: svgPath != null
                  ? SvgPicture.asset(
                      svgPath!,
                      width: 12,
                      height: 12,
                      fit: BoxFit.scaleDown,
                      colorFilter: ColorFilter.mode(
                        colorScheme.tabIcon,
                        BlendMode.srcIn,
                      ),
                    )
                  : const SizedBox(),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.small,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
