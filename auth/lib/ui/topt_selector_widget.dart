import 'package:ente_auth/models/code.dart';
import 'package:ente_auth/theme/ente_theme.dart';
import 'package:flutter/material.dart';

class ToptSelectorWidget extends StatelessWidget {
  final Type currentTopt;
  final void Function(Type) onSelected;
  const ToptSelectorWidget({
    super.key,
    required this.currentTopt,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    Text toptOptionText(Type type) {
      return Text(
        type.name.toUpperCase(),
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
          items: List.generate(Type.values.length, (index) {
            return PopupMenuItem(
              value: index,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  toptOptionText(Type.values[index]),
                  if (Type.values[index] == currentTopt)
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
          onSelected(Type.values[selectedValue]);
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
            toptOptionText(currentTopt),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }
}
