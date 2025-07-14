import "package:flutter/material.dart";
import "package:photos/ui/viewer/gallery/scrollbar/scroll_bar_with_use_notifier.dart";

class CustomScrollBar2 extends StatefulWidget {
  final Widget child;
  final ScrollController scrollController;
  const CustomScrollBar2({
    super.key,
    required this.child,
    required this.scrollController,
  });

  @override
  State<CustomScrollBar2> createState() => _CustomScrollBar2State();
}

class _CustomScrollBar2State extends State<CustomScrollBar2> {
  final inUseNotifier = ValueNotifier<bool>(false);
  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.centerLeft,
      children: [
        ScrollbarWithUseNotifer(
          controller: widget.scrollController,
          interactive: true,
          inUseNotifier: inUseNotifier,
          child: widget.child,
        ),
        ValueListenableBuilder<bool>(
          valueListenable: inUseNotifier,
          builder: (context, inUse, _) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: !inUse
                  ? const SizedBox.shrink()
                  : Stack(
                      children: [
                        Positioned(
                          top: 50,
                          right: 24,
                          child: Container(
                            color: Colors.teal,
                            child: const Center(
                              child: Text(
                                'Item 1',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 100,
                          right: 24,
                          child: Container(
                            color: Colors.teal,
                            child: const Center(
                              child: Text(
                                'Item 2',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 250,
                          right: 24,
                          child: Container(
                            color: Colors.teal,
                            child: const Center(
                              child: Text(
                                'Item 3',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 400,
                          right: 24,
                          child: Container(
                            color: Colors.teal,
                            child: const Center(
                              child: Text(
                                'Item 4',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }
}
