import 'package:flutter/material.dart';

// trailing icon can be passed without size as default size set by flutter is what this component expects
class MenuItemWidget extends StatelessWidget {
  final Widget captionedTextWidget;
  final bool isHeaderOfExpansion;
  final IconData? leadingIcon;
  final Color? leadingIconColor;
  final IconData? trailingIcon;
  final Widget? trailingSwitch;
  final bool trailingIconIsMuted;
  final Function? onTap;
  final Color? menuItemColor;
  final bool alignCaptionedTextToLeft;
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return isHeaderOfExpansion
        ? menuItemWidget(context)
        : GestureDetector(
            onTap: () {
              onTap;
            },
            child: menuItemWidget(context),
          );
  }

  Widget menuItemWidget(BuildContext context) {
    return Container(
      color: menuItemColor,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          alignCaptionedTextToLeft && leadingIcon == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: leadingIcon == null
                        ? const SizedBox.shrink()
                        : FittedBox(
                            fit: BoxFit.contain,
                            child: Icon(
                              leadingIcon,
                              color: leadingIconColor,
                            ),
                          ),
                  ),
                ),
          captionedTextWidget,
          trailingIcon != null
              ? Icon(trailingIcon)
              : trailingSwitch ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}
