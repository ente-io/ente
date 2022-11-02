import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';

enum DividerType {
  solid,
  menu,
  menuNoIcon,
  bottomBar,
}

class DividerWidget extends StatelessWidget {
  final DividerType dividerType;
  final Color bgColor;
  const DividerWidget({
    required this.dividerType,
    this.bgColor = Colors.transparent,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final dividerColor = getEnteColorScheme(context).blurStrokeFaint;
    if (dividerType == DividerType.solid) {
      return Container(
        color: getEnteColorScheme(context).strokeFaint,
        width: double.infinity,
        height: 1,
      );
    }
    if (dividerType == DividerType.bottomBar) {
      return Container(
        color: dividerColor,
        width: double.infinity,
        height: 1,
      );
    }

    return Row(
      children: [
        Container(
          color: bgColor,
          width: dividerType == DividerType.menu
              ? 48
              : dividerType == DividerType.menuNoIcon
                  ? 16
                  : 0,
          height: 1,
        ),
        Expanded(
          child: Container(
            color: dividerColor,
            height: 1,
            width: double.infinity,
          ),
        ),
      ],
    );

    // return SizedBox(
    //   width: double.infinity,
    //   child: Row(
    //     children: [
    //       Container(
    //         color: bgColor,
    //         height: 1,
    //         width: dividerType == DividerType.menu
    //             ? 48
    //             : dividerType == DividerType.menuNoIcon
    //                 ? 16
    //                 : 0,
    //       ),
    //       Container(
    //         height: 1,
    //         width: 100,
    //         color: dividerColor,
    //       ),
    //     ],
    //   ),
    // );

    //  else if (dividerType == DividerType.menu) {
    //   return Padding(
    //     padding: const EdgeInsets.only(left: 48),
    //     child: divider,
    //   );
    // } else if (dividerType == DividerType.menuNoIcon) {
    //   return Padding(
    //     padding: const EdgeInsets.only(left: 16),
    //     child: divider,
    //   );
    // } else if (dividerType == DividerType.bottomBar) {
    //   return divider;
    // } else {
    //   return const SizedBox.shrink();
    // }
  }
}
