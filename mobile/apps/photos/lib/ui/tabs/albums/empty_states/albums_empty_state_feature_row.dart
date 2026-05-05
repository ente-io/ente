import "package:flutter/widgets.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";

class AlbumsEmptyStateFeatureRow extends StatelessWidget {
  const AlbumsEmptyStateFeatureRow({
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
          padding: const EdgeInsetsGeometry.all(6),
          child: HugeIcon(
            icon: icon,
            size: 20,
            color: const Color.fromRGBO(222, 222, 222, 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: textTheme.small,
          ),
        ),
      ],
    );
  }
}
