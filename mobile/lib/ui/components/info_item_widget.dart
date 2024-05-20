import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/common/loading_widget.dart";
import 'package:photos/ui/components/buttons/icon_button_widget.dart';

///https://www.figma.com/file/SYtMyLBs5SAOkTbfMMzhqt/ente-Visual-Design?node-id=8113-59605&t=OMX5f5KdDJYWSQQN-4
class InfoItemWidget extends StatelessWidget {
  final IconData leadingIcon;
  final VoidCallback? editOnTap;
  final String? title;
  final Widget? endSection;
  final Future<List<Widget>> subtitleSection;
  final bool hasChipButtons;
  final bool biggerSpinner;
  final VoidCallback? onTap;
  const InfoItemWidget({
    required this.leadingIcon,
    this.editOnTap,
    this.title,
    this.endSection,
    required this.subtitleSection,
    this.hasChipButtons = false,
    this.biggerSpinner = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (title != null) {
      children.addAll([
        Text(
          title!,
          style: hasChipButtons
              ? getEnteTextTheme(context).miniMuted
              : getEnteTextTheme(context).small,
        ),
        SizedBox(height: hasChipButtons ? 8 : 4),
      ]);
    }

    children.addAll([
      Flexible(
        child: FutureBuilder(
          future: subtitleSection,
          builder: (context, snapshot) {
            Widget child;
            if (snapshot.hasData) {
              final subtitle = snapshot.data as List<Widget>;
              if (subtitle.isNotEmpty) {
                child = Wrap(
                  runSpacing: 8,
                  spacing: 8,
                  children: subtitle,
                );
              } else {
                child = const SizedBox.shrink();
              }
            } else {
              child = EnteLoadingWidget(
                padding: biggerSpinner ? 6 : 3,
                size: biggerSpinner ? 20 : 11,
                color: getEnteColorScheme(context).strokeMuted,
                alignment:
                    biggerSpinner ? Alignment.center : Alignment.centerLeft,
              );
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeInOutExpo,
              child: child,
            );
          },
        ),
      ),
    ]);

    endSection != null ? children.add(endSection!) : null;

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
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: onTap,
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        editOnTap != null
            ? IconButtonWidget(
                icon: Icons.edit,
                iconButtonType: IconButtonType.secondary,
                onTap: editOnTap,
              )
            : const SizedBox.shrink(),
      ],
    );
  }
}
