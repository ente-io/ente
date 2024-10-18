import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:photos/ente_theme_data.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/icon_button_widget.dart";
import "package:photos/ui/viewer/search/result/person_face_widget.dart";

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
    Key? key,
    required this.type,
    this.startIcon,
    this.faceWidget,
    required this.actionIcon,
    required this.text,
    required this.onTap,
    this.subText,
  }) : super(key: key);

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
        startWidget = SizedBox(
          width: 56,
          height: 56,
          child: ClipRRect(
            borderRadius: const BorderRadius.all(
              Radius.circular(4),
            ),
            child: faceWidget!,
          ),
        );
        roundedActionIcon = false;
    }

    final Widget banner = Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: Theme.of(context).colorScheme.enteTheme.shadowMenu,
            color: backgroundColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
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
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
          duration: 1000.ms,
          delay: 3200.ms,
          size: 0.6,
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
