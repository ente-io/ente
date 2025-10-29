import "package:dotted_border/dotted_border.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class HomeEmptyStateWidget extends StatelessWidget {
  final VoidCallback onTap;
  const HomeEmptyStateWidget({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    return DottedBorder(
      options: const RoundedRectDottedBorderOptions(
        strokeWidth: 1,
        color: Color.fromRGBO(82, 82, 82, 0.6),
        dashPattern: [5, 5],
        radius: Radius.circular(24),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.backdropBase,
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 42,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/upload_file.png',
              ),
              const SizedBox(height: 12),
              Text(
                'Upload a File',
                style: textTheme.h3Bold.copyWith(
                  color: colorScheme.textBase,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Click here to upload',
                style: textTheme.small.copyWith(
                  color: colorScheme.primary700,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
