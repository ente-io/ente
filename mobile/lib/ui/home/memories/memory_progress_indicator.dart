import "package:flutter/material.dart";

class NewProgressIndicator extends StatefulWidget {
  final int totalSteps;
  final int currentIndex;
  final Duration duration;
  final Color selectedColor;
  final Color unselectedColor;
  final double height;
  final double gap;
  final void Function(AnimationController)? animationController;
  final VoidCallback? onComplete;

  const NewProgressIndicator({
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
  State<NewProgressIndicator> createState() => _NewProgressIndicatorState();
}

class _NewProgressIndicatorState extends State<NewProgressIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
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
  void didUpdateWidget(NewProgressIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _animationController.reset();
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(widget.totalSteps, (index) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4, right: 4),
            child: index < widget.currentIndex
                ? Container(
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: widget.selectedColor,
                      borderRadius: BorderRadius.circular(widget.height / 2),
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
                            borderRadius:
                                BorderRadius.circular(widget.height / 2),
                          );
                        },
                      )
                    : Container(
                        height: widget.height,
                        decoration: BoxDecoration(
                          color: widget.unselectedColor,
                          borderRadius:
                              BorderRadius.circular(widget.height / 2),
                        ),
                      ),
          ),
        );
      }),
    );
  }
}
