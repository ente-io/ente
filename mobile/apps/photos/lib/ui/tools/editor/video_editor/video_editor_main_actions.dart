import "package:flutter/material.dart";

class VideoEditorMainActions extends StatelessWidget {
  const VideoEditorMainActions({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 76,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          children: children,
        ),
      ),
    );
  }
}
