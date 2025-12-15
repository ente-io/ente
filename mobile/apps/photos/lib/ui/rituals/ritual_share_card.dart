import "package:flutter/material.dart";
import "package:photos/models/rituals/ritual_models.dart";

class RitualShareCard extends StatelessWidget {
  const RitualShareCard({
    super.key,
    required this.ritual,
    required this.progress,
  });

  final Ritual ritual;
  final RitualProgress? progress;

  static const double width = 360;
  static const double height = 450;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0x14000000),
            width: 1,
          ),
        ),
      ),
    );
  }
}
