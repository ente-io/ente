import "package:flutter/material.dart";
import "package:rive/rive.dart" as rive;

class ChristmasLightsBanner extends StatefulWidget {
  const ChristmasLightsBanner({super.key});

  @override
  State<ChristmasLightsBanner> createState() => _ChristmasLightsBannerState();
}

class _ChristmasLightsBannerState extends State<ChristmasLightsBanner> {
  late final rive.FileLoader _riveFileLoader;

  @override
  void initState() {
    super.initState();
    _riveFileLoader = rive.FileLoader.fromAsset(
      "assets/x_mas_banner.riv",
      riveFactory: rive.Factory.flutter,
    );
  }

  @override
  void dispose() {
    _riveFileLoader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double bannerHeight = 28;
    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: rive.RiveWidgetBuilder(
        fileLoader: _riveFileLoader,
        stateMachineSelector: const rive.StateMachineNamed("State Machine 1"),
        builder: (BuildContext context, rive.RiveState state) {
          if (state is rive.RiveLoaded) {
            return rive.RiveWidget(
              controller: state.controller,
              fit: rive.Fit.fitWidth,
            );
          }
          if (state is rive.RiveFailed) {
            return const SizedBox.shrink();
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
