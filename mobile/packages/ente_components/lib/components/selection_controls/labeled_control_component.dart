import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

class LabeledControlComponent extends StatelessWidget {
  const LabeledControlComponent({
    super.key,
    required this.control,
    required this.label,
    this.subtitle,
  });

  final Widget control;
  final String label;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    return Row(
      children: [
        control,
        const SizedBox(width: Spacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: colors.textBase)),
              if (subtitle != null)
                Text(subtitle!, style: TextStyle(color: colors.textLight)),
            ],
          ),
        ),
      ],
    );
  }
}
