import 'package:ente_components/components/loading/loading_component.dart';
import 'package:ente_components/theme/colors.dart';
import 'package:ente_components/theme/motion.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/shadows.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';

// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=9421-4017&m=dev
LoadingComponentHandle showLoadingComponent(
  BuildContext context,
  String message, {
  bool isDismissible = false,
}) {
  final route = _LoadingComponentRoute(
    message: message,
    isDismissible: isDismissible,
    colors: context.componentColors,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
  );
  Navigator.of(context, rootNavigator: true).push(route);
  return LoadingComponentHandle._(route);
}

class LoadingComponentHandle {
  LoadingComponentHandle._(this._route);

  final _LoadingComponentRoute _route;

  bool isShowing() => _route.isActive;

  void update({String? message, double? value}) {
    if (!_route.isActive) return;
    if (message != null) _route.message.value = message;
    if (value != null) _route.value.value = value;
  }

  Future<void> hide() {
    final navigator = _route.navigator;
    if (navigator != null && _route.isActive) {
      if (_route.isCurrent) {
        navigator.pop();
      } else {
        navigator.removeRoute(_route);
      }
    }
    return _route.completed;
  }
}

class _LoadingComponentRoute extends PopupRoute<void> {
  _LoadingComponentRoute({
    required String message,
    required bool isDismissible,
    required this.colors,
    required this.barrierLabel,
  }) : message = ValueNotifier(message),
       barrierDismissible = isDismissible;

  final ColorTokens colors;
  final ValueNotifier<String> message;
  final value = ValueNotifier<double?>(null);

  @override
  final bool barrierDismissible;

  @override
  final String barrierLabel;

  @override
  Color get barrierColor => colors.specialScrim;

  @override
  Duration get transitionDuration => Motion.standard;

  @override
  void dispose() {
    message.dispose();
    value.dispose();
    super.dispose();
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return PopScope(
      canPop: barrierDismissible,
      child: Padding(
        padding: MediaQuery.viewInsetsOf(context),
        child: Center(
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 288,
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xxl,
                vertical: Spacing.xl,
              ),
              decoration: BoxDecoration(
                color: colors.backgroundBase,
                border: Border.all(color: colors.strokeFaint),
                borderRadius: Radii.buttonBorder,
                boxShadow: Shadows.floating,
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<double?>(
                    valueListenable: value,
                    builder: (_, value, _) =>
                        LoadingComponent(value: value, color: colors.primary),
                  ),
                  const SizedBox(width: Spacing.lg),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: message,
                      builder: (_, message, _) => Text(
                        message,
                        style: TextStyles.body.copyWith(color: colors.textBase),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }
}
