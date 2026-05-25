import "package:ente_components/ente_components.dart";
import "package:flutter/material.dart";

class GenericFilterChip extends StatelessWidget {
  final String label;
  final IconData? leadingIcon;
  final VoidCallback apply;
  final VoidCallback remove;
  final bool isApplied;

  const GenericFilterChip({
    required this.label,
    required this.apply,
    required this.remove,
    required this.isApplied,
    this.leadingIcon,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChipComponent(
      label: label,
      leading: leadingIcon == null ? null : Icon(leadingIcon),
      state: isApplied
          ? FilterChipComponentState.selected
          : FilterChipComponentState.unselected,
      onChanged: (_) => isApplied ? remove() : apply(),
    );
  }
}
