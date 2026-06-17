import "package:flutter/material.dart";

const searchTabHorizontalPadding = 15.0;

double searchTabSingleLineTextHeight(BuildContext context, TextStyle style) {
  final textPainter = TextPainter(
    text: TextSpan(text: "Ag", style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  return textPainter.height;
}

class SearchTabHorizontalListView extends StatelessWidget {
  const SearchTabHorizontalListView({
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    super.key,
  });

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;

  @override
  Widget build(BuildContext context) {
    return _SearchTabHorizontalViewport(
      height: height,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: searchTabHorizontalPadding,
        ),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        itemCount: itemCount,
        itemBuilder: itemBuilder,
        separatorBuilder: separatorBuilder,
      ),
    );
  }
}

class SearchTabHorizontalScrollView extends StatelessWidget {
  const SearchTabHorizontalScrollView({
    required this.height,
    required this.child,
    super.key,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _SearchTabHorizontalViewport(
      height: height,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: searchTabHorizontalPadding,
        ),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        child: child,
      ),
    );
  }
}

class _SearchTabHorizontalViewport extends StatelessWidget {
  const _SearchTabHorizontalViewport({
    required this.height,
    required this.child,
  });

  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth + (searchTabHorizontalPadding * 2);
          return OverflowBox(
            minWidth: width,
            maxWidth: width,
            alignment: Alignment.center,
            child: SizedBox(width: width, height: height, child: child),
          );
        },
      ),
    );
  }
}
