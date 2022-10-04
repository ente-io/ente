import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';

// trailing icon can be passed without size as default size set by flutter is what this component expects
class MenuItemWidget extends StatefulWidget {
  final Widget captionedTextWidget;
  final bool isHeaderOfExpansion;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final IconData? trailingIcon;
  final Widget? trailingSwitch;
  final bool trailingIconIsMuted;
  final VoidCallback? onTap;
  final Color? menuItemColor;
  final bool alignCaptionedTextToLeft;
  final double borderRadius;
  final ExpandableController? expandableController;
  const MenuItemWidget({
    required this.captionedTextWidget,
    required this.isHeaderOfExpansion,
    this.leadingIcon,
    this.leadingIconColor,
    this.trailingIcon,
    this.trailingSwitch,
    this.trailingIconIsMuted = false,
    this.onTap,
    this.menuItemColor,
    this.alignCaptionedTextToLeft = false,
    this.borderRadius = 4.0,
    this.expandableController,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  @override
  void initState() {
    if (widget.expandableController != null) {
      widget.expandableController!.addListener(() {
        setState(() {});
      });
    }
    super.initState();
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
            child: menuItemWidget(context),
          );
  }

  Widget menuItemWidget(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        color: widget.menuItemColor,
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
              ? _isExpanded()
                  ? const SizedBox.shrink()
                  : Icon(widget.trailingIcon)
              : widget.trailingIcon != null
                  ? Icon(widget.trailingIcon)
                  : widget.trailingSwitch ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  bool _isExpanded() {
    return widget.expandableController!.value;
  }
}
