import "dart:async";

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/soft_icon_button.dart";

class EntePopupMenuOption<T> {
  const EntePopupMenuOption({
    required this.value,
    required this.label,
    this.secondaryLabel,
    this.labelColor,
    this.leadingWidget,
    this.isActive = false,
    this.trailingWidget,
    this.activeTrailingWidget,
    this.showDivider = true,
  });

  final T value;
  final String label;
  final String? secondaryLabel;
  final Color? labelColor;
  final Widget? leadingWidget;
  final bool isActive;
  final Widget? trailingWidget;
  final Widget? activeTrailingWidget;
  final bool showDivider;
}

class EntePopupMenuButton<T> extends StatelessWidget {
  const EntePopupMenuButton({
    required this.optionsBuilder,
    required this.onSelected,
    this.child,
    this.menuWidth = 196.0,
    this.itemHeight = 52.0,
    this.borderRadius = 20.0,
    this.elevation = 8.0,
    this.itemHorizontalPadding = 16.0,
    super.key,
  });

  final FutureOr<List<EntePopupMenuOption<T>>> Function() optionsBuilder;
  final FutureOr<void> Function(T value) onSelected;
  final Widget? child;
  final double menuWidth;
  final double itemHeight;
  final double borderRadius;
  final double elevation;
  final double itemHorizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final child = this.child;
    if (child == null) {
      return SoftIconButton(
        icon: HugeIcon(
          icon: HugeIcons.strokeRoundedMoreVertical,
          size: 18,
          color: colorScheme.textBase,
        ),
        onTap: () => _showMenu(context),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showMenu(context),
      child: child,
    );
  }

  Future<void> _showMenu(BuildContext context) async {
    final options = await optionsBuilder();
    if (options.isEmpty) {
      return;
    }

    final selected = await showEntePopupMenu<T>(
      context: context,
      options: options,
      menuWidth: menuWidth,
      itemHeight: itemHeight,
      borderRadius: borderRadius,
      elevation: elevation,
      itemHorizontalPadding: itemHorizontalPadding,
    );
    if (selected == null) return;
    await onSelected(selected);
  }
}

Future<T?> showEntePopupMenu<T>({
  required BuildContext context,
  required List<EntePopupMenuOption<T>> options,
  double menuWidth = 196.0,
  double itemHeight = 52.0,
  double borderRadius = 20.0,
  double elevation = 0.0,
  double itemHorizontalPadding = 16.0,
}) {
  final colorScheme = getEnteColorScheme(context);
  final button = context.findRenderObject()! as RenderBox;
  final overlay = Overlay.of(context).context.findRenderObject()! as RenderBox;
  // Anchor the menu to the button's bottom edge so it drops below the button
  // instead of opening on top of it (showMenu flips it upward if there's no
  // room below).
  final position = RelativeRect.fromRect(
    Rect.fromPoints(
      button.localToGlobal(
        button.size.bottomLeft(Offset.zero),
        ancestor: overlay,
      ),
      button.localToGlobal(
        button.size.bottomRight(Offset.zero),
        ancestor: overlay,
      ),
    ),
    Offset.zero & overlay.size,
  );

  return showMenu<T>(
    context: context,
    color: colorScheme.fill,
    elevation: elevation,
    constraints: BoxConstraints.tightFor(width: menuWidth),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: colorScheme.strokeFaint),
    ),
    position: position,
    items: List.generate(options.length, (index) {
      final option = options[index];
      return PopupMenuItem<T>(
        value: option.value,
        padding: EdgeInsets.zero,
        height: itemHeight,
        child: Container(
          height: itemHeight,
          padding: EdgeInsets.symmetric(horizontal: itemHorizontalPadding),
          decoration: BoxDecoration(
            border: option.showDivider && index != options.length - 1
                ? Border(bottom: BorderSide(color: colorScheme.strokeFaint))
                : null,
          ),
          child: _EntePopupMenuRow(option: option),
        ),
      );
    }),
  );
}

class _EntePopupMenuRow<T> extends StatelessWidget {
  const _EntePopupMenuRow({required this.option});

  final EntePopupMenuOption<T> option;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final titleStyle = textTheme.mini.copyWith(color: option.labelColor);
    final title = option.secondaryLabel == null
        ? Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: titleStyle,
          )
        : Row(
            children: [
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: titleStyle,
                ),
              ),
              const SizedBox(width: 6),
              Text("•", style: textTheme.miniMuted),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  option.secondaryLabel!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.miniMuted,
                ),
              ),
            ],
          );

    return Row(
      children: [
        if (option.leadingWidget != null) ...[
          SizedBox.square(
            dimension: 20,
            child: Center(child: option.leadingWidget),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(child: title),
        if (option.trailingWidget != null)
          option.trailingWidget!
        else if (option.activeTrailingWidget != null)
          option.isActive
              ? option.activeTrailingWidget!
              : const SizedBox(width: 12),
      ],
    );
  }
}
