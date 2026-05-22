import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:hugeicons/hugeicons.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/soft_icon_button.dart";

class EntePopupMenuOption<T> {
  const EntePopupMenuOption({
    required this.value,
    required this.label,
    this.secondaryLabel,
    this.isActive = false,
    this.trailingWidget,
    this.activeTrailingWidget,
    this.showDivider = true,
  });

  final T value;
  final String label;
  final String? secondaryLabel;
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
    this.screenPadding = 16.0,
    this.itemHorizontalPadding = 16.0,
    this.menuVerticalOffset = 12.0,
    super.key,
  });

  final List<EntePopupMenuOption<T>> Function() optionsBuilder;
  final FutureOr<void> Function(T value) onSelected;
  final Widget? child;
  final double menuWidth;
  final double itemHeight;
  final double borderRadius;
  final double elevation;
  final double screenPadding;
  final double itemHorizontalPadding;
  final double menuVerticalOffset;

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
        onTap: () {},
        onTapDown: (details) => _showMenu(context, details),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) => _showMenu(context, details),
      child: child,
    );
  }

  Future<void> _showMenu(
    BuildContext context,
    TapDownDetails details,
  ) async {
    final options = optionsBuilder();
    if (options.isEmpty) {
      return;
    }

    final selected = await showEntePopupMenu<T>(
      context: context,
      details: details,
      options: options,
      menuWidth: menuWidth,
      itemHeight: itemHeight,
      borderRadius: borderRadius,
      elevation: elevation,
      screenPadding: screenPadding,
      itemHorizontalPadding: itemHorizontalPadding,
      menuVerticalOffset: menuVerticalOffset,
    );
    if (selected == null) return;
    await onSelected(selected);
  }
}

Future<T?> showEntePopupMenu<T>({
  required BuildContext context,
  required TapDownDetails details,
  required List<EntePopupMenuOption<T>> options,
  double menuWidth = 196.0,
  double itemHeight = 52.0,
  double borderRadius = 20.0,
  double elevation = 8.0,
  double screenPadding = 16.0,
  double itemHorizontalPadding = 16.0,
  double menuVerticalOffset = 12.0,
}) {
  final colorScheme = getEnteColorScheme(context);
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  final overlaySize = overlay?.size ?? MediaQuery.sizeOf(context);
  final effectiveMenuWidth = math.min<double>(
    menuWidth,
    math.max(0.0, overlaySize.width - (screenPadding * 2)),
  );
  final left = _getMenuLeft(
    tapX: details.globalPosition.dx,
    menuWidth: effectiveMenuWidth,
    overlayWidth: overlaySize.width,
    screenPadding: screenPadding,
  );
  final top = details.globalPosition.dy + menuVerticalOffset;
  final right = math.max(
    screenPadding,
    overlaySize.width - left - effectiveMenuWidth,
  );

  return showMenu<T>(
    context: context,
    color: colorScheme.fill,
    elevation: elevation,
    constraints: BoxConstraints.tightFor(width: effectiveMenuWidth),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(borderRadius),
      side: BorderSide(color: colorScheme.strokeFaint),
    ),
    position: RelativeRect.fromLTRB(
      left,
      top,
      right,
      overlaySize.height - top,
    ),
    items: options
        .map(
          (option) => PopupMenuItem<T>(
            value: option.value,
            padding: EdgeInsets.zero,
            height: itemHeight,
            child: Container(
              height: itemHeight,
              padding: EdgeInsets.symmetric(
                horizontal: itemHorizontalPadding,
              ),
              decoration: BoxDecoration(
                border: option.showDivider
                    ? Border(
                        bottom: BorderSide(color: colorScheme.strokeFaint),
                      )
                    : null,
              ),
              child: _EntePopupMenuRow(option: option),
            ),
          ),
        )
        .toList(),
  );
}

double _getMenuLeft({
  required double tapX,
  required double menuWidth,
  required double overlayWidth,
  required double screenPadding,
}) {
  const trailingAnchorOffset = 32.0;
  final preferredLeft = tapX - menuWidth + trailingAnchorOffset;
  final maxLeft =
      math.max(screenPadding, overlayWidth - menuWidth - screenPadding);
  return math.min(math.max(screenPadding, preferredLeft), maxLeft);
}

class _EntePopupMenuRow<T> extends StatelessWidget {
  const _EntePopupMenuRow({required this.option});

  final EntePopupMenuOption<T> option;

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final title = option.secondaryLabel == null
        ? Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.mini,
          )
        : Row(
            children: [
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.mini,
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
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
