import 'package:flutter/widgets.dart';
import 'package:photos/theme/ente_theme.dart';

class ChangeLogEntry extends StatelessWidget {
  final bool isFeature;
  final String title;
  final String description;

  const ChangeLogEntry({
    super.key,
    required this.isFeature,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final enteTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);
    return Column(
      children: [
        Text(
          title,
          style: enteTheme.largeBold.copyWith(
            color: isFeature ? colorScheme.primary700 : colorScheme.textMuted,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
        Text(
          description,
          style: enteTheme.body.copyWith(
            color: colorScheme.textMuted,
          ),
        ),
        const SizedBox(
          height: 18,
        ),
      ],
    );
  }
}
