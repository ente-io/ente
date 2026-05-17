import "package:flutter/widgets.dart";
import "package:hugeicons/hugeicons.dart";

const double _hugeIconStrokeWidth = 1.5;

class LegacyKitDownloadIcon extends StatelessWidget {
  final Color color;
  final double size;

  const LegacyKitDownloadIcon({
    required this.color,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedDownload02,
      color: color,
      size: size,
      strokeWidth: _hugeIconStrokeWidth,
    );
  }
}

class LegacyKitShareIcon extends StatelessWidget {
  final Color color;
  final double size;

  const LegacyKitShareIcon({
    required this.color,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedShare08,
      color: color,
      size: size,
      strokeWidth: _hugeIconStrokeWidth,
    );
  }
}

class LegacyKitEditIcon extends StatelessWidget {
  final Color color;
  final double size;

  const LegacyKitEditIcon({
    required this.color,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedEdit03,
      color: color,
      size: size,
      strokeWidth: _hugeIconStrokeWidth,
    );
  }
}

class LegacyKitClockIcon extends StatelessWidget {
  final Color color;
  final double size;

  const LegacyKitClockIcon({
    required this.color,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedClock01,
      color: color,
      size: size,
      strokeWidth: _hugeIconStrokeWidth,
    );
  }
}

class LegacyKitRowIcon extends StatelessWidget {
  final Color color;
  final double size;

  const LegacyKitRowIcon({
    required this.color,
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return HugeIcon(
      icon: HugeIcons.strokeRoundedFileFavourite,
      color: color,
      size: size,
      strokeWidth: _hugeIconStrokeWidth,
    );
  }
}

class LegacyKitAlertIcon extends StatelessWidget {
  final double size;

  const LegacyKitAlertIcon({
    this.size = 18,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      "assets/warning-red.png",
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}
