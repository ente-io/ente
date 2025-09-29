import "package:flutter/material.dart";
import "package:photos/generated/l10n.dart";
import "package:photos/models/selected_people.dart";
import "package:photos/theme/ente_theme.dart";

class PeopleActionBarWidget extends StatefulWidget {
  final SelectedPeople? selectedPeople;
  final VoidCallback? onCancel;
  const PeopleActionBarWidget({
    super.key,
    this.selectedPeople,
    this.onCancel,
  });

  @override
  State<PeopleActionBarWidget> createState() => _PeopleActionBarWidgetState();
}

class _PeopleActionBarWidgetState extends State<PeopleActionBarWidget> {
  final ValueNotifier<int> _selectedPeopleNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    widget.selectedPeople?.addListener(_selectedPeopleListener);
  }

  @override
  void dispose() {
    widget.selectedPeople?.removeListener(_selectedPeopleListener);
    _selectedPeopleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = getEnteTextTheme(context);
    final colorScheme = getEnteColorScheme(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.backgroundElevated2,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder(
            valueListenable: _selectedPeopleNotifier,
            builder: (context, value, child) {
              final count = widget.selectedPeople?.personIds.length ?? 0;
              return Text(
                S.of(context).selectedPhotos(count),
                style: textTheme.miniMuted,
              );
            },
          ),
          const SizedBox(width: 4),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              widget.onCancel?.call();
            },
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.close,
                size: 16,
                color: textTheme.mini.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectedPeopleListener() {
    _selectedPeopleNotifier.value =
        widget.selectedPeople?.personIds.length ?? 0;
  }
}
