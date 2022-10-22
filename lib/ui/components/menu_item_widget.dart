import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class MenuItemWidget extends StatefulWidget {
  final Widget captionedTextWidget;
  final bool isHeaderOfExpansion;
// leading icon can be passed without specifing size of icon, this component sets size to 20x20 irrespective of passed icon's size
  final IconData? leadingIcon;
  final Color? leadingIconColor;
// trailing icon can be passed without size as default size set by flutter is what this component expects
  final IconData? trailingIcon;
  final Widget? trailingSwitch;
  final bool trailingIconIsMuted;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Color? menuItemColor;
  final bool alignCaptionedTextToLeft;
  final double borderRadius;
  final Color? pressedColor;
  final ExpandableController? expandableController;
  const MenuItemWidget({
    required this.captionedTextWidget,
    this.isHeaderOfExpansion = false,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailingIcon,
    this.trailingSwitch,
    this.trailingIconIsMuted = false,
    this.onTap,
    this.onDoubleTap,
    this.menuItemColor,
    this.alignCaptionedTextToLeft = false,
    this.borderRadius = 4.0,
    this.pressedColor,
    this.expandableController,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  Color? menuItemColor;
  @override
  void initState() {
    menuItemColor = widget.menuItemColor;
    if (widget.expandableController != null) {
      widget.expandableController!.addListener(() {
        setState(() {});
      });
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    menuItemColor = widget.menuItemColor;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (widget.expandableController != null) {
      widget.expandableController!.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isHeaderOfExpansion
        ? menuItemWidget(context)
        : GestureDetector(
            onTap: widget.onTap,
            onDoubleTap: widget.onDoubleTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onCancel,
            child: menuItemWidget(context),
          );
  }

  Widget menuItemWidget(BuildContext context) {
    final enteColorScheme = Theme.of(context).colorScheme.enteTheme.colorScheme;
    final borderRadius = Radius.circular(widget.borderRadius);
    final isExpanded = widget.expandableController?.value;
    final bottomBorderRadius = isExpanded != null && isExpanded
        ? const Radius.circular(0)
        : borderRadius;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 20),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: borderRadius,
          topRight: borderRadius,
          bottomLeft: bottomBorderRadius,
          bottomRight: bottomBorderRadius,
        ),
        color: menuItemColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.alignCaptionedTextToLeft && widget.leadingIcon == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: widget.leadingIcon == null
                        ? const SizedBox.shrink()
                        : FittedBox(
                            fit: BoxFit.contain,
                            child: Icon(
                              widget.leadingIcon,
                              color: widget.leadingIconColor,
                            ),
                          ),
                  ),
                ),
          widget.captionedTextWidget,
          widget.expandableController != null
              ? AnimatedOpacity(
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeInOut,
                  opacity: isExpanded! ? 0 : 1,
                  child: AnimatedSwitcher(
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    duration: const Duration(milliseconds: 200),
                    switchInCurve: Curves.easeOut,
                    child: isExpanded
                        ? const SizedBox.shrink()
                        : Icon(widget.trailingIcon),
                  ),
                )
              : widget.trailingIcon != null
                  ? Icon(
                      widget.trailingIcon,
                      color: widget.trailingIconIsMuted
                          ? enteColorScheme.strokeMuted
                          : null,
                    )
                  : widget.trailingSwitch ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  void _onTapDown(details) {
    setState(() {
      menuItemColor = widget.pressedColor;
    });
  }

  void _onTapUp(details) {
    Future.delayed(
      const Duration(milliseconds: 100),
      () => setState(() {
        menuItemColor = widget.menuItemColor;
      }),
    );
  }

  void _onCancel() {
    setState(() {
      menuItemColor = widget.menuItemColor;
    });
  }
}
