import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

class RecoveryDateSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;

  const RecoveryDateSelector({
    required this.selectedDays,
    required this.onDaysChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildChip(context, 7, colorScheme, textTheme),
        const SizedBox(width: 12),
        _buildChip(context, 14, colorScheme, textTheme),
        const SizedBox(width: 12),
        _buildChip(context, 30, colorScheme, textTheme),
      ],
    );
  }

  Widget _buildChip(
    BuildContext context,
    int days,
    colorScheme,
    textTheme,
  ) {
    final isSelected = selectedDays == days;
    return GestureDetector(
      onTap: () => onDaysChanged(days),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 26.0,
          vertical: 18.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary700 : colorScheme.fillFaint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          context.strings.nDays(days),
          style: textTheme.bodyBold.copyWith(
            color: isSelected ? Colors.white : colorScheme.primary700,
          ),
        ),
      ),
    );
  }
}
