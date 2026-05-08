import "package:flutter/material.dart";

const int kMemoryProgressTickCutoff = 60;

class MemoryProgressIndicator extends StatefulWidget {
  final int totalSteps;
  final int currentIndex;
  final Duration duration;
  final Color selectedColor;
  final Color unselectedColor;
  final double height;
  final double gap;
  final void Function(AnimationController)? animationController;
  final VoidCallback? onComplete;

  const MemoryProgressIndicator({
    super.key,
    required this.totalSteps,
    required this.currentIndex,
    this.duration = const Duration(seconds: 5),
    this.selectedColor = Colors.white,
    this.unselectedColor = Colors.white54,
    this.height = 2.0,
    this.gap = 4.0,
    this.animationController,
    this.onComplete,
  });

  @override
  State<MemoryProgressIndicator> createState() =>
      _MemoryProgressIndicatorState();
}

class _MemoryProgressIndicatorState extends State<MemoryProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
      animationBehavior: AnimationBehavior.preserve,
    );

    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    if (widget.animationController != null) {
      widget.animationController!(_animationController);
    }

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For very large memories, a per-file tick bar would render as pixel-thin
    // slivers. Show a single continuous bar instead, combining completed-file
    // progress with the current file's in-flight animation.
    if (widget.totalSteps >= kMemoryProgressTickCutoff) {
      return AnimatedBuilder(
        animation: _animation,
        builder: (context, _) {
          final progress =
              (widget.currentIndex + _animation.value) / widget.totalSteps;
          return LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            backgroundColor: widget.unselectedColor,
            valueColor: AlwaysStoppedAnimation<Color>(widget.selectedColor),
            minHeight: widget.height,
            borderRadius: BorderRadius.circular(12),
          );
        },
      );
    }
    return Row(
      children: List.generate(widget.totalSteps, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: widget.gap),
            child: index < widget.currentIndex
                ? Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )
                : index == widget.currentIndex
                    ? AnimatedBuilder(
                        animation: _animation,
                        builder: (context, child) {
                          return LinearProgressIndicator(
                            value: _animation.value,
                            backgroundColor: widget.unselectedColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              widget.selectedColor,
                            ),
                            minHeight: widget.height,
                            borderRadius: BorderRadius.circular(12),
                          );
                        },
                      )
                    : Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: widget.unselectedColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
          ),
        );
      }),
    );
  }
}
