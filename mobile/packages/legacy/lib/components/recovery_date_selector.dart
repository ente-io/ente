import "package:ente_strings/ente_strings.dart";
import "package:ente_ui/theme/ente_theme.dart";
import "package:flutter/material.dart";

enum RecoveryDateSelectorLayout { chips, list }

class RecoveryDateSelector extends StatelessWidget {
  final int selectedDays;
  final ValueChanged<int> onDaysChanged;
  final List<int> dayOptions;
  final RecoveryDateSelectorLayout layout;

  const RecoveryDateSelector({
    required this.selectedDays,
    required this.onDaysChanged,
    this.dayOptions = const [7, 14, 30],
    this.layout = RecoveryDateSelectorLayout.chips,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);

    return switch (layout) {
      RecoveryDateSelectorLayout.chips => _buildChips(
          context,
          colorScheme,
          textTheme,
        ),
      RecoveryDateSelectorLayout.list => Column(
          children: [
            for (var index = 0; index < dayOptions.length; index++) ...[
              _buildListItem(
                context,
                dayOptions[index],
                colorScheme,
                textTheme,
              ),
              if (index < dayOptions.length - 1) const SizedBox(height: 8),
            ],
          ],
        ),
    };
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
          days == 0 ? context.strings.immediate : context.strings.nDays(days),
          style: textTheme.bodyBold.copyWith(
            color: isSelected ? Colors.white : colorScheme.primary700,
          ),
        ),
      ),
    );
  }

  Widget _buildChips(
    BuildContext context,
    colorScheme,
    textTheme,
  ) {
    final chips = dayOptions
        .map((days) => _buildChip(context, days, colorScheme, textTheme))
        .toList(growable: false);

    if (chips.length == 3) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          chips[0],
          const SizedBox(width: 12),
          chips[1],
          const SizedBox(width: 12),
          chips[2],
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: chips,
    );
  }

  Widget _buildListItem(
    BuildContext context,
    int days,
    colorScheme,
    textTheme,
  ) {
    final isSelected = selectedDays == days;
    final cardColor = colorScheme.isLightTheme
        ? Colors.white
        : colorScheme.backgroundElevated2;
    final borderColor = colorScheme.primary700.withValues(alpha: 0.24);

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => onDaysChanged(days),
        child: Container(
          height: 60,
          padding: const EdgeInsets.only(left: 16, right: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelected ? Border.all(color: borderColor) : null,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  days == 0
                      ? context.strings.immediate
                      : context.strings.nDays(days),
                  style: textTheme.small.copyWith(height: 20 / 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 34,
                height: 34,
                child: isSelected
                    ? Center(
                        child: Icon(
                          Icons.check_circle,
                          size: 18,
                          color: colorScheme.primary700,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
