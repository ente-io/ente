import "package:flutter/widgets.dart";
import "package:photos/theme/ente_theme.dart";

class OutlinedTile extends StatelessWidget {
  const OutlinedTile({
    super.key,
    this.isActive = false,
  });

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isActive
              ? getEnteColorScheme(context).strokeBase
              : getEnteColorScheme(context).strokeMuted,
          width: 2,
        ),
        borderRadius: const BorderRadius.all(Radius.circular(2)),
      ),
    );
  }
}
