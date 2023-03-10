import "package:flutter/material.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';
import "package:photos/utils/separators_util.dart";

///https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?node-id=8113-59605&t=OMX5f5KdDJYWSQQN-4
class InfoItemWidget extends StatelessWidget {
  final IconData leadingIcon;
  final VoidCallback? editOnTap;
  final String title;
  final List<Widget> subtitle;
  const InfoItemWidget({
    required this.leadingIcon,
    required this.editOnTap,
    required this.title,
    required this.subtitle,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    //if subtitle has list of ChipButtons, set whitespace width to 12pts
    final subtitleWithSeparators =
        addSeparators(subtitle, const SizedBox(width: 8));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButtonWidget(
                icon: leadingIcon,
                iconButtonType: IconButtonType.secondary,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 3.5, 16, 3.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //modify textStyle if subtitle has list of ChipButtons
                      Text(title),
                      const SizedBox(height: 4),
                      Flexible(child: Wrap(children: subtitleWithSeparators)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        IconButtonWidget(
          icon: Icons.edit,
          iconButtonType: IconButtonType.secondary,
          onTap: editOnTap,
        ),
      ],
    );
  }
}
