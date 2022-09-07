// @dart=2.9

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ThemeSwitchWidget extends StatefulWidget {
  const ThemeSwitchWidget({Key key}) : super(key: key);

  @override
  State<ThemeSwitchWidget> createState() => _ThemeSwitchWidgetState();
}

class _ThemeSwitchWidgetState extends State<ThemeSwitchWidget> {
  AdaptiveThemeMode themeMode;
  @override
  void initState() {
    super.initState();
    AdaptiveTheme.getThemeMode().then(
      (value) {
        themeMode = value ?? AdaptiveThemeMode.system;
        debugPrint('theme value $value');
        if (mounted) {
          setState(() => {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await showCupertinoModalPopup(
          context: context,
          builder: (_) => CupertinoActionSheet(
            title: Text(
              "Theme",
              style: Theme.of(context)
                  .textTheme
                  .headline4
                  .copyWith(color: Colors.white),
            ),
            actions: [
              for (var mode in AdaptiveThemeMode.values)
                CupertinoActionSheetAction(
                  child: Text(mode.modeName),
                  onPressed: () async {
                    AdaptiveTheme.of(context).setThemeMode(mode);
                    themeMode = mode;
                    Navigator.of(context, rootNavigator: true).pop();
                    if (mounted) {
                      setState(() => {});
                    }
                  },
                ),
            ],
            cancelButton: CupertinoActionSheetAction(
              child: const Text("Cancel"),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ),
        );
      },
      child: Text(themeMode?.modeName ?? ">"),
    );
  }
}
