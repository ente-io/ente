library google_nav_bar;

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GNav extends StatefulWidget {
  const GNav({
    Key key,
    this.tabs,
    this.selectedIndex = 0,
    this.onTabChange,
    this.gap,
    this.padding,
    this.activeColor,
    this.color,
    this.rippleColor,
    this.hoverColor,
    this.backgroundColor,
    this.tabBackgroundColor,
    this.tabBorderRadius,
    this.iconSize,
    this.textStyle,
    this.curve,
    this.tabMargin,
    this.debug,
    this.duration,
    this.tabBorder,
    this.tabActiveBorder,
    this.tabShadow,
    this.haptic,
    this.tabBackgroundGradient,
    this.mainAxisAlignment = MainAxisAlignment.spaceBetween,
  }) : super(key: key);

  final List<GButton> tabs;
  final int selectedIndex;
  final Function onTabChange;
  final double gap;
  final double tabBorderRadius;
  final double iconSize;
  final Color activeColor;
  final Color backgroundColor;
  final Color tabBackgroundColor;
  final Color color;
  final Color rippleColor;
  final Color hoverColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry tabMargin;
  final TextStyle textStyle;
  final Duration duration;
  final Curve curve;
  final bool debug;
  final bool haptic;
  final Border tabBorder;
  final Border tabActiveBorder;
  final List<BoxShadow> tabShadow;
  final Gradient tabBackgroundGradient;
  final MainAxisAlignment mainAxisAlignment;

  @override
  _GNavState createState() => _GNavState();
}

class _GNavState extends State<GNav> {
  int selectedIndex;
  bool clickable = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    selectedIndex = widget.selectedIndex;

    return Container(
        color: widget.backgroundColor ?? Colors.transparent,
        // padding: EdgeInsets.all(12),
        // alignment: Alignment.center,
        child: Row(
            mainAxisAlignment: widget.mainAxisAlignment,
            children: widget.tabs
                .map((t) => GButton(
                      key: t.key,
                      border: t.border ?? widget.tabBorder,
                      activeBorder: t.activeBorder ?? widget.tabActiveBorder,
                      shadow: t.shadow ?? widget.tabShadow,
                      borderRadius:
                          t.borderRadius ?? widget.tabBorderRadius != null
                              ? BorderRadius.all(
                                  Radius.circular(widget.tabBorderRadius))
                              : const BorderRadius.all(Radius.circular(100.0)),
                      debug: widget.debug ?? false,
                      margin: t.margin ?? widget.tabMargin,
                      active: selectedIndex == widget.tabs.indexOf(t),
                      gap: t.gap ?? widget.gap,
                      iconActiveColor: t.iconActiveColor ?? widget.activeColor,
                      iconColor: t.iconColor ?? widget.color,
                      iconSize: t.iconSize ?? widget.iconSize,
                      textColor: t.textColor ?? widget.activeColor,
                      rippleColor: t.rippleColor ??
                          widget.rippleColor ??
                          Colors.transparent,
                      hoverColor: t.hoverColor ??
                          widget.hoverColor ??
                          Colors.transparent,
                      padding: t.padding ?? widget.padding,
                      textStyle: t.textStyle ?? widget.textStyle,
                      text: t.text,
                      icon: t.icon,
                      haptic: widget.haptic ?? true,
                      leading: t.leading,
                      curve: widget.curve ?? Curves.easeInCubic,
                      backgroundGradient:
                          t.backgroundGradient ?? widget.tabBackgroundGradient,
                      backgroundColor: t.backgroundColor ??
                          widget.tabBackgroundColor ??
                          Colors.transparent,
                      duration:
                          widget.duration ?? const Duration(milliseconds: 500),
                      onPressed: () {
                        if (!clickable) return;
                        setState(() {
                          selectedIndex = widget.tabs.indexOf(t);
                          clickable = false;
                        });
                        widget.onTabChange(selectedIndex);

                        Future.delayed(
                            widget.duration ??
                                const Duration(milliseconds: 500), () {
                          setState(() {
                            clickable = true;
                          });
                        });
                      },
                    ))
                .toList()));
  }
}

class GButton extends StatefulWidget {
  final bool active;
  final bool debug;
  final bool haptic;
  final double gap;
  final Color iconColor;
  final Color rippleColor;
  final Color hoverColor;
  final Color iconActiveColor;
  final Color textColor;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final TextStyle textStyle;
  final double iconSize;
  final Function onPressed;
  final String text;
  final IconData icon;
  final Color backgroundColor;
  final Duration duration;
  final Curve curve;
  final Gradient backgroundGradient;
  final Widget leading;
  final BorderRadius borderRadius;
  final Border border;
  final Border activeBorder;
  final List<BoxShadow> shadow;
  final String semanticLabel;

  const GButton({
    Key key,
    this.active,
    this.haptic,
    this.backgroundColor,
    this.icon,
    this.iconColor,
    this.rippleColor,
    this.hoverColor,
    this.iconActiveColor,
    this.text = '',
    this.textColor,
    this.padding,
    this.margin,
    this.duration,
    this.debug,
    this.gap,
    this.curve,
    this.textStyle,
    this.iconSize,
    this.leading,
    this.onPressed,
    this.backgroundGradient,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.shadow,
    this.semanticLabel,
  }) : super(key: key);

  @override
  _GButtonState createState() => _GButtonState();
}

class _GButtonState extends State<GButton> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ?? widget.text,
      child: Button(
        borderRadius: widget.borderRadius,
        border: widget.border,
        activeBorder: widget.activeBorder,
        shadow: widget.shadow,
        debug: widget.debug,
        duration: widget.duration,
        iconSize: widget.iconSize,
        active: widget.active,
        onPressed: () {
          if (widget.haptic) HapticFeedback.selectionClick();
          widget.onPressed();
        },
        padding: widget.padding,
        margin: widget.margin,
        gap: widget.gap,
        color: widget.backgroundColor,
        rippleColor: widget.rippleColor,
        hoverColor: widget.hoverColor,
        gradient: widget.backgroundGradient,
        curve: widget.curve,
        leading: widget.leading,
        iconActiveColor: widget.iconActiveColor,
        iconColor: widget.iconColor,
        icon: widget.icon,
        text: Text(
          widget.text,
          style: widget.textStyle ??
              TextStyle(fontWeight: FontWeight.w600, color: widget.textColor),
        ),
      ),
    );
  }
}

class Button extends StatefulWidget {
  const Button(
      {Key key,
      this.icon,
      this.iconSize,
      this.leading,
      this.iconActiveColor,
      this.iconColor,
      this.text,
      this.gap = 0,
      this.color,
      this.rippleColor,
      this.hoverColor,
      this.onPressed,
      this.duration,
      this.curve,
      this.padding = const EdgeInsets.all(25),
      this.margin = const EdgeInsets.all(0),
      this.active = false,
      this.debug,
      this.gradient,
      this.borderRadius = const BorderRadius.all(Radius.circular(100.0)),
      this.border,
      this.activeBorder,
      this.shadow})
      : super(key: key);

  final IconData icon;
  final double iconSize;
  final Text text;
  final Widget leading;
  final Color iconActiveColor;
  final Color iconColor;
  final Color color;
  final Color rippleColor;
  final Color hoverColor;
  final double gap;
  final bool active;
  final bool debug;
  final VoidCallback onPressed;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final Duration duration;
  final Curve curve;
  final Gradient gradient;
  final BorderRadius borderRadius;
  final Border border;
  final Border activeBorder;
  final List<BoxShadow> shadow;

  @override
  _ButtonState createState() => _ButtonState();
}

class _ButtonState extends State<Button> with TickerProviderStateMixin {
  bool _expanded;

  AnimationController expandController;
  Animation<double> animation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.active;

    expandController =
        AnimationController(vsync: this, duration: widget.duration)
          ..addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    expandController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var curveValue = expandController
        .drive(
            CurveTween(curve: _expanded ? widget.curve : widget.curve.flipped))
        .value;

    _expanded = !widget.active;
    if (_expanded)
      expandController.reverse();
    else
      expandController.forward();

    Widget icon = widget.leading ??
        Icon(
          widget.icon,
          color: _expanded ? widget.iconColor : widget.iconActiveColor,
          size: widget.iconSize,
        );

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        highlightColor: widget.hoverColor,
        splashColor: widget.rippleColor,
        borderRadius: BorderRadius.circular(100),
        // behavior: HitTestBehavior.opaque,
        onTap: () {
          widget.onPressed();
        },
        child: Container(
          padding: widget.margin,
          child: AnimatedContainer(
            curve: Curves.easeOut,
            // padding: EdgeInsets.symmetric(horizontal: 5),
            padding: widget.padding,
            // curve: Curves.easeOutQuad,
            duration: widget.duration,
            // curve: !_expanded ? widget.curve : widget.curve.flipped,
            decoration: BoxDecoration(
              boxShadow: widget.shadow,
              border: widget.active
                  ? (widget.activeBorder ?? widget.border)
                  : widget.border,
              gradient: widget.gradient,
              color: _expanded
                  ? widget.color.withOpacity(0)
                  : widget.debug
                      ? Colors.red
                      : widget.gradient != null
                          ? Colors.white
                          : widget.color,
              borderRadius: widget.borderRadius,
            ),
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Stack(children: [
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  icon,
                  Container(
//               width: double.infinity,

                    child: Container(
                      //color: Colors.blue.withOpacity(.2),
                      child: Align(
                          alignment: Alignment.centerRight,
                          widthFactor: curveValue,
                          child: Container(
                            //width: 100,
                            //color: Colors.red.withOpacity(.2),
                            child: Opacity(
                                opacity: _expanded
                                    ? pow(expandController.value, 13)
                                    : expandController
                                        .drive(CurveTween(curve: Curves.easeIn))
                                        .value,
                                //width: 100,
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      left: widget.gap +
                                          8 -
                                          (8 *
                                              expandController
                                                  .drive(CurveTween(
                                                      curve:
                                                          Curves.easeOutSine))
                                                  .value),
                                      right: 8 *
                                          expandController
                                              .drive(CurveTween(
                                                  curve: Curves.easeOutSine))
                                              .value),
                                  child: widget.text,
                                )),
                          )),
                    ),
                  ),
                ]),
                Align(alignment: Alignment.centerLeft, child: icon),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
