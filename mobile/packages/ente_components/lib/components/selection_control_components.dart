import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2513-47857&m=dev
/// Section: Radio buttons, toggles and checkboxes / CheckboxComponent
/// Specs: 16px checkbox, selected and disabled variants.
class CheckboxComponent extends StatelessWidget {
  const CheckboxComponent({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final enabled = onChanged != null;
    final fill = selected
        ? (enabled ? colors.primary : colors.fillDarkest)
        : Colors.transparent;
    final stroke = enabled ? colors.strokeDark : colors.strokeFaint;

    return InkWell(
      onTap: enabled ? () => onChanged!(!selected) : null,
      borderRadius: BorderRadius.circular(4),
      child: AnimatedContainer(
        duration: Motion.quick,
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: selected ? fill : stroke),
        ),
        child: selected
            ? Icon(Icons.check_rounded, size: 12, color: colors.specialWhite)
            : null,
      ),
    );
  }
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2513-47857&m=dev
/// Section: Radio buttons, toggles and checkboxes / Radio Button
/// Specs: 16px radio, selected and disabled variants.
class RadioComponent extends StatelessWidget {
  const RadioComponent({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final enabled = onChanged != null;
    final active = enabled ? colors.primary : colors.fillDarkest;

    return InkWell(
      onTap: enabled ? () => onChanged!(!selected) : null,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: Motion.quick,
        width: 16,
        height: 16,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? active : colors.strokeDark,
            width: selected ? 2 : 1,
          ),
        ),
        child: selected
            ? DecoratedBox(
                decoration:
                    BoxDecoration(shape: BoxShape.circle, color: active),
              )
            : null,
      ),
    );
  }
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=2482-6644&m=dev
/// Section: Radio buttons, toggles and checkboxes / Toggle Switch
/// Specs: 31px by 18px switch with selected and unselected states.
class ToggleSwitchComponent extends StatelessWidget {
  const ToggleSwitchComponent({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final bool selected;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final enabled = onChanged != null;
    final track = selected
        ? (enabled ? colors.primary : colors.fillDarkest)
        : colors.strokeDark;

    return InkWell(
      onTap: enabled ? () => onChanged!(!selected) : null,
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: Motion.quick,
        width: 31,
        height: 18,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(9),
        ),
        child: AnimatedAlign(
          duration: Motion.quick,
          alignment: selected ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: colors.specialWhite,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

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
