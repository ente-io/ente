import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String label;
  final double width;

  const FieldLabel(
    this.label, {
    super.key,
    this.width = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: SizedBox(
        width: width,
        child: Text(
          label,
          style: getEnteTextTheme(context).miniBoldMuted,
        ),
      ),
    );
  }
}
