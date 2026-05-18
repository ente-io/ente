import 'dart:async';

import 'package:ente_components/components/buttons/icon_button_component.dart';
import 'package:ente_components/theme/radii.dart';
import 'package:ente_components/theme/spacing.dart';
import 'package:ente_components/theme/text_styles.dart';
import 'package:ente_components/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=4809-7992&m=dev
/// Section: Bottom sheet / Bottom Sheet Header
/// Specs: H2 title, optional 36px circular close action, and optional centered
/// illustration slot for warning and error sheets.
class _BottomSheetHeaderComponent extends StatelessWidget {
  const _BottomSheetHeaderComponent({
    this.title,
    this.illustration,
    this.onClose,
    this.showCloseButton = true,
    this.closeTooltip = 'Close',
    this.textAlign,
    this.isCentered = false,
  });

  final String? title;
  final Widget? illustration;

  /// Called when the close button is pressed, before the sheet is dismissed.
  ///
  /// Barrier taps, drag dismissals, and system back dismissals do not call this.
  final FutureOr<void> Function()? onClose;
  final bool showCloseButton;
  final String closeTooltip;
  final TextAlign? textAlign;
  final bool isCentered;

  @override
  Widget build(BuildContext context) {
    if (isCentered || illustration != null) {
      return _CenteredHeader(
        title: title,
        illustration: illustration,
        onClose: onClose,
        showCloseButton: showCloseButton,
        closeTooltip: closeTooltip,
      );
    }

    if (title == null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showCloseButton)
            _BottomSheetCloseButton(onClose: onClose, tooltip: closeTooltip),
        ],
      );
    }

    final colors = context.componentColors;
    return SizedBox(
      height: _headerHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: textAlign,
              style: TextStyles.h2.copyWith(color: colors.textBase),
            ),
          ),
          if (showCloseButton) const SizedBox(width: Spacing.md),
          if (showCloseButton)
            _BottomSheetCloseButton(onClose: onClose, tooltip: closeTooltip),
        ],
      ),
    );
  }
}

/// Figma: https://www.figma.com/design/BuBNPPytxlVnqfmCUW0mgz/Ente-Visual-Design?node-id=4809-8027&m=dev
/// Section: Bottom sheet / Bottom sheet template
/// Specs: 20px top radius, 20px padding, 16px content gap, stacked 12px
/// action gap.
class BottomSheetComponent extends StatelessWidget {
  const BottomSheetComponent({
    super.key,
    this.title,
    this.header,
    this.message,
    this.illustration,
    this.content,
    this.actions = const [],
    this.onClose,
    this.showCloseButton = true,
    this.closeTooltip = 'Close',
    this.textAlign,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.padding = const EdgeInsets.all(Spacing.xl),
    this.contentSpacing = Spacing.lg,
    this.actionsTopSpacing = Spacing.lg,
    this.backgroundColor,
    this.isKeyboardAware = false,
  });

  final String? title;
  final Widget? header;
  final String? message;
  final Widget? illustration;
  final Widget? content;
  final List<Widget> actions;

  /// Called when the close button is pressed, before the sheet is dismissed.
  ///
  /// Barrier taps, drag dismissals, and system back dismissals do not call this.
  final FutureOr<void> Function()? onClose;
  final bool showCloseButton;
  final String closeTooltip;
  final TextAlign? textAlign;
  final CrossAxisAlignment crossAxisAlignment;
  final EdgeInsets padding;
  final double contentSpacing;
  final double actionsTopSpacing;
  final Color? backgroundColor;
  final bool isKeyboardAware;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;
    final bottomInset = isKeyboardAware
        ? MediaQuery.viewInsetsOf(context).bottom
        : 0.0;
    final usesCenteredLayout =
        illustration != null || (message != null && content == null);
    final effectiveHeader =
        header ??
        ((title != null || showCloseButton || usesCenteredLayout)
            ? _BottomSheetHeaderComponent(
                title: title,
                illustration: illustration,
                onClose: onClose,
                showCloseButton: showCloseButton,
                closeTooltip: closeTooltip,
                textAlign: textAlign,
                isCentered: usesCenteredLayout,
              )
            : null);
    final effectiveContent =
        content ??
        (message == null
            ? null
            : Text(
                message!,
                textAlign: usesCenteredLayout ? TextAlign.center : textAlign,
                style: TextStyles.body.copyWith(color: colors.textLight),
              ));
    final effectiveCrossAxisAlignment = usesCenteredLayout
        ? CrossAxisAlignment.stretch
        : crossAxisAlignment;
    final effectiveContentSpacing = usesCenteredLayout
        ? Spacing.xs
        : contentSpacing;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.backgroundBase,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(Radii.bottomSheet),
            topRight: Radius.circular(Radii.bottomSheet),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: effectiveCrossAxisAlignment,
              children: [
                if (effectiveHeader != null) effectiveHeader,
                if (effectiveContent != null) ...[
                  if (effectiveHeader != null)
                    SizedBox(height: effectiveContentSpacing),
                  effectiveContent,
                ],
                if (actions.isNotEmpty) ...[
                  SizedBox(height: actionsTopSpacing),
                  _BottomSheetActions(actions: actions),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows [BottomSheetComponent] with the modal behavior used by the component
/// catalog and mobile apps.
Future<T?> showBottomSheetComponent<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  bool useRootNavigator = false,
  Color? barrierColor,
}) {
  final colors = context.componentColors;
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? colors.specialScrim.withValues(alpha: 0.55),
    builder: builder,
  );
}

class _CenteredHeader extends StatelessWidget {
  const _CenteredHeader({
    required this.title,
    required this.illustration,
    required this.onClose,
    required this.showCloseButton,
    required this.closeTooltip,
  });

  final String? title;
  final Widget? illustration;
  final FutureOr<void> Function()? onClose;
  final bool showCloseButton;
  final String closeTooltip;

  @override
  Widget build(BuildContext context) {
    final colors = context.componentColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (showCloseButton)
              _BottomSheetCloseButton(onClose: onClose, tooltip: closeTooltip),
          ],
        ),
        if (showCloseButton && (illustration != null || title != null))
          const SizedBox(height: Spacing.xs),
        if (illustration != null) Center(child: illustration!),
        if (title != null) ...[
          SizedBox(height: illustration == null ? 0 : Spacing.lg),
          Text(
            title!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyles.h2.copyWith(color: colors.textBase),
          ),
        ],
      ],
    );
  }
}

class _BottomSheetCloseButton extends StatelessWidget {
  const _BottomSheetCloseButton({required this.onClose, required this.tooltip});

  /// Called when the close button is pressed, before the sheet is dismissed.
  final FutureOr<void> Function()? onClose;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButtonComponent(
      tooltip: tooltip,
      variant: IconButtonComponentVariant.circular,
      shouldSurfaceExecutionStates: false,
      icon: const HugeIcon(icon: HugeIcons.strokeRoundedCancel01, size: 18),
      onTap: () => _handleClose(context),
    );
  }

  Future<void> _handleClose(BuildContext context) async {
    await Future.sync(onClose ?? () {});
    if (!context.mounted) {
      return;
    }

    final route = ModalRoute.of(context);
    if (route == null || route.isCurrent) {
      await Navigator.of(context).maybePop();
    }
  }
}

class _BottomSheetActions extends StatelessWidget {
  const _BottomSheetActions({required this.actions});

  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < actions.length; index++) ...[
          actions[index],
          if (index != actions.length - 1) const SizedBox(height: Spacing.md),
        ],
      ],
    );
  }
}

const double _headerHeight = 38;
