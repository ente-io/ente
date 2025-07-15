import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

enum PeopleBannerType {
  addName,
  suggestion,
}

class PeopleBanner extends StatelessWidget {
  final PeopleBannerType type;
  final IconData? startIcon;
  final PersonFaceWidget? faceWidget;
  final IconData actionIcon;
  final String text;
  final String? subText;
  final GestureTapCallback onTap;

  const PeopleBanner({
    super.key,
    required this.type,
    this.startIcon,
    this.faceWidget,
    required this.actionIcon,
    required this.text,
    required this.onTap,
    this.subText,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    Color backgroundColor = colorScheme.backgroundElevated2;
    final TextStyle mainTextStyle = textTheme.bodyBold;
    final TextStyle subTextStyle = textTheme.miniMuted;
    late final Widget startWidget;
    late final bool roundedActionIcon;
    switch (type) {
      case PeopleBannerType.suggestion:
        assert(startIcon != null);
        startWidget = Padding(
          padding:
              const EdgeInsets.only(top: 10, bottom: 10, left: 6, right: 4),
          child: Icon(
            startIcon!,
            size: 40,
            color: colorScheme.primary500,
          ),
        );
        roundedActionIcon = true;
        break;
      case PeopleBannerType.addName:
        assert(faceWidget != null);
        backgroundColor = colorScheme.backgroundElevated;
        startWidget = Padding(
          padding: const EdgeInsets.all(4.0),
          child: SizedBox(
            width: 56,
            height: 56,
            child: ClipPath(
              clipper: ShapeBorderClipper(
                shape: ContinuousRectangleBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
              child: faceWidget!,
            ),
          ),
        );
        roundedActionIcon = false;
    }

    final Widget banner = Center(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              border: Border.all(
                color: colorScheme.strokeFaint,
                width: 1,
              ),
              borderRadius: const BorderRadius.all(
                Radius.circular(5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                startWidget,
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        text,
                        style: mainTextStyle,
                        textAlign: TextAlign.left,
                      ),
                      subText != null
                          ? const SizedBox(height: 6)
                          : const SizedBox.shrink(),
                      subText != null
                          ? Text(
                              subText!,
                              style: subTextStyle,
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                IconButtonWidget(
                  icon: actionIcon,
                  iconButtonType: IconButtonType.primary,
                  iconColor: colorScheme.strokeBase,
                  defaultColor: colorScheme.fillFaint,
                  pressedColor: colorScheme.fillMuted,
                  roundedIcon: roundedActionIcon,
                  onTap: onTap,
                ),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );

    if (type == PeopleBannerType.suggestion) {
      return SafeArea(
        top: false,
        child: RepaintBoundary(child: banner),
      );
    } else {
      return RepaintBoundary(child: banner);
    }
  }
}
