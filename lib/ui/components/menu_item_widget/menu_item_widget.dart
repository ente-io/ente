import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:photos/theme/ente_theme.dart';
import 'package:photos/ui/components/menu_item_widget/menu_item_child_widgets.dart';
import 'package:photos/utils/debouncer.dart';

enum ExecutionState {
  idle,
  inProgress,
  error,
  successful;
}

typedef FutureVoidCallback = Future<void> Function();

class MenuItemWidget extends StatefulWidget {
  final Widget captionedTextWidget;
  final bool isExpandable;

  /// leading icon can be passed without specifing size of icon,
  /// this component sets size to 20x20 irrespective of passed icon's size
  final IconData? leadingIcon;
  final Color? leadingIconColor;

  final Widget? leadingIconWidget;
  // leadIconSize deafult value is 20.
  final double leadingIconSize;

  /// trailing icon can be passed without size as default size set by
  /// flutter is what this component expects
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final Widget? trailingWidget;
  final bool trailingIconIsMuted;

  /// If provided, add this much extra spacing to the right of the trailing icon.
  final double trailingExtraMargin;
  final FutureVoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final Color? menuItemColor;
  final bool alignCaptionedTextToLeft;
  final double borderRadius;
  final Color? pressedColor;
  final ExpandableController? expandableController;
  final bool isBottomBorderRadiusRemoved;
  final bool isTopBorderRadiusRemoved;

  /// disable gesture detector if not used
  final bool isGestureDetectorDisabled;

  const MenuItemWidget({
    required this.captionedTextWidget,
    this.isExpandable = false,
    this.leadingIcon,
    this.leadingIconColor,
    this.leadingIconSize = 20.0,
    this.leadingIconWidget,
    this.trailingIcon,
    this.trailingIconColor,
    this.trailingWidget,
    this.trailingIconIsMuted = false,
    this.trailingExtraMargin = 0.0,
    this.onTap,
    this.onDoubleTap,
    this.menuItemColor,
    this.alignCaptionedTextToLeft = false,
    this.borderRadius = 4.0,
    this.pressedColor,
    this.expandableController,
    this.isBottomBorderRadiusRemoved = false,
    this.isTopBorderRadiusRemoved = false,
    this.isGestureDetectorDisabled = false,
    Key? key,
  }) : super(key: key);

  @override
  State<MenuItemWidget> createState() => _MenuItemWidgetState();
}

class _MenuItemWidgetState extends State<MenuItemWidget> {
  final _debouncer = Debouncer(const Duration(milliseconds: 300));
  ValueNotifier<ExecutionState> executionStateNotifier =
      ValueNotifier(ExecutionState.idle);

  Color? menuItemColor;

  @override
  void initState() {
    menuItemColor = widget.menuItemColor;
    if (widget.expandableController != null) {
      widget.expandableController!.addListener(() {
        setState(() {});
      });
    }
    super.initState();
  }

  @override
  void didChangeDependencies() {
    menuItemColor = widget.menuItemColor;
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    if (widget.expandableController != null) {
      widget.expandableController!.dispose();
    }
    executionStateNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.isExpandable || widget.isGestureDetectorDisabled
        ? menuItemWidget(context)
        : GestureDetector(
            onTap: _onTap,
            onDoubleTap: widget.onDoubleTap,
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onCancel,
            child: menuItemWidget(context),
          );
  }

  Widget menuItemWidget(BuildContext context) {
    final borderRadius = Radius.circular(widget.borderRadius);
    final isExpanded = widget.expandableController?.value;
    final bottomBorderRadius =
        (isExpanded != null && isExpanded) || widget.isBottomBorderRadiusRemoved
            ? const Radius.circular(0)
            : borderRadius;
    final topBorderRadius = widget.isTopBorderRadiusRemoved
        ? const Radius.circular(0)
        : borderRadius;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 20),
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: topBorderRadius,
          topRight: topBorderRadius,
          bottomLeft: bottomBorderRadius,
          bottomRight: bottomBorderRadius,
        ),
        color: menuItemColor,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          widget.alignCaptionedTextToLeft && widget.leadingIcon == null
              ? const SizedBox.shrink()
              : LeadingWidget(
                  leadingIconSize: widget.leadingIconSize,
                  leadingIcon: widget.leadingIcon,
                  leadingIconColor: widget.leadingIconColor,
                  leadingIconWidget: widget.leadingIconWidget,
                ),
          widget.captionedTextWidget,
          if (widget.expandableController != null)
            ExpansionTrailingIcon(
              isExpanded: isExpanded!,
              trailingIcon: widget.trailingIcon,
              trailingIconColor: widget.trailingIconColor,
            )
          else
            TrailingWidget(
              executionStateNotifier: executionStateNotifier,
              trailingIcon: widget.trailingIcon,
              trailingIconColor: widget.trailingIconColor,
              trailingWidget: widget.trailingWidget,
              trailingIconIsMuted: widget.trailingIconIsMuted,
              trailingExtraMargin: widget.trailingExtraMargin,
            ),
        ],
      ),
    );
  }

  Future<void> _onTap() async {
    _debouncer.run(
      () => Future(
        () {
          executionStateNotifier.value = ExecutionState.inProgress;
        },
      ),
    );
    await widget.onTap
        ?.call()
        .onError((error, stackTrace) => _debouncer.cancelDebounce());
    _debouncer.cancelDebounce();
    if (executionStateNotifier.value == ExecutionState.inProgress) {
      executionStateNotifier.value = ExecutionState.successful;
      Future.delayed(const Duration(seconds: 2), () {
        executionStateNotifier.value = ExecutionState.idle;
      });
    }
  }

  void _onTapDown(details) {
    setState(() {
      if (widget.pressedColor == null) {
        hasPassedGestureCallbacks()
            ? menuItemColor = getEnteColorScheme(context).fillFaintPressed
            : menuItemColor = widget.menuItemColor;
      } else {
        menuItemColor = widget.pressedColor;
      }
    });
  }

  bool hasPassedGestureCallbacks() {
    return widget.onDoubleTap != null || widget.onTap != null;
  }

  void _onTapUp(details) {
    Future.delayed(
      const Duration(milliseconds: 100),
      () => setState(() {
        menuItemColor = widget.menuItemColor;
      }),
    );
  }

  void _onCancel() {
    setState(() {
      menuItemColor = widget.menuItemColor;
    });
  }
}
