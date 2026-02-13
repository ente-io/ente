import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/service_locator.dart";

class OfflineSettingsBanner extends StatefulWidget {
  final VoidCallback onGetStarted;

  const OfflineSettingsBanner({
    super.key,
    required this.onGetStarted,
  });

  @override
  State<OfflineSettingsBanner> createState() => _OfflineSettingsBannerState();
}

class _OfflineSettingsBannerState extends State<OfflineSettingsBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    if (localSettings.isOfflineSettingsBannerDismissed) {
      return const SizedBox.shrink();
    }

    const titleStyle = TextStyle(
      fontFamily: "Nunito",
      fontWeight: FontWeight.w800,
      fontSize: 18,
      height: 28 / 18,
      letterSpacing: -1,
      color: Colors.white,
    );

    const descriptionStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 12,
      height: 18 / 12,
      color: Color.fromRGBO(165, 165, 165, 0.79),
    );

    const buttonTextStyle = TextStyle(
      fontFamily: "Montserrat",
      fontWeight: FontWeight.w600,
      fontSize: 10,
      height: 12 / 10,
      color: Colors.black,
    );

    final l10n = AppLocalizations.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 165,
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 235),
                          child: Text(
                            l10n.offlineSettingsBannerTitle,
                            style: titleStyle,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: _onDismiss,
                        behavior: HitTestBehavior.opaque,
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              color: Colors.white,
                              size: 20,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 235),
                    child: Text(
                      l10n.offlineSettingsBannerDesc,
                      style: descriptionStyle,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: widget.onGetStarted,
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
                  height: 100,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onDismiss() {
    setState(() {
      _dismissed = true;
    });
    unawaited(localSettings.setOfflineSettingsBannerDismissed(true));
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
