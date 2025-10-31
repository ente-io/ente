import "package:flutter/material.dart";
import "package:photos/service_locator.dart";
import "package:photos/services/wrapped/models.dart";
import "package:photos/services/wrapped/wrapped_service.dart";
import "package:photos/theme/ente_theme.dart";
import "package:photos/ui/notification/toast.dart";
import "package:photos/ui/wrapped/wrapped_viewer_page.dart";
import "package:rive/rive.dart" show Artboard, Fill, RiveAnimation;

class WrappedRewindBannerButton extends StatefulWidget {
  const WrappedRewindBannerButton({
    super.key,
    this.height,
    this.semanticsLabel,
  });

  final double? height;
  final String? semanticsLabel;

  @override
  State<WrappedRewindBannerButton> createState() =>
      _WrappedRewindBannerButtonState();
}

class _WrappedRewindBannerButtonState extends State<WrappedRewindBannerButton> {
  double? _artboardAspectRatio;

  @override
  Widget build(BuildContext context) {
    final enteColorScheme = getEnteColorScheme(context);
    final textTheme = getEnteTextTheme(context);
    const BorderRadius borderRadius = BorderRadius.all(Radius.circular(24));

    return Semantics(
      button: true,
      label: widget.semanticsLabel,
      child: Material(
        color: Colors.transparent,
        borderRadius: borderRadius,
        child: InkWell(
          borderRadius: borderRadius,
          onTap: () => _handleTap(context),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double availableWidth =
                  constraints.hasBoundedWidth && constraints.maxWidth.isFinite
                      ? constraints.maxWidth
                      : MediaQuery.sizeOf(context).width;
              double? resolvedHeight = widget.height;
              if (resolvedHeight == null &&
                  _artboardAspectRatio != null &&
                  _artboardAspectRatio! > 0 &&
                  availableWidth.isFinite) {
                resolvedHeight = availableWidth / _artboardAspectRatio!;
              }
              resolvedHeight ??= 128;

              return ClipRRect(
                borderRadius: borderRadius,
                child: SizedBox(
                  height: resolvedHeight,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: RiveAnimation.asset(
                          "assets/ente_rewind_banner.riv",
                          fit: BoxFit.cover,
                          stateMachines: const ["State Machine 1"],
                          onInit: _onRiveInit,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Flexible(
                              child: Text(
                                "Ente Rewind 2025",
                                style: textTheme.largeBold.copyWith(
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: enteColorScheme.textBase,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onRiveInit(Artboard artboard) {
    _sanitizeFillRules(artboard);
    if (!mounted) return;
    final double height = artboard.height;
    final double width = artboard.width;
    if (height <= 0 || width <= 0) {
      return;
    }
    final double aspectRatio = width / height;
    if (aspectRatio == _artboardAspectRatio) {
      return;
    }
    setState(() {
      _artboardAspectRatio = aspectRatio;
    });
  }

  void _sanitizeFillRules(Artboard artboard) {
    artboard.forEachComponent((component) {
      if (component is! Fill) return;
      if (component.fillRule >= PathFillType.values.length) {
        component.fillRule = PathFillType.nonZero.index;
      }
    });
  }

  void _handleTap(BuildContext context) {
    final WrappedEntryState currentState = wrappedService.state;
    final WrappedResult? result = currentState.result;
    if (result == null || result.cards.isEmpty) {
      showShortToast(context, "Ente Rewind isn't ready yet");
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WrappedViewerPage(
          initialState: currentState,
        ),
      ),
    );
  }
}
