import 'package:flutter/material.dart';

class LinearProgressWidget extends StatelessWidget {
  final Color color;
  final double fractionOfStorage;
  const LinearProgressWidget({
    required this.color,
    required this.fractionOfStorage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constrains) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: color,
          ),
          width: constrains.maxWidth * fractionOfStorage,
          height: 4,
        );
      },
    );
  }
}
