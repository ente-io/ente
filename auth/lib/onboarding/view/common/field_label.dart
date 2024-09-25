import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  final String label;

  const FieldLabel(
    this.label, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: SizedBox(
        width: 80,
        child: Text(
          label,
          style: getEnteTextTheme(context).miniBoldMuted,
        ),
      ),
    );
  }
}
