import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

enum FilterChipComponentState {
  selected,
  unselected,
  disabled,
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=9524-4352&m=dev
/// Section: Filter Chip
/// Specs: 40px height, 24px radius, selected/unselected/disabled states with icon and avatar slots.
class FilterChipComponent extends StatelessWidget {
  const FilterChipComponent({
    super.key,
    this.label,
    this.leading,
    this.trailing,
    this.avatar,
    this.state = FilterChipComponentState.unselected,
    this.onChanged,
    this.tooltip,
  }) : assert(label != null || avatar != null);

  final String? label;
  final Widget? leading;
  final Widget? trailing;
  final Widget? avatar;
  final FilterChipComponentState state;
  final ValueChanged<bool>? onChanged;
  final String? tooltip;

  bool get _selected => state == FilterChipComponentState.selected;

  bool get _enabled =>
      state != FilterChipComponentState.disabled && onChanged != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final textColor = switch (state) {
      FilterChipComponentState.selected => colors.primary,
      FilterChipComponentState.unselected => colors.textLight,
      FilterChipComponentState.disabled => colors.textLightest,
    };
    final background = _selected ? colors.primaryLight : colors.fillLight;

    Widget chip = MouseRegion(
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _enabled ? () => onChanged!(!_selected) : null,
        child: AnimatedContainer(
          key: const ValueKey('filter-chip-surface'),
          duration: Motion.quick,
          curve: Curves.easeInOutCubic,
          height: 40,
          constraints: const BoxConstraints(minWidth: 40),
          padding: _padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: _children(textColor),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      chip = Tooltip(message: tooltip!, child: chip);
    }

    return Semantics(
      button: true,
      enabled: _enabled,
      selected: _selected,
      label: tooltip ?? label,
      child: chip,
    );
  }

  List<Widget> _children(Color color) {
    final children = <Widget>[];
    final gap = avatar != null ? Spacing.xs : Spacing.sm;

    void addGap() {
      if (children.isNotEmpty) {
        children.add(SizedBox(width: gap));
      }
    }

    if (avatar != null) {
      children.add(
        _FilterChipAvatar(
          enabled: state != FilterChipComponentState.disabled,
          child: avatar!,
        ),
      );
    }

    if (leading != null) {
      addGap();
      children.add(_FilterChipIcon(color: color, child: leading!));
    }

    if (label != null) {
      addGap();
      children.add(
        Text(
          label!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyles.mini.copyWith(color: color),
        ),
      );
    }

    final selectedTrailing = _selected && trailing == null;
    if (trailing != null || selectedTrailing) {
      addGap();
      children.add(
        _FilterChipIcon(
          color: color,
          size: selectedTrailing ? 12 : 18,
          child: selectedTrailing ? const Icon(Icons.close_rounded) : trailing!,
        ),
      );
    }

    return children;
  }

  EdgeInsets get _padding {
    if (avatar != null && label == null) {
      return _selected
          ? const EdgeInsets.fromLTRB(
              Spacing.xs,
              Spacing.xs,
              Spacing.sm,
              Spacing.xs,
            )
          : const EdgeInsets.all(Spacing.xs);
    }

    if (avatar != null) {
      return EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.xs,
        _selected ? Spacing.sm : 18,
        Spacing.xs,
      );
    }

    if (leading != null && trailing == null) {
      return EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.md,
        _selected ? Spacing.md : Spacing.lg,
        Spacing.md,
      );
    }

    if (trailing != null) {
      return const EdgeInsets.fromLTRB(
        Spacing.lg,
        Spacing.md,
        Spacing.md,
        Spacing.md,
      );
    }

    if (_selected) {
      return const EdgeInsets.fromLTRB(18, Spacing.md, Spacing.md, Spacing.md);
    }

    return const EdgeInsets.symmetric(
      horizontal: 18,
      vertical: Spacing.md,
    );
  }
}

class _FilterChipIcon extends StatelessWidget {
  const _FilterChipIcon({
    required this.color,
    required this.child,
    this.size = 18,
  });

  final Color color;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size == 12 ? 20 : 16,
      child: Center(
        child: IconTheme.merge(
          data: IconThemeData(color: color, size: size),
          child: child,
        ),
      ),
    );
  }
}

class _FilterChipAvatar extends StatelessWidget {
  const _FilterChipAvatar({
    required this.enabled,
    required this.child,
  });

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.6,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Radii.button),
        child: SizedBox.square(
          dimension: 32,
          child: child,
        ),
      ),
    );
  }
}
