import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";

class OfflineSettingsBanner extends StatelessWidget {
  final VoidCallback onGetStarted;

  const OfflineSettingsBanner({
    super.key,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    const titleStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.bold,
      fontSize: 16,
      height: 28 / 16,
      letterSpacing: -1,
      color: Colors.white,
    );

    const descriptionStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 16 / 10,
      color: Color.fromRGBO(165, 165, 165, 0.79),
    );

    const buttonTextStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      color: Colors.black,
    );

    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 156,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(21, 21, 21, 1),
              Color.fromRGBO(43, 43, 43, 1),
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _DotsPainter(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 235),
                    child: Text(
                      l10n.offlineSettingsBannerTitle,
                      style: titleStyle,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 235),
                    child: Text(
                      l10n.offlineSettingsBannerDesc,
                      style: descriptionStyle,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: onGetStarted,
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          l10n.offlineEnableBackupAction,
                          style: buttonTextStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 0,
              child: IgnorePointer(
                child: Image.asset(
                  "assets/ducky_settings.png",
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  static const double _dotRadius = 2.0;
  static const double _horizontalSpacing = 24.0;
  static const double _verticalSpacing = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    final horizontalCount = (size.width / _horizontalSpacing).ceil() + 1;
    final verticalCount = (size.height / _verticalSpacing).ceil() + 1;

    for (int row = 0; row < verticalCount; row++) {
      for (int col = 0; col < horizontalCount; col++) {
        final x = col * _horizontalSpacing + (_horizontalSpacing / 2);
        final y = row * _verticalSpacing + (_verticalSpacing / 2);

        if (x <= size.width + _dotRadius && y <= size.height + _dotRadius) {
          canvas.drawCircle(Offset(x, y), _dotRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
