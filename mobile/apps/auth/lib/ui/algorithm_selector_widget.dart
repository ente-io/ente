import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class AlgorithmSelectorWidget extends StatelessWidget {
  final Algorithm currentAlgorithm;
  final void Function(Algorithm) onSelected;
  const AlgorithmSelectorWidget({
    super.key,
    required this.currentAlgorithm,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Text algorithmOptionText(Algorithm algorithm) {
      return Text(
        algorithm.name.toUpperCase(),
        style: getEnteTextTheme(context).small,
      );
    }

    return GestureDetector(
      onTapDown: (TapDownDetails details) async {
        final int? selectedValue = await showMenu<int>(
          context: context,
          position: RelativeRect.fromLTRB(
            details.globalPosition.dx,
            details.globalPosition.dy,
            details.globalPosition.dx,
            details.globalPosition.dy + 300,
          ),
          items: List.generate(Algorithm.values.length, (index) {
            return PopupMenuItem(
              value: index,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  algorithmOptionText(Algorithm.values[index]),
                  if (Algorithm.values[index] == currentAlgorithm)
                    Icon(
                      Icons.check,
                      color: Theme.of(context).iconTheme.color,
                    ),
                ],
              ),
            );
          }),
        );
        if (selectedValue != null) {
          onSelected(Algorithm.values[selectedValue]);
        }
      },
      child: Container(
        padding: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            algorithmOptionText(currentAlgorithm),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
