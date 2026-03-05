import "package:flutter/material.dart";

class QrCodeDetectionOverlay extends StatelessWidget {
  const QrCodeDetectionOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 48,
        height: 48,
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Colors.white,
        ),
      ),
    );
  }
}
