import 'package:flutter/material.dart';

class StorageProgressWidget extends StatelessWidget {
  final Color color;
  final double fractionOfStorage;
  const StorageProgressWidget({
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
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
          width: constrains.maxWidth * fractionOfStorage.clamp(0.0, 1.0),
          height: 4,
        );
      },
    );
  }
}
