import "package:flutter/material.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/viewer/people/face_thumbnail_squircle.dart";
import "package:photos/ui/viewer/people/person_face_widget.dart";

class SavePersonBanner extends StatelessWidget {
  final PersonFaceWidget? faceWidget;
  final String text;
  final String? subText;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final GestureTapCallback? onPrimaryTap;
  final GestureTapCallback? onSecondaryTap;
  final VoidCallback? onDismissed;
  final Key? dismissibleKey;

  const SavePersonBanner({
    super.key,
    this.faceWidget,
    required this.text,
    this.subText,
    this.primaryActionLabel,
    this.secondaryActionLabel,
    this.onPrimaryTap,
    this.onSecondaryTap,
    this.onDismissed,
    this.dismissibleKey,
  })  : assert(
          faceWidget != null &&
              primaryActionLabel != null &&
              secondaryActionLabel != null &&
              onPrimaryTap != null &&
              onSecondaryTap != null,
        ),
        assert(onDismissed == null || dismissibleKey != null);

  @override
  Widget build(BuildContext context) {
    return _buildBanner(context);
  }

  Widget _buildBanner(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    final captionColor = colorScheme.textBase.withValues(alpha: 0.8);
    final buttonTextStyle = textTheme.smallBold.copyWith(
      height: 20 / 14,
    );
    const double faceSize = 52;
    const double closeButtonSize = 24;
    final bool showDismiss = onDismissed != null;
    final double closeButtonInset = showDismiss ? closeButtonSize + 8 : 0;

    final banner = RepaintBoundary(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.backgroundElevated2,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(12),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: closeButtonInset),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: faceSize,
                          height: faceSize,
                          child: FaceThumbnailSquircleClip(
                            child: faceWidget!,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                text,
                                style: textTheme.body,
                              ),
                              if (subText != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  subText!,
                                  style: textTheme.mini.copyWith(
                                    color: captionColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SavePersonBannerActionButton(
                          label: primaryActionLabel!,
                          backgroundColor: const Color(0xFF08C225),
                          textStyle: buttonTextStyle.copyWith(
                            color: Colors.white,
                          ),
                          onTap: onPrimaryTap,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _SavePersonBannerActionButton(
                          label: secondaryActionLabel!,
                          backgroundColor: colorScheme.fillFaint,
                          textStyle: buttonTextStyle.copyWith(
                            color: colorScheme.textBase,
                          ),
                          onTap: onSecondaryTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (showDismiss)
                Positioned(
                  top: 0,
                  right: 0,
                  child: _SavePersonBannerCloseButton(
                    size: closeButtonSize,
                    onTap: onDismissed,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (!showDismiss) {
      return banner;
    }

    return Dismissible(
      key: dismissibleKey!,
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismissed?.call(),
      child: banner,
    );
  }
}

class _SavePersonBannerActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final TextStyle textStyle;
  final GestureTapCallback? onTap;

  const _SavePersonBannerActionButton({
    required this.label,
    required this.backgroundColor,
    required this.textStyle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(14);
    return SizedBox(
      height: 48,
      child: Material(
        color: backgroundColor,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: textStyle,
            ),
          ),
        ),
      ),
    );
  }
}

class _SavePersonBannerCloseButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;

  const _SavePersonBannerCloseButton({
    required this.size,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = getEnteColorScheme(context);
    final borderRadius = BorderRadius.circular(size / 2);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.fillFaint,
          borderRadius: borderRadius,
        ),
        child: const Icon(
          Icons.close,
          size: 14,
          color: Colors.black,
        ),
      ),
    );
  }
}
