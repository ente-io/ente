import "package:ente_components/ente_components.dart";
import "package:flutter/widgets.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";

class EmptyStateFeatureRow extends StatelessWidget {
  const EmptyStateFeatureRow({
    required this.icon,
    required this.label,
    super.key,
  });

  final List<List<dynamic>> icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(6),
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: const Color.fromRGBO(222, 222, 222, 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: textTheme.small)),
      ],
    );
  }
}

class EmptyStateBulletFeatureRow extends StatelessWidget {
  const EmptyStateBulletFeatureRow({
    required this.label,
    super.key,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 5,
          height: 20,
          child: Align(
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: const SizedBox.square(dimension: 4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyles.body.copyWith(color: colors.textLight),
          ),
        ),
      ],
    );
  }
}
