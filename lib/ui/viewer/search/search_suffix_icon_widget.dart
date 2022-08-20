import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class SearchSuffixIcon extends StatefulWidget {
  final bool timerIsActive;
  const SearchSuffixIcon(this.timerIsActive, {Key key}) : super(key: key);

  @override
  State<SearchSuffixIcon> createState() => _SearchSuffixIconState();
}

class _SearchSuffixIconState extends State<SearchSuffixIcon>
    with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    final animation = Tween(
      begin: 0.0,
      end: 1.0,
    ).animate(controller);
    if (widget.timerIsActive) {
      controller.forward();
      return FadeTransition(
        opacity: animation,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SizedBox(
            height: 6,
            width: 6,
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.iconColor.withOpacity(0.5),
              ),
            ),
          ),
        ),
      );
    } else {
      controller.forward();
      return FadeTransition(
        opacity: animation,
        child: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(
            Icons.close,
            color: Theme.of(context).colorScheme.iconColor.withOpacity(0.5),
          ),
        ),
      );
    }
  }
}
