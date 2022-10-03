import 'package:flutter/material.dart';
import 'package:photos/ente_theme_data.dart';

class ToggleSwitch extends StatefulWidget {
  final bool value;
  final Function onChanged;
  final String? label;
  final String? message;
  const ToggleSwitch(
      {required this.value,
      required this.onChanged,
      this.label,
      this.message,
      Key? key})
      : super(key: key);

  @override
  State<ToggleSwitch> createState() => _ToggleSwitchState();
}

class _ToggleSwitchState extends State<ToggleSwitch> {
  @override
  Widget build(BuildContext context) {
    final enteTheme = Theme.of(context).colorScheme.enteTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.label == null
            ? const SizedBox.shrink()
            : Text(widget.label!, style: enteTheme.textTheme.body),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SizedBox(
            height: 30,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch.adaptive(
                activeColor: enteTheme.colorScheme.primary400,
                inactiveTrackColor: enteTheme.colorScheme.fillMuted,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                value: widget.value,
                onChanged: (value) async {
                  widget.onChanged;
                  setState(() {});
                },
              ),
            ),
          ),
        ),
        widget.message == null
            ? const SizedBox.shrink()
            : Text(
                widget.message!,
                style: enteTheme.textTheme.small
                    .copyWith(color: enteTheme.colorScheme.textMuted),
              ),
      ],
    );
  }
}
