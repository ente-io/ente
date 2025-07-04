import "package:figma_squircle/figma_squircle.dart";
import 'package:flutter/material.dart';
import "package:photos/generated/l10n.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/components/buttons/button_widget.dart";
import "package:photos/ui/components/models/button_type.dart";
import "package:photos/utils/collection_util.dart";

class CollectPhotosCardWidget extends StatefulWidget {
  const CollectPhotosCardWidget({super.key});

  @override
  State<CollectPhotosCardWidget> createState() =>
      _CollectPhotosCardWidgetState();
}

class _CollectPhotosCardWidgetState extends State<CollectPhotosCardWidget> {
  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorTheme = getEnteColorScheme(context);
    return Stack(
      children: [
        Positioned(
          bottom: 22.5,
          left: 14.5,
          child: Container(
            height: 125,
            width: 125,
            decoration: ShapeDecoration(
              gradient: LinearGradient(
                colors: [
                  colorTheme.primary700.withValues(alpha: 0.9),
                  colorTheme.backdropBase.withValues(alpha: 0.6),
                  colorTheme.backdropBase,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
              shape: SmoothRectangleBorder(
                borderRadius: SmoothBorderRadius(
                  cornerRadius: 12.0,
                  cornerSmoothing: 1.0,
                ),
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () => onTapCollectEventPhotos(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Container(
              decoration: ShapeDecoration(
                color: colorTheme.backgroundElevated,
                shadows: [
                  BoxShadow(
                    color: colorTheme.textBase.withValues(alpha: 0.1),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1),
                  ),
                ],
                shape: SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius(
                    cornerRadius: 10.0,
                    cornerSmoothing: 1.0,
                  ),
                ),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).collectPhotos,
                      style: textTheme.bodyBold,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      S.of(context).collectPhotosDescription,
                      style: textTheme.smallMuted,
                    ),
                    const SizedBox(
                      height: 34,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ButtonWidget(
                          buttonType: ButtonType.primary,
                          buttonSize: ButtonSize.small,
                          labelText: S.of(context).collect,
                          icon: Icons.add_photo_alternate_outlined,
                          shouldShowSuccessConfirmation: false,
                          shouldSurfaceExecutionStates: false,
                          onTap: () => onTapCollectEventPhotos(context),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 24,
          left: 16,
          child: Container(
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              borderRadius:
                  const BorderRadius.only(bottomLeft: Radius.circular(10)),
              gradient: LinearGradient(
                colors: [
                  colorTheme.primary700.withValues(alpha: 0.4),
                  colorTheme.backgroundElevated.withValues(alpha: 0.6),
                  colorTheme.backgroundElevated,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 25,
          left: 20,
          child: SizedBox(
            child: Image.asset('assets/create_new_album.png'),
          ),
        ),
      ],
    );
  }
}
