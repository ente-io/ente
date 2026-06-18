import "package:flutter/material.dart";

const searchTabHorizontalPadding = 15.0;

class SearchTabHorizontalRow extends StatelessWidget {
  const SearchTabHorizontalRow({
    required this.children,
    required this.spacing,
    super.key,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return _SearchTabHorizontalViewport(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: searchTabHorizontalPadding,
        ),
        physics: const BouncingScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        scrollDirection: Axis.horizontal,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _spacedChildren(),
        ),
      ),
    );
  }

  List<Widget> _spacedChildren() {
    return [
      for (final (index, child) in children.indexed) ...[
        if (index != 0) SizedBox(width: spacing),
        child,
      ],
    ];
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
    return SizedBox(
      height: height,
      child: _SearchTabHorizontalViewport(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: searchTabHorizontalPadding,
          ),
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          scrollDirection: Axis.horizontal,
          child: child,
        ),
      ),
    );
  }
}

class _SearchTabHorizontalViewport extends StatelessWidget {
  const _SearchTabHorizontalViewport({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final widthFactor =
            (constraints.maxWidth + (searchTabHorizontalPadding * 2)) /
            constraints.maxWidth;
        return FractionallySizedBox(widthFactor: widthFactor, child: child);
      },
    );
  }
}
