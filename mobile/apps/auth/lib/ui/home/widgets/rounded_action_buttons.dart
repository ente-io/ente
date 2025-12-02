import 'package:ente_auth/theme/colors.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class PrimaryRoundedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;

  const PrimaryRoundedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: ShapeDecoration(
          color: accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.small.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class SecondaryRoundedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final double? width;

  const SecondaryRoundedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    final isDarkTheme = !colorScheme.isLightTheme;
    final backgroundColor =
        isDarkTheme ? const Color(0x29A75CFF) : const Color(0x0AA75CFF);

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: width,
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        decoration: ShapeDecoration(
          color: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: textTheme.small.copyWith(
              color: colorScheme.textBase,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class TextLinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const TextLinkButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
        child: Text(
          label,
          style: textTheme.small.copyWith(
            color: colorScheme.textBase,
            fontWeight: FontWeight.w600,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}
